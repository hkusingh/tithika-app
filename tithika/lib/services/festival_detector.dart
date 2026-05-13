import '../models/day_data.dart';
import '../models/lunar_month.dart';

abstract final class FestivalDetector {
  /// Returns the festival name for [day], or null if it is an ordinary day.
  ///
  /// Solar festivals (Sankranti) take priority over tithi-based names.
  /// Tithi numbers use the continuous 1–30 scale: Shukla 1–15 = 1–15,
  /// Krishna 1–14 = 16–29, Amavasya = 30.
  static String? detect(DayData day) {
    final t = day.tithi.number;
    final m = day.lunarMonth;

    // ── Solar festivals ──────────────────────────────────────────────────────
    if (day.sunZodiacEntryToday) {
      return switch (day.sunZodiacSign) {
        0 => 'Baisakhi / Vishu',           // Sun enters Mesha
        9 => 'Makar Sankranti / Pongal',   // Sun enters Makara
        _ => null,
      };
    }

    // ── Tithi-based festivals ────────────────────────────────────────────────
    // Month follows Purnimanta convention: month ends at Purnima.
    // Krishna paksha days belong to the month whose Purnima comes next.
    // e.g. Dhanteras (Kartika Krishna 13) → lunarMonth = kartika.
    return switch ((m, t)) {
      // Chaitra
      (LunarMonth.chaitra, 1)  => 'Chaitra Navratri (Day 1)',
      (LunarMonth.chaitra, 2)  => 'Chaitra Navratri (Day 2)',
      (LunarMonth.chaitra, 3)  => 'Chaitra Navratri (Day 3)',
      (LunarMonth.chaitra, 4)  => 'Chaitra Navratri (Day 4)',
      (LunarMonth.chaitra, 5)  => 'Chaitra Navratri (Day 5)',
      (LunarMonth.chaitra, 6)  => 'Chaitra Navratri (Day 6)',
      (LunarMonth.chaitra, 7)  => 'Chaitra Navratri (Day 7)',
      (LunarMonth.chaitra, 8)  => 'Chaitra Navratri (Day 8)',
      (LunarMonth.chaitra, 9)  => 'Ram Navami',           // Shukla 9
      (LunarMonth.chaitra, 15) => 'Hanuman Jayanti',      // Purnima
      (LunarMonth.chaitra, 16) => 'Holi',                 // Krishna 1 = Rangwali Holi

      // Vaishakha
      (LunarMonth.vaishakha, 3)  => 'Akshaya Tritiya',   // Shukla 3
      (LunarMonth.vaishakha, 15) => 'Buddha Purnima',

      // Jyeshtha
      (LunarMonth.jyeshtha, 11) => 'Nirjala Ekadashi',   // Shukla 11
      (LunarMonth.jyeshtha, 30) => 'Vat Savitri',        // Amavasya

      // Ashadha
      (LunarMonth.ashadha, 2)  => 'Rath Yatra',          // Shukla 2
      (LunarMonth.ashadha, 11) => 'Devshayani Ekadashi', // Shukla 11
      (LunarMonth.ashadha, 15) => 'Guru Purnima',

      // Shravana
      (LunarMonth.shravana, 5)  => 'Nag Panchami',       // Shukla 5
      (LunarMonth.shravana, 15) => 'Raksha Bandhan',

      // Bhadrapada — Krishna 8 (tithi 23) falls here because in Purnimanta
      // the days after Shravana Purnima belong to Bhadrapada month.
      (LunarMonth.bhadrapada, 23) => 'Krishna Janmashtami', // Krishna 8
      (LunarMonth.bhadrapada, 4)  => 'Ganesh Chaturthi',    // Shukla 4
      (LunarMonth.bhadrapada, 14) => 'Anant Chaturdashi',   // Shukla 14

      // Ashwina
      (LunarMonth.ashwina, 1)  => 'Sharad Navratri (Day 1)',
      (LunarMonth.ashwina, 2)  => 'Sharad Navratri (Day 2)',
      (LunarMonth.ashwina, 3)  => 'Sharad Navratri (Day 3)',
      (LunarMonth.ashwina, 4)  => 'Sharad Navratri (Day 4)',
      (LunarMonth.ashwina, 5)  => 'Sharad Navratri (Day 5)',
      (LunarMonth.ashwina, 6)  => 'Sharad Navratri (Day 6)',
      (LunarMonth.ashwina, 7)  => 'Sharad Navratri (Day 7)',
      (LunarMonth.ashwina, 8)  => 'Sharad Navratri (Day 8)',
      (LunarMonth.ashwina, 9)  => 'Sharad Navratri (Day 9)',
      (LunarMonth.ashwina, 10) => 'Vijayadashami',
      (LunarMonth.ashwina, 15) => 'Sharad Purnima',

      // Kartika — Krishna paksha (tithi 16–30) and Shukla (1–15) all in same month.
      (LunarMonth.kartika, 28) => 'Dhanteras',              // Krishna 13
      (LunarMonth.kartika, 29) => 'Naraka Chaturdashi',     // Krishna 14
      (LunarMonth.kartika, 30) => 'Diwali',                 // Amavasya
      (LunarMonth.kartika, 1)  => 'Govardhan Puja',         // Shukla 1
      (LunarMonth.kartika, 2)  => 'Bhai Dooj',              // Shukla 2
      (LunarMonth.kartika, 4)  => 'Chhath — Nahay Khay',   // Shukla 4
      (LunarMonth.kartika, 5)  => 'Chhath — Kharna',       // Shukla 5
      (LunarMonth.kartika, 6)  => 'Chhath — Sandhya Arghya', // Shukla 6
      (LunarMonth.kartika, 7)  => 'Chhath — Usha Arghya',  // Shukla 7
      (LunarMonth.kartika, 11) => 'Devutthana Ekadashi',    // Shukla 11
      (LunarMonth.kartika, 15) => 'Kartik Purnima',

      // Margashirsha
      (LunarMonth.margashirsha, 11) => 'Gita Jayanti',      // Shukla 11

      // Magha
      (LunarMonth.magha, 5) => 'Vasant Panchami',           // Shukla 5

      // Phalguna
      (LunarMonth.phalguna, 29) => 'Maha Shivaratri',       // Krishna 14
      (LunarMonth.phalguna, 15) => 'Holika Dahan',

      _ => null,
    };
  }
}
