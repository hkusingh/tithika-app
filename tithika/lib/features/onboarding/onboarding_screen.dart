import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/app_location.dart';
import '../shared/starfield_background.dart';
import '../../state/providers.dart';
import '../shared/city_picker_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _gpsLoading = false;
  String? _errorMessage;

  // ── GPS path ─────────────────────────────────────────────────────────────────

  Future<void> _useGps() async {
    setState(() { _gpsLoading = true; _errorMessage = null; });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = permission == LocationPermission.deniedForever
              ? 'Location access is permanently denied. Enable it in Settings, or enter your city manually.'
              : 'Location permission denied. You can enter your city manually below.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      String cityName = 'My Location';
      String country = '';
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.locality?.isNotEmpty == true
              ? p.locality!
              : p.administrativeArea ?? cityName;
          country = p.isoCountryCode ?? '';
        }
      } catch (_) {
        // Reverse geocode failed — proceed with coordinates and generic name.
      }

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

      await ref.read(appSettingsProvider.notifier).setLocation(location);
      if (mounted) context.go(Routes.dayView);
    } catch (e) {
      setState(() { _errorMessage = 'Could not get location. Try entering your city manually.'; });
    } finally {
      if (mounted) setState(() { _gpsLoading = false; });
    }
  }

  // ── Manual path ──────────────────────────────────────────────────────────────

  Future<void> _enterManually() async {
    final selected = await showModalBottomSheet<AppLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityPickerSheet(),
    );
    if (selected != null && mounted) {
      await ref.read(appSettingsProvider.notifier).setLocation(selected);
      if (mounted) context.go(Routes.dayView);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const StarfieldBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _MoonGlyph(),
                  const SizedBox(height: 24),
                  Text('Tithika', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 6),
                  Text(
                    'तिथिका',
                    style: devanagariStyle(
                      Theme.of(context).textTheme.titleLarge,
                      color: colors.shukla,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set your location to see tithis calculated\nfor your local sunrise.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.inkSoft,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _PrimaryButton(
                    label: _gpsLoading ? 'Getting location…' : 'Use my current location',
                    icon: Icons.my_location_rounded,
                    loading: _gpsLoading,
                    onTap: _gpsLoading ? null : _useGps,
                  ),
                  const SizedBox(height: 10),
                  _SecondaryButton(
                    label: 'Enter city manually',
                    onTap: _enterManually,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.festival,
                            height: 1.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _MoonGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shuklaGlow = TithikaColors.of(context).shuklaGlow;
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shuklaGlow,
            blurRadius: 48,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Image.asset(
        'assets/moon_circle.png',
        width: 160,
        height: 160,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shukla = TithikaColors.of(context).shukla;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: shukla,
          foregroundColor: const Color(0xFF1C1300),
          disabledBackgroundColor: shukla.withAlpha(120),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1C1300)),
              )
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.lineStrong, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}
