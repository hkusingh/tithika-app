import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/app_location.dart';

class CitySearchService {
  List<AppLocation> _cities = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/cities/cities.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cities = list.map((e) => AppLocation.fromJson(e as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  /// Returns up to [limit] cities matching [query].
  ///
  /// Ranking: exact name match > starts-with > contains (all case-insensitive).
  /// An empty query returns the first [limit] entries (India-first order from asset).
  List<AppLocation> search(String query, {int limit = 40}) {
    if (!_loaded) return [];
    if (query.isEmpty) return _cities.take(limit).toList();

    final q = query.toLowerCase().trim();

    final exact   = <AppLocation>[];
    final starts  = <AppLocation>[];
    final contains = <AppLocation>[];

    for (final city in _cities) {
      final name = city.cityName.toLowerCase();
      if (name == q) {
        exact.add(city);
      } else if (name.startsWith(q)) {
        starts.add(city);
      } else if (name.contains(q)) {
        contains.add(city);
      }
    }

    return [...exact, ...starts, ...contains].take(limit).toList();
  }
}
