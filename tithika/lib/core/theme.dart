import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class TithikaColors {
  TithikaColors._();

  static const background = Color(0xFF0B0F1E);
  static const panel = Color(0xFF11132A);
  static const card = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  static const shukla = Color(0xFFE6B85C); // warm gold
  static const shuklaGlow = Color(0x40E6B85C);
  static const krishna = Color(0xFF7D8DF0); // lighter indigo
  static const krishnaGlow = Color(0x2E7D8DF0);
  static const festival = Color(0xFFFF8C42); // saffron-orange

  static const ink = Color(0xFFF3EEDF);
  static const inkSoft = Color(0xFFAAB0C5);
  static const inkMuted = Color(0xFF6C7290);

  static const moonLight = Color(0xFFF7F2DC);
  static const moonDark = Color(0xFF1C2147);

  static const line = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const lineStrong = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
}

// ── Devanagari text style helper ─────────────────────────────────────────────
TextStyle devanagariStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansDevanagari',
    fontFamilyFallback: const ['Kohinoor Devanagari', 'Devanagari Sangam MN'],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0,
  );
}

TextStyle tamilStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansTamil',
    fontFamilyFallback: const ['Tamil MN', 'Tamil Sangam MN'],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0,
  );
}

TextStyle bengaliStyle(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'NotoSansBengali',
    fontFamilyFallback: const ['Bangla MN', 'Bangla Sangam MN'],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0,
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

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData buildTithikaTheme() {
  final base = ThemeData.dark();
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      color: TithikaColors.ink,
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 38,
    ),
    titleLarge: GoogleFonts.inter(
      color: TithikaColors.ink,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01 * 19,
    ),
    bodyMedium: GoogleFonts.inter(
      color: TithikaColors.ink,
      fontSize: 13,
    ),
    bodySmall: GoogleFonts.inter(
      color: TithikaColors.inkSoft,
      fontSize: 12,
    ),
    labelSmall: GoogleFonts.inter(
      color: TithikaColors.inkMuted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05 * 10,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: TithikaColors.background,
    colorScheme: const ColorScheme.dark(
      primary: TithikaColors.shukla,
      secondary: TithikaColors.krishna,
      surface: TithikaColors.panel,
      onPrimary: Color(0xFF1C1300),
      onSecondary: TithikaColors.ink,
      onSurface: TithikaColors.ink,
    ),
    textTheme: textTheme,
    dividerColor: TithikaColors.line,
    cardColor: TithikaColors.card,
  );
}
