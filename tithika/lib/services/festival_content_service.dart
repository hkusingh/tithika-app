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
        AppLanguage.odia            => 'assets/festival_content/or.json',
        AppLanguage.telugu          => 'assets/festival_content/te.json',
        AppLanguage.malayalam       => 'assets/festival_content/ml.json',
        AppLanguage.kannada         => 'assets/festival_content/kn.json',
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
    final content = _cache[path]![canonicalKey];
    if (content != null) return content;

    // Fall back to English when the key is missing from the language file.
    if (lang == AppLanguage.english) return null;
    return load(canonicalKey, AppLanguage.english);
  }
}
