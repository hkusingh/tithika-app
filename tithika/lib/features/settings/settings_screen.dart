import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/app_location.dart';
import '../../models/app_settings.dart';
import '../../state/providers.dart';
import '../shared/city_picker_sheet.dart';
import '../shared/starfield_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _gpsLoading = false;

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

      final tzId = await FlutterTimezone.getLocalTimezone();
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final cityName = settings.location?.cityName ?? 'Not set';
    final language = settings.language;
    final monthSystem = settings.monthSystem;

    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: TithikaColors.inkSoft),
                        onPressed: () => context.go('/'),
                      ),
                      Text(
                        'Settings',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
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
                        options: const ['English', 'Hindi (Latin)', 'हिन्दी'],
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

