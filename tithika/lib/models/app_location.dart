import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

class AppLocation {
  final double lat;
  final double lon;
  final String cityName;
  final String country;
  final int tzOffsetMinutes; // kept for backward-compat / fallback
  final String tzId; // IANA timezone ID, e.g. "America/New_York"

  const AppLocation({
    required this.lat,
    required this.lon,
    required this.cityName,
    this.country = '',
    required this.tzOffsetMinutes,
    this.tzId = '',
  });

  /// UTC offset in effect on [localDate], accounting for DST.
  /// Falls back to the fixed [tzOffsetMinutes] when [tzId] is unknown.
  Duration tzOffsetAt(DateTime localDate) {
    if (tzId.isEmpty) return Duration(minutes: tzOffsetMinutes);
    try {
      final loc = tz.getLocation(tzId);
      final tzDate = tz.TZDateTime(loc, localDate.year, localDate.month, localDate.day);
      return tzDate.timeZoneOffset;
    } catch (_) {
      return Duration(minutes: tzOffsetMinutes);
    }
  }

  /// Current UTC offset (used for display / one-off conversions).
  Duration get tzOffset => tzOffsetAt(DateTime.now());

  static const ujjain = AppLocation(
    lat: 23.18,
    lon: 75.78,
    cityName: 'Ujjain',
    country: 'IN',
    tzOffsetMinutes: 330,
    tzId: 'Asia/Kolkata',
  );

  AppLocation copyWith({
    double? lat,
    double? lon,
    String? cityName,
    String? country,
    int? tzOffsetMinutes,
    String? tzId,
  }) {
    return AppLocation(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      tzId: tzId ?? this.tzId,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'cityName': cityName,
        'country': country,
        'tzOffsetMinutes': tzOffsetMinutes,
        'tzId': tzId,
      };

  factory AppLocation.fromJson(Map<String, dynamic> json) => AppLocation(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        cityName: (json['cityName'] ?? json['name']) as String,
        country: (json['country'] as String?) ?? '',
        tzOffsetMinutes: (json['tzOffsetMinutes'] as int?) ?? 0,
        tzId: (json['timezone'] ?? json['tzId'] ?? '') as String,
      );

  static AppLocation? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}
