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
  String get nameTamil => _tithiNamesTamil[number - 1];
  String get nameBengali => _tithiNamesBengali[number - 1];

  /// Human-readable paksha + tithi, e.g. "Shukla Pratipada".
  /// Purnima (15) and Amavasya (30) are self-describing — no paksha prefix.
  bool get _needsPakshaPrefix => number != 15 && number != 30;

  String get fullNameEn => _needsPakshaPrefix
      ? '${paksha == Paksha.shukla ? "Shukla" : "Krishna"} $nameEn'
      : nameEn;
  String get fullNameDeva => _needsPakshaPrefix
      ? '${paksha == Paksha.shukla ? "शुक्ल" : "कृष्ण"} $nameDeva'
      : nameDeva;
  String get fullNameTamil => _needsPakshaPrefix
      ? '${paksha == Paksha.shukla ? "வளர்பிறை" : "தேய்பிறை"} $nameTamil'
      : nameTamil;
  String get fullNameBengali => _needsPakshaPrefix
      ? '${paksha == Paksha.shukla ? "শুক্ল" : "কৃষ্ণ"} $nameBengali'
      : nameBengali;
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

const _tithiNamesTamil = [
  'பிரதமை', 'துவிதியை', 'திரிதியை', 'சதுர்த்தி', 'பஞ்சமி',
  'ஷஷ்டி', 'சப்தமி', 'அஷ்டமி', 'நவமி', 'தசமி',
  'ஏகாதசி', 'துவாதசி', 'திரயோதசி', 'சதுர்தசி', 'பவுர்ணமி',
  'பிரதமை', 'துவிதியை', 'திரிதியை', 'சதுர்த்தி', 'பஞ்சமி',
  'ஷஷ்டி', 'சப்தமி', 'அஷ்டமி', 'நவமி', 'தசமி',
  'ஏகாதசி', 'துவாதசி', 'திரயோதசி', 'சதுர்தசி', 'அமாவாசை',
];

const _tithiNamesBengali = [
  'প্রতিপদ', 'দ্বিতীয়া', 'তৃতীয়া', 'চতুর্থী', 'পঞ্চমী',
  'ষষ্ঠী', 'সপ্তমী', 'অষ্টমী', 'নবমী', 'দশমী',
  'একাদশী', 'দ্বাদশী', 'ত্রয়োদশী', 'চতুর্দশী', 'পূর্ণিমা',
  'প্রতিপদ', 'দ্বিতীয়া', 'তৃতীয়া', 'চতুর্থী', 'পঞ্চমী',
  'ষষ্ঠী', 'সপ্তমী', 'অষ্টমী', 'নবমী', 'দশমী',
  'একাদশী', 'দ্বাদশী', 'ত্রয়োদশী', 'চতুর্দশী', 'অমাবস্যা',
];

