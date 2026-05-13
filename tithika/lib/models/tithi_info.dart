import 'paksha.dart';
import 'special_tithi.dart';

/// All data for a single tithi instance.
class TithiInfo {
  /// 1–30 (1–15 = Shukla, 16–30 = Krishna; 30 = Amavasya).
  final int number;

  /// 1–15 within the paksha (display value).
  final int pakshaNumber;

  final Paksha paksha;

  /// UTC time this tithi began.
  final DateTime start;

  /// UTC time this tithi ends.
  final DateTime end;

  final SpecialTithi? special;

  const TithiInfo({
    required this.number,
    required this.pakshaNumber,
    required this.paksha,
    required this.start,
    required this.end,
    this.special,
  });

  String get nameEn => _tithiNamesEn[number - 1];
  String get nameDeva => _tithiNamesDeva[number - 1];

  /// Human-readable paksha + tithi, e.g. "Shukla Pratipada".
  String get fullNameEn => '${paksha == Paksha.shukla ? "Shukla" : "Krishna"} $nameEn';
  String get fullNameDeva => '${paksha == Paksha.shukla ? "शुक्ल" : "कृष्ण"} $nameDeva';
}

// ── String tables ─────────────────────────────────────────────────────────────

const _tithiNamesEn = [
  'Pratipada', 'Dvitiya', 'Tritiya', 'Chaturthi', 'Panchami',
  'Shashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
  'Ekadashi', 'Dvadashi', 'Trayodashi', 'Chaturdashi', 'Purnima',
  'Pratipada', 'Dvitiya', 'Tritiya', 'Chaturthi', 'Panchami',
  'Shashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
  'Ekadashi', 'Dvadashi', 'Trayodashi', 'Chaturdashi', 'Amavasya',
];

const _tithiNamesDeva = [
  'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पञ्चमी',
  'षष्ठी', 'सप्तमी', 'अष्टमी', 'नवमी', 'दशमी',
  'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी', 'पूर्णिमा',
  'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पञ्चमी',
  'षष्ठी', 'सप्तमी', 'अष्टमी', 'नवमी', 'दशमी',
  'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी', 'अमावस्या',
];

