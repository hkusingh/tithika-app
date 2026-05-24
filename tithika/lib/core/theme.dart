import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

class TithikaColors extends ThemeExtension<TithikaColors> {
  const TithikaColors._({
    required this.background,
    required this.panel,
    required this.card,
    required this.shukla,
    required this.shuklaGlow,
    required this.krishna,
    required this.krishnaGlow,
    required this.festival,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.moonLight,
    required this.moonDark,
    required this.line,
    required this.lineStrong,
  });

  final Color background;
  final Color panel;
  final Color card;
  final Color shukla;
  final Color shuklaGlow;
  final Color krishna;
  final Color krishnaGlow;
  final Color festival;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color moonLight;
  final Color moonDark;
  final Color line;
  final Color lineStrong;

  static const dark = TithikaColors._(
    background:  Color(0xFF0B0F1E),
    panel:       Color(0xFF11132A),
    card:        Color(0x0AFFFFFF),
    shukla:      Color(0xFFE6B85C),
    shuklaGlow:  Color(0x40E6B85C),
    krishna:     Color(0xFF7D8DF0),
    krishnaGlow: Color(0x2E7D8DF0),
    festival:    Color(0xFFFF8C42),
    ink:         Color(0xFFF3EEDF),
    inkSoft:     Color(0xFFAAB0C5),
    inkMuted:    Color(0xFF6C7290),
    moonLight:   Color(0xFFF7F2DC),
    moonDark:    Color(0xFF1C2147),
    line:        Color(0x14FFFFFF),
    lineStrong:  Color(0x26FFFFFF),
  );

  static const light = TithikaColors._(
    background:  Color(0xFFF5F0E8),
    panel:       Color(0xFFEDE8D8),
    card:        Color(0x0A000000),
    shukla:      Color(0xFFC8922A),
    shuklaGlow:  Color(0x33C8922A),
    krishna:     Color(0xFF5A6BD8),
    krishnaGlow: Color(0x2E5A6BD8),
    festival:    Color(0xFFD46A1E),
    ink:         Color(0xFF1A1F3C),
    inkSoft:     Color(0xFF4A5070),
    inkMuted:    Color(0xFF8890A8),
    moonLight:   Color(0xFFF7F2DC),
    moonDark:    Color(0xFF1C2147),
    line:        Color(0x14000000),
    lineStrong:  Color(0x26000000),
  );

  /// Shorthand for `Theme.of(context).extension<TithikaColors>()!`.
  static TithikaColors of(BuildContext context) =>
      Theme.of(context).extension<TithikaColors>()!;

  @override
  TithikaColors copyWith({
    Color? background, Color? panel, Color? card,
    Color? shukla, Color? shuklaGlow,
    Color? krishna, Color? krishnaGlow,
    Color? festival,
    Color? ink, Color? inkSoft, Color? inkMuted,
    Color? moonLight, Color? moonDark,
    Color? line, Color? lineStrong,
  }) => TithikaColors._(
    background:  background  ?? this.background,
    panel:       panel       ?? this.panel,
    card:        card        ?? this.card,
    shukla:      shukla      ?? this.shukla,
    shuklaGlow:  shuklaGlow  ?? this.shuklaGlow,
    krishna:     krishna     ?? this.krishna,
    krishnaGlow: krishnaGlow ?? this.krishnaGlow,
    festival:    festival    ?? this.festival,
    ink:         ink         ?? this.ink,
    inkSoft:     inkSoft     ?? this.inkSoft,
    inkMuted:    inkMuted    ?? this.inkMuted,
    moonLight:   moonLight   ?? this.moonLight,
    moonDark:    moonDark    ?? this.moonDark,
    line:        line        ?? this.line,
    lineStrong:  lineStrong  ?? this.lineStrong,
  );

  @override
  TithikaColors lerp(TithikaColors other, double t) => TithikaColors._(
    background:  Color.lerp(background,  other.background,  t)!,
    panel:       Color.lerp(panel,       other.panel,       t)!,
    card:        Color.lerp(card,        other.card,        t)!,
    shukla:      Color.lerp(shukla,      other.shukla,      t)!,
    shuklaGlow:  Color.lerp(shuklaGlow,  other.shuklaGlow,  t)!,
    krishna:     Color.lerp(krishna,     other.krishna,     t)!,
    krishnaGlow: Color.lerp(krishnaGlow, other.krishnaGlow, t)!,
    festival:    Color.lerp(festival,    other.festival,    t)!,
    ink:         Color.lerp(ink,         other.ink,         t)!,
    inkSoft:     Color.lerp(inkSoft,     other.inkSoft,     t)!,
    inkMuted:    Color.lerp(inkMuted,    other.inkMuted,    t)!,
    moonLight:   Color.lerp(moonLight,   other.moonLight,   t)!,
    moonDark:    Color.lerp(moonDark,    other.moonDark,    t)!,
    line:        Color.lerp(line,        other.line,        t)!,
    lineStrong:  Color.lerp(lineStrong,  other.lineStrong,  t)!,
  );
}

// ── Script text style helpers ─────────────────────────────────────────────────

TextStyle devanagariStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansDevanagari',
    fontFamilyFallback: const ['Kohinoor Devanagari', 'Devanagari Sangam MN'],
    color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: 0,
  );
}

TextStyle tamilStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansTamil',
    fontFamilyFallback: const ['Tamil MN', 'Tamil Sangam MN'],
    color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: 0,
  );
}

TextStyle bengaliStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansBengali',
    fontFamilyFallback: const ['Bangla MN', 'Bangla Sangam MN'],
    color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: 0,
  );
}

TextStyle scriptStyle(AppLanguage lang, TextStyle? base,
    {Color? color, double? fontSize, FontWeight? fontWeight}) =>
    switch (lang) {
      AppLanguage.hindiDevanagari => devanagariStyle(base, color: color, fontSize: fontSize, fontWeight: fontWeight),
      AppLanguage.tamil           => tamilStyle(base, color: color, fontSize: fontSize, fontWeight: fontWeight),
      AppLanguage.bengali         => bengaliStyle(base, color: color, fontSize: fontSize, fontWeight: fontWeight),
      _                           => (base ?? const TextStyle()).copyWith(color: color, fontSize: fontSize, fontWeight: fontWeight),
    };

// ── Theme builder ─────────────────────────────────────────────────────────────

ThemeData buildTithikaTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark ? TithikaColors.dark : TithikaColors.light;
  final base   = brightness == Brightness.dark ? ThemeData.dark()   : ThemeData.light();

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(color: colors.ink, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 38),
    titleLarge:   GoogleFonts.inter(color: colors.ink, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.01 * 19),
    bodyMedium:   GoogleFonts.inter(color: colors.ink, fontSize: 13),
    bodySmall:    GoogleFonts.inter(color: colors.inkSoft, fontSize: 12),
    labelSmall:   GoogleFonts.inter(color: colors.inkMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.05 * 10),
  );

  return base.copyWith(
    extensions: [colors],
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary:     colors.shukla,
      secondary:   colors.krishna,
      surface:     colors.panel,
      onPrimary:   brightness == Brightness.dark ? const Color(0xFF1C1300) : Colors.white,
      onSecondary: colors.ink,
      onSurface:   colors.ink,
      error:       const Color(0xFFCF6679),
      onError:     Colors.white,
    ),
    textTheme: textTheme,
    dividerColor: colors.line,
    cardColor:    colors.card,
  );
}
