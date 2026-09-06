import 'dart:async';

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
      // Several OEMs (Samsung, ColorOS/Realme, MIUI) kill the app in the
      // background before scheduled notifications can fire unless the app
      // is exempted from battery optimization — ask right after the
      // notification permission, while the user is already in this flow.
      await NotificationService.requestBatteryOptimizationExemption();
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

  Future<void> _pickAlertTime() async {
    final current = ref.read(appSettingsProvider).notificationSettings;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: current.alertHour, minute: current.alertMinute),
    );
    if (picked != null && mounted) {
      await ref.read(appSettingsProvider.notifier).setNotificationSettings(
            current.copyWith(
              alertHour: picked.hour,
              alertMinute: picked.minute,
            ),
          );
    }
  }

  Future<void> _pickAlertDays() async {
    final colors = TithikaColors.of(context);
    final current = ref.read(appSettingsProvider).notificationSettings;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: colors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (var d = 0; d <= maxAlertDaysBefore; d++)
              ListTile(
                title: Text(
                  _NotifSubGroup.alertDaysLabel(d),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: d == current.alertDaysBefore
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
                trailing: d == current.alertDaysBefore
                    ? Icon(Icons.check_rounded, size: 18, color: colors.shukla)
                    : null,
                onTap: () => Navigator.of(ctx).pop(d),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await ref
          .read(appSettingsProvider.notifier)
          .setNotificationSettings(current.copyWith(alertDaysBefore: picked));
    }
  }

  /// Turning the master switch on is a widening change the user should
  /// understand — it supersedes any individual bells (which are preserved,
  /// and take effect again when it is switched back off).
  Future<void> _setFestivalAlerts(bool enable) async {
    final current = ref.read(appSettingsProvider).notificationSettings;
    if (enable) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notify for all festivals?'),
          content: const Text(
            "You'll be notified for every festival. To choose individual "
            'festivals instead, leave this off and tap the bell on any '
            'festival.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Turn on'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await ref.read(appSettingsProvider.notifier).setNotificationSettings(
        current.copyWith(festivalAlertsEnabled: enable));
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
                      _LanguagePickerRow(
                        selected: language,
                        onChanged: (lang) => ref
                            .read(appSettingsProvider.notifier)
                            .setLanguage(lang),
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
                        _DailyReminderGroup(
                          notif: notif,
                          switchStyle: switchStyle,
                          onDailyChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(dailyReminderEnabled: v)),
                          onTimeTap: _pickReminderTime,
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel('FESTIVALS & OBSERVANCES'),
                        _NotifSubGroup(
                          notif: notif,
                          switchStyle: switchStyle,
                          onAlertDaysTap: _pickAlertDays,
                          onAlertTimeTap: _pickAlertTime,
                          onFestivalChanged: _setFestivalAlerts,
                          onEkadashiChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(ekadashiAlertsEnabled: v)),
                          onPurnimaChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(purnimaAlertsEnabled: v)),
                          onAmavasyaChanged: (v) => ref
                              .read(appSettingsProvider.notifier)
                              .setNotificationSettings(
                                  notif.copyWith(amavasyaAlertsEnabled: v)),
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

  const _RadioGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
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
          final style = defaultStyle;
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

// ── Language picker ───────────────────────────────────────────────────────────

class _LanguagePickerRow extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguagePickerRow({required this.selected, required this.onChanged});

  static const _labels = [
    'English', 'Hindi (Latin)', 'हिन्दी',
    'தமிழ்', 'বাংলা', 'ଓଡ଼ିଆ',
    'తెలుగు', 'മലയാളം', 'ಕನ್ನಡ',
  ];

  TextStyle? _styleFor(int i, TextStyle? base) => switch (i) {
    2 => devanagariStyle(base, fontWeight: FontWeight.w500),
    3 => tamilStyle(base, fontWeight: FontWeight.w500),
    4 => bengaliStyle(base, fontWeight: FontWeight.w500),
    5 => odiaStyle(base, fontWeight: FontWeight.w500),
    6 => teluguStyle(base, fontWeight: FontWeight.w500),
    7 => malayalamStyle(base, fontWeight: FontWeight.w500),
    8 => kannadaStyle(base, fontWeight: FontWeight.w500),
    _ => base?.copyWith(fontWeight: FontWeight.w500),
  };

  void _showSheet(BuildContext context) {
    final colors = TithikaColors.of(context);
    final base = Theme.of(context).textTheme.bodyMedium;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppLanguage.values.length,
                itemBuilder: (_, i) {
                  final lang = AppLanguage.values[i];
                  final isSelected = lang == selected;
                  final isLast = i == AppLanguage.values.length - 1;
                  return InkWell(
                    onTap: () {
                      onChanged(lang);
                      Navigator.pop(sheetCtx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      decoration: isLast
                          ? null
                          : BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: colors.line))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_labels[i], style: _styleFor(i, base)),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: colors.shukla, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    final base   = Theme.of(context).textTheme.bodyMedium;
    final idx    = selected.index;
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Language',
                style: base?.copyWith(fontWeight: FontWeight.w500)),
            Row(children: [
              Text(
                _labels[idx],
                style: _styleFor(idx, base)
                    ?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: colors.inkMuted, size: 18),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Notification sub-options card ─────────────────────────────────────────────

/// Card shell shared by the notification sub-groups, matching the other
/// settings sections.
class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }
}

/// The daily panchanga reminder and its time. Independent of the festival and
/// observance alerts below, so it gets its own card.
class _DailyReminderGroup extends StatelessWidget {
  final NotificationSettings notif;
  final _SwitchStyle switchStyle;
  final ValueChanged<bool> onDailyChanged;
  final VoidCallback onTimeTap;

  const _DailyReminderGroup({
    required this.notif,
    required this.switchStyle,
    required this.onDailyChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GroupCard(
      children: [
        _SubRow(
          label: 'Daily panchanga reminder',
          trailing: _NotifSubGroup.styledSwitch(
              switchStyle, notif.dailyReminderEnabled, onDailyChanged),
          // Only divides when the time row follows it.
          divider: notif.dailyReminderEnabled,
        ),
        if (notif.dailyReminderEnabled)
          _SubRow(
            label: 'Reminder time',
            trailing: _NotifSubGroup.valueLabel(
              context,
              _NotifSubGroup.fmtTime(
                  notif.dailyReminderHour, notif.dailyReminderMinute),
              onTimeTap,
            ),
            divider: false,
          ),
      ],
    );
  }
}

/// Festival, Ekadashi, Purnima and Amavasya alerts, plus the timing that
/// governs all four.
class _NotifSubGroup extends StatelessWidget {
  final NotificationSettings notif;
  final _SwitchStyle switchStyle;
  final VoidCallback onAlertDaysTap;
  final VoidCallback onAlertTimeTap;
  final ValueChanged<bool> onFestivalChanged;
  final ValueChanged<bool> onEkadashiChanged;
  final ValueChanged<bool> onPurnimaChanged;
  final ValueChanged<bool> onAmavasyaChanged;

  const _NotifSubGroup({
    required this.notif,
    required this.switchStyle,
    required this.onAlertDaysTap,
    required this.onAlertTimeTap,
    required this.onFestivalChanged,
    required this.onEkadashiChanged,
    required this.onPurnimaChanged,
    required this.onAmavasyaChanged,
  });

  static String fmtTime(int h, int m) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }

  static String alertDaysLabel(int days) => switch (days) {
        0 => 'On the day',
        1 => '1 day before',
        _ => '$days days before',
      };

  static Widget styledSwitch(
          _SwitchStyle style, bool value, ValueChanged<bool> onChanged) =>
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: style.activeThumb,
        activeTrackColor: style.activeTrack,
        inactiveThumbColor: style.inactiveThumb,
        inactiveTrackColor: style.inactiveTrack,
        trackOutlineColor: WidgetStatePropertyAll(style.trackOutline),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  static Widget valueLabel(
      BuildContext context, String text, VoidCallback onTap) {
    final colors = TithikaColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.shukla,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 16, color: colors.inkMuted),
        ],
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) =>
      styledSwitch(switchStyle, value, onChanged);

  /// Honest report of what the festival setting will actually do — the master
  /// switch alone can't say, since "off" means "individually chosen" rather
  /// than "silent".
  String get _festivalSubtitle {
    if (notif.festivalAlertsEnabled) return 'All festivals';
    final n = notif.selectedFestivals.length;
    if (n == 0) return 'None selected — choose on the Festivals page';
    return n == 1 ? '1 festival selected' : '$n festivals selected';
  }

  @override
  Widget build(BuildContext context) {
    return _GroupCard(
      children: [
        // Timing sits above the categories it governs.
        _SubRow(
          label: 'Alert me',
          subtitle: 'For festivals, Ekadashi, Purnima, Amavasya',
          trailing: valueLabel(
            context,
            alertDaysLabel(notif.alertDaysBefore),
            onAlertDaysTap,
          ),
          divider: true,
        ),
        _SubRow(
          label: 'Alert time',
          trailing: valueLabel(
            context,
            fmtTime(notif.alertHour, notif.alertMinute),
            onAlertTimeTap,
          ),
          divider: true,
        ),
        _SubRow(
          label: 'All festivals',
          subtitle: _festivalSubtitle,
          trailing: _switch(notif.festivalAlertsEnabled, onFestivalChanged),
          divider: true,
        ),
        _SubRow(
          label: 'Ekadashi alerts',
          trailing: _switch(notif.ekadashiAlertsEnabled, onEkadashiChanged),
          divider: true,
        ),
        _SubRow(
          label: 'Purnima alerts',
          trailing: _switch(notif.purnimaAlertsEnabled, onPurnimaChanged),
          divider: true,
        ),
        _SubRow(
          label: 'Amavasya alerts',
          trailing: _switch(notif.amavasyaAlertsEnabled, onAmavasyaChanged),
          divider: false,
        ),
      ],
    );
  }
}

class _SubRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget trailing;
  final bool divider;

  const _SubRow({
    required this.label,
    this.subtitle,
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
          // Flexible so a long subtitle wraps instead of pushing [trailing]
          // off the right edge.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.inkMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
