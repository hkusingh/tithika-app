import 'package:flutter/material.dart';

import 'app_settings.dart';

enum HoraPlanet { sun, venus, mercury, moon, saturn, jupiter, mars }

extension HoraPlanetExt on HoraPlanet {
  String get nameEn => switch (this) {
    HoraPlanet.sun     => 'Sun',
    HoraPlanet.venus   => 'Venus',
    HoraPlanet.mercury => 'Mercury',
    HoraPlanet.moon    => 'Moon',
    HoraPlanet.saturn  => 'Saturn',
    HoraPlanet.jupiter => 'Jupiter',
    HoraPlanet.mars    => 'Mars',
  };

  String get _nameDeva => switch (this) {
    HoraPlanet.sun     => 'सूर्य',
    HoraPlanet.venus   => 'शुक्र',
    HoraPlanet.mercury => 'बुध',
    HoraPlanet.moon    => 'चंद्र',
    HoraPlanet.saturn  => 'शनि',
    HoraPlanet.jupiter => 'बृहस्पति',
    HoraPlanet.mars    => 'मंगल',
  };

  String get _nameHindiLatin => switch (this) {
    HoraPlanet.sun     => 'Surya',
    HoraPlanet.venus   => 'Shukra',
    HoraPlanet.mercury => 'Budha',
    HoraPlanet.moon    => 'Chandra',
    HoraPlanet.saturn  => 'Shani',
    HoraPlanet.jupiter => 'Brihaspati',
    HoraPlanet.mars    => 'Mangal',
  };

  String get _nameTamil => switch (this) {
    HoraPlanet.sun     => 'சூரியன்',
    HoraPlanet.venus   => 'சுக்கிரன்',
    HoraPlanet.mercury => 'புதன்',
    HoraPlanet.moon    => 'சந்திரன்',
    HoraPlanet.saturn  => 'சனி',
    HoraPlanet.jupiter => 'குரு',
    HoraPlanet.mars    => 'செவ்வாய்',
  };

  String get _nameBengali => switch (this) {
    HoraPlanet.sun     => 'সূর্য',
    HoraPlanet.venus   => 'শুক্র',
    HoraPlanet.mercury => 'বুধ',
    HoraPlanet.moon    => 'চন্দ্র',
    HoraPlanet.saturn  => 'শনি',
    HoraPlanet.jupiter => 'বৃহস্পতি',
    HoraPlanet.mars    => 'মঙ্গল',
  };

  String name(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => _nameDeva,
    AppLanguage.hindiLatin      => _nameHindiLatin,
    AppLanguage.tamil           => _nameTamil,
    AppLanguage.bengali         => _nameBengali,
    _                           => nameEn,
  };

  String get glyph => switch (this) {
    HoraPlanet.sun     => '☉',
    HoraPlanet.venus   => '♀',
    HoraPlanet.mercury => '☿',
    HoraPlanet.moon    => '☽',
    HoraPlanet.saturn  => '♄',
    HoraPlanet.jupiter => '♃',
    HoraPlanet.mars    => '♂',
  };

  Color get accentColor => switch (this) {
    HoraPlanet.sun     => const Color(0xFFFFB347),
    HoraPlanet.venus   => const Color(0xFFE6B85C),
    HoraPlanet.mercury => const Color(0xFF7D8DF0),
    HoraPlanet.moon    => const Color(0xFFF7F2DC),
    HoraPlanet.saturn  => const Color(0xFFAAB0C5),
    HoraPlanet.jupiter => const Color(0xFFE6B85C),
    HoraPlanet.mars    => const Color(0xFFFF7070),
  };
}

class HoraSlot {
  final HoraPlanet planet;
  final DateTime start;
  final DateTime end;
  final bool isDay;

  const HoraSlot({
    required this.planet,
    required this.start,
    required this.end,
    required this.isDay,
  });
}
