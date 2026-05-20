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
              backgroundColor: TithikaColors.card,
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
          const SnackBar(
            content: Text('Could not get location. Try entering your city manually.'),
            backgroundColor: TithikaColors.card,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (enable) {
      setState(() => _notifLoading = true);
      final granted = await NotificationService.requestPermission();
      if (mounted) setState(() => _notifLoading = false);
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission denied.'),
            backgroundColor: TithikaColors.card,
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
    final settings = ref.watch(appSettingsProvider);
    final cityName = settings.location?.cityName ?? 'Not set';
    final language = settings.language;
    final monthSystem = settings.monthSystem;
    final notif = settings.notificationSettings;

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TithikaNavBar(title: 'Settings'),
                const Divider(color: TithikaColors.line, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    children: [
                      _SectionLabel('LOCATION'),
                      _SettingsRow(
                        label: 'Current location',
                        value: cityName,
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: TithikaColors.inkMuted, size: 18),
                        onTap: _pickCity,
                      ),
                      const SizedBox(height: 8),
                      _SettingsRow(
                        label: 'Use GPS location',
                        value: '',
                        trailing: _gpsLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: TithikaColors.shukla,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded,
                                color: TithikaColors.shukla, size: 18),
                        onTap: _gpsLoading ? null : _useGps,
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
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: TithikaColors.shukla,
                                ),
                              )
                            : Switch(
                                value: notif.enabled,
                                onChanged: _notifLoading
                                    ? null
                                    : _toggleNotifications,
                                activeThumbColor: Colors.white,
                                activeTrackColor: TithikaColors.shukla.withValues(alpha: 0.35),
                                inactiveThumbColor: TithikaColors.shukla.withValues(alpha: 0.5),
                                inactiveTrackColor: Colors.black,
                                trackOutlineColor: WidgetStatePropertyAll(TithikaColors.shukla.withValues(alpha: 0.5)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                      ),
                      if (notif.enabled) ...[
                        const SizedBox(height: 8),
                        _NotifSubGroup(
                          notif: notif,
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
                                color: TithikaColors.inkMuted,
                              ),
                        ),
                      ),
                      Text(
                        '© Astrodienst AG, Zurich — astro.com/swisseph',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TithikaColors.inkMuted,
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
                                  color: TithikaColors.inkMuted,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: TithikaColors.card,
          border: Border.all(color: TithikaColors.line),
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
    final defaultStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w500);

    return Container(
      decoration: BoxDecoration(
        color: TithikaColors.card,
        border: Border.all(color: TithikaColors.line),
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
                    : const Border(
                        bottom: BorderSide(color: TithikaColors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: style),
                  if (i == selected)
                    const Icon(Icons.check_rounded,
                        color: TithikaColors.shukla, size: 18),
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
  final ValueChanged<bool> onDailyChanged;
  final VoidCallback onTimeTap;
  final ValueChanged<bool> onFestivalChanged;
  final ValueChanged<bool> onEkadashiChanged;

  const _NotifSubGroup({
    required this.notif,
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
    return Container(
      decoration: BoxDecoration(
        color: TithikaColors.card,
        border: Border.all(color: TithikaColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _SubRow(
            label: 'Daily panchanga reminder',
            trailing: Switch(
              value: notif.dailyReminderEnabled,
              onChanged: onDailyChanged,
              activeThumbColor: Colors.white,
                                activeTrackColor: TithikaColors.shukla.withValues(alpha: 0.35),
                                inactiveThumbColor: TithikaColors.shukla.withValues(alpha: 0.5),
                                inactiveTrackColor: Colors.black,
                                trackOutlineColor: WidgetStatePropertyAll(TithikaColors.shukla.withValues(alpha: 0.5)),
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
                        color: TithikaColors.shukla,
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
              activeThumbColor: Colors.white,
                                activeTrackColor: TithikaColors.shukla.withValues(alpha: 0.35),
                                inactiveThumbColor: TithikaColors.shukla.withValues(alpha: 0.5),
                                inactiveTrackColor: Colors.black,
                                trackOutlineColor: WidgetStatePropertyAll(TithikaColors.shukla.withValues(alpha: 0.5)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            divider: true,
          ),
          _SubRow(
            label: 'Ekadashi alerts',
            trailing: Switch(
              value: notif.ekadashiAlertsEnabled,
              onChanged: onEkadashiChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: TithikaColors.shukla.withValues(alpha: 0.35),
              inactiveThumbColor: TithikaColors.shukla.withValues(alpha: 0.5),
              inactiveTrackColor: Colors.black,
              trackOutlineColor: WidgetStatePropertyAll(TithikaColors.shukla.withValues(alpha: 0.5)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: TithikaColors.line))
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
