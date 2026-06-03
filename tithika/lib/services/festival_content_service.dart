import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/festival_content.dart';

class FestivalContentService {
  static final _cache = <String, Map<String, FestivalContent>>{};

  static String _assetPath(AppLanguage lang) => switch (lang) {
        AppLanguage.hindiDevanagari => 'assets/festival_content/hi.json',
        AppLanguage.tamil           => 'assets/festival_content/ta.json',
        AppLanguage.bengali         => 'assets/festival_content/bn.json',
        _                           => 'assets/festival_content/en.json',
      };

  static Future<FestivalContent?> load(
      String canonicalKey, AppLanguage lang) async {
    final path = _assetPath(lang);
    if (!_cache.containsKey(path)) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = json.decode(raw) as Map<String, dynamic>;
        _cache[path] = data.map(
          (k, v) => MapEntry(k, FestivalContent.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {
        _cache[path] = {};
      }
    }
    return _cache[path]![canonicalKey];
  }
}
