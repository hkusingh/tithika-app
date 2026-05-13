/// The 12 Purnimanta lunar months, keyed by the sidereal sun sign at Purnima.
///
/// The moon is in the nakshatra that names the month at each Full Moon; the sun
/// is therefore ~180° away, i.e. one sign "behind":
///   Mesha sun → moon in Krittika/Rohini area → Vaishakha
///   Vrishabha sun → Jyeshtha … and so on.
///
/// Index = sidereal sun sign (0 = Mesha … 11 = Meena) at the Purnima that
/// ENDS the current Purnimanta month.
enum LunarMonth {
  vaishakha,    // Sun in Mesha  (sign 0) at Purnima
  jyeshtha,     // Sun in Vrishabha (1)
  ashadha,      // Sun in Mithuna  (2)
  shravana,     // Sun in Karka    (3)
  bhadrapada,   // Sun in Simha    (4)
  ashwina,      // Sun in Kanya    (5)
  kartika,      // Sun in Tula     (6)
  margashirsha, // Sun in Vrishchika (7)
  pausha,       // Sun in Dhanu    (8)
  magha,        // Sun in Makara   (9)
  phalguna,     // Sun in Kumbha   (10)
  chaitra,      // Sun in Meena    (11)
}

extension LunarMonthName on LunarMonth {
  // Array order matches enum declaration (vaishakha=0 … chaitra=11)
  String get nameEn => const [
        'Vaishakha', 'Jyeshtha', 'Ashadha', 'Shravana',
        'Bhadrapada', 'Ashwina', 'Kartika', 'Margashirsha',
        'Pausha', 'Magha', 'Phalguna', 'Chaitra',
      ][index];

  String get nameDeva => const [
        'वैशाख', 'ज्येष्ठ', 'आषाढ़', 'श्रावण',
        'भाद्रपद', 'आश्विन', 'कार्तिक', 'मार्गशीर्ष',
        'पौष', 'माघ', 'फाल्गुन', 'चैत्र',
      ][index];

  // 4-char abbreviation for the month-grid cell label.
  // ASHA=Ashadha, ASHW=Ashwina (unique pair).
  String get abbr4 => const [
        'VAIS', 'JYES', 'ASHA', 'SHRA', 'BHAD', 'ASHW',
        'KART', 'MARG', 'PAUS', 'MAGH', 'PHAL', 'CHAI',
      ][index];
}
