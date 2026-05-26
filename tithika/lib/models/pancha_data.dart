import 'package:flutter/material.dart';

enum YogaQuality { excellent, auspicious, neutral, inauspicious }

enum KaranaType {
  // 7 moveable (repeat through each lunar month)
  bava,
  balava,
  kaulava,
  taitila,
  gara,
  vanija,
  vishti,
  // 4 fixed (each occurs once per lunar month)
  shakuni,
  chatushpada,
  naga,
  kimstughna,
}

extension KaranaTypeX on KaranaType {
  bool get isInauspicious => this == KaranaType.vishti;
  bool get isFixed =>
      this == KaranaType.shakuni ||
      this == KaranaType.chatushpada ||
      this == KaranaType.naga ||
      this == KaranaType.kimstughna;

  Color get dotColor => switch (this) {
        KaranaType.vishti                    => const Color(0xFFB84040),
        KaranaType.shakuni ||
        KaranaType.chatushpada ||
        KaranaType.naga ||
        KaranaType.kimstughna                => const Color(0xFF8890A8),
        _                                    => const Color(0xFF2A8A5A),
      };
}

extension YogaQualityX on YogaQuality {
  Color get color => switch (this) {
        YogaQuality.excellent    => const Color(0xFFC8922A),
        YogaQuality.auspicious   => const Color(0xFF2A8A5A),
        YogaQuality.neutral      => const Color(0xFF8890A8),
        YogaQuality.inauspicious => const Color(0xFFB84040),
      };
}

class YogaInfo {
  final int number;    // 1–27
  final DateTime start;
  final DateTime end;

  const YogaInfo({
    required this.number,
    required this.start,
    required this.end,
  });

  /// Quality tier for this yoga number.
  YogaQuality get quality => _yogaQuality[number - 1];

  static const _yogaQuality = [
    YogaQuality.inauspicious, // 1  Vishkambha
    YogaQuality.auspicious,   // 2  Priti
    YogaQuality.auspicious,   // 3  Ayushman
    YogaQuality.auspicious,   // 4  Saubhagya
    YogaQuality.excellent,    // 5  Shobhana
    YogaQuality.neutral,      // 6  Atiganda
    YogaQuality.auspicious,   // 7  Sukarma
    YogaQuality.auspicious,   // 8  Dhriti
    YogaQuality.neutral,      // 9  Shula
    YogaQuality.neutral,      // 10 Ganda
    YogaQuality.excellent,    // 11 Vriddhi
    YogaQuality.excellent,    // 12 Dhruva
    YogaQuality.inauspicious, // 13 Vyaghata
    YogaQuality.excellent,    // 14 Harshana
    YogaQuality.neutral,      // 15 Vajra
    YogaQuality.excellent,    // 16 Siddhi
    YogaQuality.inauspicious, // 17 Vyatipata
    YogaQuality.auspicious,   // 18 Variyan
    YogaQuality.inauspicious, // 19 Parigha
    YogaQuality.auspicious,   // 20 Shiva
    YogaQuality.excellent,    // 21 Siddha
    YogaQuality.auspicious,   // 22 Sadhya
    YogaQuality.excellent,    // 23 Shubha
    YogaQuality.auspicious,   // 24 Shukla
    YogaQuality.excellent,    // 25 Brahma
    YogaQuality.excellent,    // 26 Indra
    YogaQuality.inauspicious, // 27 Vaidhriti
  ];
}

class KaranaInfo {
  final KaranaType type;
  final DateTime start;
  final DateTime end;

  const KaranaInfo({
    required this.type,
    required this.start,
    required this.end,
  });
}

class PanchaData {
  final YogaInfo currentYoga;
  final YogaInfo nextYoga;

  /// Karanas spanning from just before sunrise to next sunrise + buffer.
  /// Typically 2–3 entries; past ones are kept for context.
  final List<KaranaInfo> karanas;

  const PanchaData({
    required this.currentYoga,
    required this.nextYoga,
    required this.karanas,
  });
}
