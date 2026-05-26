import 'package:flutter/material.dart';

enum ChoghadiyaType { amrit, shubh, labh, char, udveg, kaal, rog }

extension ChoghadiyaTypeX on ChoghadiyaType {
  bool get isAuspicious =>
      this == ChoghadiyaType.amrit ||
      this == ChoghadiyaType.shubh ||
      this == ChoghadiyaType.labh;

  bool get isInauspicious =>
      this == ChoghadiyaType.udveg ||
      this == ChoghadiyaType.kaal ||
      this == ChoghadiyaType.rog;

  // Fixed accent colors — theme-independent, like HoraPlanet.accentColor.
  Color get dotColor => switch (this) {
    ChoghadiyaType.amrit => const Color(0xFF2A8A5A),
    ChoghadiyaType.shubh => const Color(0xFFC8922A),
    ChoghadiyaType.labh  => const Color(0xFF5A6BD8),
    ChoghadiyaType.char  => const Color(0xFF8890A8),
    ChoghadiyaType.udveg => const Color(0xFFB84040),
    ChoghadiyaType.kaal  => const Color(0xFF7A4080),
    ChoghadiyaType.rog   => const Color(0xFFB84040),
  };
}

class ChoghadiyaSlot {
  final ChoghadiyaType type;
  final DateTime start;
  final DateTime end;

  const ChoghadiyaSlot({
    required this.type,
    required this.start,
    required this.end,
  });
}

class MuhurtaData {
  final DateTimeRange rahuKaal;
  final DateTimeRange yamaganda;
  final DateTimeRange gulika;

  /// Null on Wednesdays — Abhijit is not observed.
  final DateTimeRange? abhijit;

  /// Pre-dawn window: sunriseUtc − 96 min → sunriseUtc − 48 min.
  final DateTimeRange brahma;

  final List<ChoghadiyaSlot> dayChoghadiya;    // 8 slots, sunrise → sunset
  final List<ChoghadiyaSlot> nightChoghadiya;  // 8 slots, sunset → next sunrise

  const MuhurtaData({
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulika,
    this.abhijit,
    required this.brahma,
    required this.dayChoghadiya,
    required this.nightChoghadiya,
  });
}
