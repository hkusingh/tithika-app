import 'lunar_month.dart';
import 'nakshatra_info.dart';
import 'tithi_info.dart';

/// All astronomical data needed to render a single calendar day.
///
/// [tithi] is the tithi active at local sunrise (the "calendar day's tithi").
/// [nakshatra] is the nakshatra active at local sunrise.
/// Both carry their UTC start/end times so the UI can display the full window.
class DayData {
  final DateTime localDate;

  /// Tithi active at local sunrise — defines the calendar day.
  final TithiInfo tithi;

  /// Nakshatra active at local sunrise.
  final NakshatraInfo nakshatra;

  final DateTime? sunriseUtc;
  final DateTime? sunsetUtc;

  final LunarMonth lunarMonth;

  /// 0–11, sidereal (Lahiri): 0 = Mesha, 1 = Vrishabha, …, 11 = Meena.
  final int sunZodiacSign;

  /// True if the sidereal sun crossed a 30° sign boundary between the
  /// previous sunrise and this sunrise (i.e. Sankranti day).
  final bool sunZodiacEntryToday;

  /// Festival name for this day, or null.
  final String? festivalName;

  /// A second tithi that begins after sunrise but before the next sunrise
  /// (kshaya / skipped tithi). Null on most days.
  final TithiInfo? secondaryTithi;

  /// True if this day falls within an Adhika (intercalary) lunar month —
  /// i.e. no solar Sankranti occurs between two consecutive Purnimas.
  final bool isAdhika;

  const DayData({
    required this.localDate,
    required this.tithi,
    required this.nakshatra,
    this.sunriseUtc,
    this.sunsetUtc,
    required this.lunarMonth,
    required this.sunZodiacSign,
    this.sunZodiacEntryToday = false,
    this.festivalName,
    this.secondaryTithi,
    this.isAdhika = false,
  });

  DayData copyWith({
    String? festivalName,
    TithiInfo? secondaryTithi,
    bool? isAdhika,
    LunarMonth? lunarMonth,
  }) {
    return DayData(
      localDate: localDate,
      tithi: tithi,
      nakshatra: nakshatra,
      sunriseUtc: sunriseUtc,
      sunsetUtc: sunsetUtc,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      sunZodiacSign: sunZodiacSign,
      sunZodiacEntryToday: sunZodiacEntryToday,
      festivalName: festivalName ?? this.festivalName,
      secondaryTithi: secondaryTithi ?? this.secondaryTithi,
      isAdhika: isAdhika ?? this.isAdhika,
    );
  }
}
