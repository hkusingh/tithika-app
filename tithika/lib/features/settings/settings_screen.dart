import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme.dart';
import '../../models/app_location.dart';
import '../../models/app_settings.dart';
import '../../services/notification_service.dart';
import '../../state/providers.dart';
import '../shared/city_picker_sheet.dart';
import '../shared/starfield_background.dart';
import '../shared/tithika_nav_bar.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _gpsLoading = false;
  bool _notifLoading = false;

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityPickerSheet(),
    );
    if (selected != null && mounted) {
      await ref.read(appSettingsProvider.notifier).setLocation(selected);
    }
  }

  Future<void> _useGps() async {
    // Capture colors before any async gap.
    final cardColor = TithikaColors.of(context).card;
    setState(() => _gpsLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                permission == LocationPermission.deniedForever
                    ? 'Location access permanently denied. Enable it in Settings.'
                    : 'Location permission denied.',
              ),
              backgroundColor: cardColor,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      String cityName = 'My Location';
      String country = '';
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.locality?.isNotEmpty == true
              ? p.locality!
              : p.administrativeArea ?? cityName;
          country = p.isoCountryCode ?? '';
        }
      } catch (_) {}

      final tzId = (await FlutterTimezone.getLocalTimezone()).identifier;
      final tzOffset = DateTime.now().timeZoneOffset;
      final location = AppLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        cityName: cityName,
        country: country,
        tzOffsetMinutes: tzOffset.inMinutes,
        tzId: tzId,
      );

      if (mounted) {
        await ref.read(appSettingsProvider.notifier).setLocation(location);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get location. Try entering your city manually.'),
            backgroundColor: cardColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (enable) {
      final cardColor = TithikaColors.of(context).card;
      setState(() => _notifLoading = true);
      final granted = await NotificationService.requestPermission();
      if (mounted) setState(() => _notifLoading = false);
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification permission denied.'),
            backgroundColor: cardColor,
          ),
        );
        return;
      }
    }
    final current = ref.read(appSettingsProvider).notificationSettings;
    await ref
        .read(appSettingsProvider.notifier)
        .setNotificationSettings(current.copyWith(enabled: enable));
  }

  Future<void> _pickReminderTime() async {
    final current = ref.read(appSettingsProvider).notificationSettings;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: current.dailyReminderHour, minute: current.dailyReminderMinute),
    );
    if (picked != null && mounted) {
      await ref.read(appSettingsProvider.notifier).setNotificationSettings(
            current.copyWith(
              dailyReminderHour: picked.hour,
              dailyReminderMinute: picked.minute,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final settings = ref.watch(appSettingsProvider);
    final cityName = settings.location?.cityName ?? 'Not set';
    final language = settings.language;
    final monthSystem = settings.monthSystem;
    final notif = settings.notificationSettings;

    final switchStyle = _SwitchStyle(colors: colors);

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TithikaNavBar(),
                Divider(color: colors.line, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    children: [
                      _SectionLabel('LOCATION'),
                      _SettingsRow(
                        label: 'Current location',
                        value: cityName,
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: colors.inkMuted, size: 18),
                        onTap: _pickCity,
                      ),
                      const SizedBox(height: 8),
                      _SettingsRow(
                        label: 'Use GPS location',
                        value: '',
                        trailing: _gpsLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: colors.shukla,
                                ),
                              )
                            : Icon(Icons.my_location_rounded,
                                color: colors.shukla, size: 18),
                        onTap: _gpsLoading ? null : _useGps,
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel('APPEARANCE'),
                      _AppearancePicker(
                        current: settings.theme,
                        onChanged: (t) => ref
                            .read(appSettingsProvider.notifier)
                            .setTheme(t),
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel('LANGUAGE'),
                      _RadioGroup(
                        options: const ['English', 'Hindi (Latin)', 'हिन्दी', 'தமிழ்', 'বাংলা'],
                        selected: language.index,
                        onChanged: (i) => ref
                            .read(appSettingsProvider.notifier)
                            .setLanguage(AppLanguage.values[i]),
                        itemStyles: [
                          null,
                          null,
                          devanagariStyle(
                            Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                          tamilStyle(
                            Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                          bengaliStyle(
                            Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel('MONTH SYSTEM'),
                      _RadioGroup(
                        options: const ['Purnimanta', 'Amanta'],
                        selected: monthSystem.index,
                        onChanged: (i) => ref
                            .read(appSettingsProvider.notifier)
                            .setMonthSystem(MonthSystem.values[i]),
                      ),

                      const SizedBox(height: 20),

                      _SectionLabel('NOTIFICATIONS'),
                      _SettingsRow(
                        label: 'Enable notifications',
                        value: '',
                        trailing: _notifLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: colors.shukla,
                                ),
                              )
                            : Switch(
                                value: notif.enabled,
                                onChanged: _notifLoading
                                    ? null
                                    : _toggleNotifications,
                                activeThumbColor: switchStyle.activeThumb,
                                activeTrackColor: switchStyle.activeTrack,
                                inactiveThumbColor: switchStyle.inactiveThumb,
                                inactiveTrackColor: switchStyle.inactiveTrack,
                                trackOutlineColor: WidgetStatePropertyAll(switchStyle.trackOutline),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                      ),
                      if (notif.enabled) ...[
                        const SizedBox(height: 8),
                        _NotifSubGroup(
                          notif: notif,
                          switchStyle: switchStyle,
                          onDailyChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(dailyReminderEnabled: v)),
                          onTimeTap: _pickReminderTime,
                          onFestivalChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(festivalAlertsEnabled: v)),
                          onEkadashiChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(ekadashiAlertsEnabled: v)),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _SectionLabel('CREDITS'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Astronomical calculations powered by Swiss Ephemeris',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.inkMuted,
                              ),
                        ),
                      ),
                      Text(
                        '© Astrodienst AG, Zurich — astro.com/swisseph',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.inkMuted,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Consumer(
                        builder: (context, ref, _) {
                          final info = ref.watch(_packageInfoProvider);
                          final version = info.whenOrNull(
                            data: (p) => 'Version ${p.version} (${p.buildNumber})',
                          ) ?? '';
                          return Text(
                            version,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.inkMuted,
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Switch style helper ───────────────────────────────────────────────────────

class _SwitchStyle {
  final Color activeThumb;
  final Color activeTrack;
  final Color inactiveThumb;
  final Color inactiveTrack;
  final Color trackOutline;

  _SwitchStyle({required TithikaColors colors})
      : activeThumb = Colors.white,
        activeTrack = colors.shukla.withValues(alpha: 0.35),
        inactiveThumb = colors.shukla.withValues(alpha: 0.5),
        inactiveTrack = colors.lineStrong,
        trackOutline = colors.shukla.withValues(alpha: 0.5);
}

// ── Appearance picker ─────────────────────────────────────────────────────────

class _AppearancePicker extends StatelessWidget {
  final AppTheme current;
  final ValueChanged<AppTheme> onChanged;

  const _AppearancePicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    const options = [AppTheme.system, AppTheme.light, AppTheme.dark];
    const labels = ['System', 'Light', 'Dark'];

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(3, (i) {
          final isSelected = current == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.shukla.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: isSelected
                      ? Border.all(color: colors.shukla.withValues(alpha: 0.5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? colors.shukla : colors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.07 * 10,
            ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
            Row(
              children: [
                if (value.isNotEmpty)
                  Text(value,
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioGroup extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<TextStyle?>? itemStyles;

  const _RadioGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.itemStyles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final defaultStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w500);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isLast = i == options.length - 1;
          final style = itemStyles != null && i < itemStyles!.length
              ? itemStyles![i]
              : defaultStyle;
          return InkWell(
            onTap: () => onChanged(i),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(color: colors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: style),
                  if (i == selected)
                    Icon(Icons.check_rounded,
                        color: colors.shukla, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Notification sub-options card ─────────────────────────────────────────────

class _NotifSubGroup extends StatelessWidget {
  final NotificationSettings notif;
  final _SwitchStyle switchStyle;
  final ValueChanged<bool> onDailyChanged;
  final VoidCallback onTimeTap;
  final ValueChanged<bool> onFestivalChanged;
  final ValueChanged<bool> onEkadashiChanged;

  const _NotifSubGroup({
    required this.notif,
    required this.switchStyle,
    required this.onDailyChanged,
    required this.onTimeTap,
    required this.onFestivalChanged,
    required this.onEkadashiChanged,
  });

  String _fmtTime() {
    final h = notif.dailyReminderHour;
    final m = notif.dailyReminderMinute;
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _SubRow(
            label: 'Daily panchanga reminder',
            trailing: Switch(
              value: notif.dailyReminderEnabled,
              onChanged: onDailyChanged,
              activeThumbColor: switchStyle.activeThumb,
              activeTrackColor: switchStyle.activeTrack,
              inactiveThumbColor: switchStyle.inactiveThumb,
              inactiveTrackColor: switchStyle.inactiveTrack,
              trackOutlineColor: WidgetStatePropertyAll(switchStyle.trackOutline),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            divider: true,
          ),
          if (notif.dailyReminderEnabled)
            _SubRow(
              label: 'Reminder time',
              trailing: GestureDetector(
                onTap: onTimeTap,
                child: Text(
                  _fmtTime(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.shukla,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              divider: true,
            ),
          _SubRow(
            label: 'Festival alerts',
            trailing: Switch(
              value: notif.festivalAlertsEnabled,
              onChanged: onFestivalChanged,
              activeThumbColor: switchStyle.activeThumb,
              activeTrackColor: switchStyle.activeTrack,
              inactiveThumbColor: switchStyle.inactiveThumb,
              inactiveTrackColor: switchStyle.inactiveTrack,
              trackOutlineColor: WidgetStatePropertyAll(switchStyle.trackOutline),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            divider: true,
          ),
          _SubRow(
            label: 'Ekadashi alerts',
            trailing: Switch(
              value: notif.ekadashiAlertsEnabled,
              onChanged: onEkadashiChanged,
              activeThumbColor: switchStyle.activeThumb,
              activeTrackColor: switchStyle.activeTrack,
              inactiveThumbColor: switchStyle.inactiveThumb,
              inactiveTrackColor: switchStyle.inactiveTrack,
              trackOutlineColor: WidgetStatePropertyAll(switchStyle.trackOutline),
            ),
            divider: false,
          ),
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final bool divider;

  const _SubRow({
    required this.label,
    required this.trailing,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: colors.line))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing,
        ],
      ),
    );
  }
}
