import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'city_search_service.dart';
import 'eclipse_service.dart';
import 'ephemeris_service.dart';
import 'settings_repository.dart';
import 'sweph_ephemeris_service.dart';
import 'tithi_service.dart';

/// Must be overridden in main() before the container is used.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(sharedPreferencesProvider));
});

/// Initialized [EphemerisService] — resolves after sweph is ready.
final ephemerisServiceProvider = FutureProvider<EphemerisService>((ref) async {
  final service = SwephEphemerisService();
  await service.initialize();
  return service;
});

/// [TithiService] backed by the live [EphemerisService].
final tithiServiceProvider = FutureProvider<TithiService>((ref) async {
  final ephe = await ref.watch(ephemerisServiceProvider.future);
  return TithiService(ephe);
});

/// [EclipseService] backed by the live [EphemerisService].
final eclipseServiceProvider = FutureProvider<EclipseService>((ref) async {
  final ephe = await ref.watch(ephemerisServiceProvider.future);
  return EclipseService(ephe);
});

/// Loaded city database for the city picker.
final citySearchServiceProvider = FutureProvider<CitySearchService>((ref) async {
  final svc = CitySearchService();
  await svc.load();
  return svc;
});
