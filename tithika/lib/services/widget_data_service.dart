import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_strings.dart';
import '../core/time_format.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../models/lunar_month.dart';
import '../models/muhurta_data.dart';
import '../models/paksha.dart';

/// Writes today's tithi/nakshatra/Rahu data to Android SharedPreferences and
/// triggers a Glance widget refresh. No-op on iOS (WidgetKit is native-only).
class WidgetDataService {
  static Future<void> update({
    required DayData dayData,
    MuhurtaData? muhurta,
    required AppSettings settings,
    required Duration tzOffset,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _write(
        dayData: dayData,
        muhurta: muhurta,
        settings: settings,
        tzOffset: tzOffset,
      );
    } catch (_) {
      // Widget update is non-critical; never crash the app.
    }
  }

  // ── internals ────────────────────────────────────────────────────────────────

  static Future<void> _write({
    required DayData dayData,
    MuhurtaData? muhurta,
    required AppSettings settings,
    required Duration tzOffset,
  }) async {
    final lang = settings.language;
    final tithi = dayData.tithi;
    final nakshatra = dayData.nakshatra;
    final sunrise = dayData.sunriseUtc;
    final sunset = dayData.sunsetUtc;
    final now = DateTime.now().toUtc();
    final isShukla = tithi.paksha == Paksha.shukla;

    // ── Localised strings ────────────────────────────────────────────────────
    final tithiName = _tithiName(tithi, lang);
    final lunarMonthLabel = _lunarMonthLabel(dayData, lang);
    final nakshatraName = _nakshatraName(nakshatra, lang);
    final nakshatraUntil = 'until ${formatLocalTime(nakshatra.end, tzOffset)}';
    final sunriseTime =
        sunrise != null ? formatLocalTime(sunrise, tzOffset) : '—';

    // ── Rahu bar percentages (0–100). -1 = outside the daylight window. ──────
    double rahuOffsetPct = 0;
    double rahuWidthPct = 12.5;
    double nowPct = -1;
    bool rahuActive = false;
    String rahuLabel = '';
    String rahuEndTime = '';

    final rahu = muhurta?.rahuKaal;
    if (rahu != null && sunrise != null && sunset != null) {
      rahuLabel =
          '${formatLocalTime(rahu.start, tzOffset)} – ${formatLocalTime(rahu.end, tzOffset)}';
      rahuEndTime = formatLocalTime(rahu.end, tzOffset);
      final dayMs = sunset.difference(sunrise).inMilliseconds.toDouble();
      if (dayMs > 0) {
        rahuOffsetPct =
            rahu.start.difference(sunrise).inMilliseconds / dayMs * 100;
        rahuWidthPct =
            rahu.end.difference(rahu.start).inMilliseconds / dayMs * 100;
        nowPct = now.difference(sunrise).inMilliseconds / dayMs * 100;
        rahuActive = now.isAfter(rahu.start) && now.isBefore(rahu.end);
      }
    }

    // ── Moon bitmaps (both variants rendered once; widget picks by theme) ────
    final moonDarkPath = await _renderMoon(tithi.number, isDark: true);
    final moonLightPath = await _renderMoon(tithi.number, isDark: false);

    // ── Write to SharedPreferences via home_widget ────────────────────────────
    await Future.wait([
      HomeWidget.saveWidgetData<String>('tithiName', tithiName),
      HomeWidget.saveWidgetData<bool>('isShukla', isShukla),
      HomeWidget.saveWidgetData<String>('lunarMonthLabel', lunarMonthLabel),
      HomeWidget.saveWidgetData<String>(
          'festivalName', dayData.festivalName ?? ''),
      HomeWidget.saveWidgetData<String>('nakshatraName', nakshatraName),
      HomeWidget.saveWidgetData<String>('nakshatraUntil', nakshatraUntil),
      HomeWidget.saveWidgetData<String>('sunriseTime', sunriseTime),
      HomeWidget.saveWidgetData<double>('rahuOffsetPct', rahuOffsetPct),
      HomeWidget.saveWidgetData<double>('rahuWidthPct', rahuWidthPct),
      HomeWidget.saveWidgetData<double>('nowPct', nowPct),
      HomeWidget.saveWidgetData<bool>('rahuActive', rahuActive),
      HomeWidget.saveWidgetData<String>('rahuLabel', rahuLabel),
      HomeWidget.saveWidgetData<String>('rahuEndTime', rahuEndTime),
      HomeWidget.saveWidgetData<String>('moonDarkPath', moonDarkPath),
      HomeWidget.saveWidgetData<String>('moonLightPath', moonLightPath),
    ]);

    await Future.wait([
      HomeWidget.updateWidget(androidName: 'TithikaWidgetReceiver'),
      HomeWidget.updateWidget(androidName: 'SmallTithikaWidgetReceiver'),
    ]);
  }

  // ── Moon bitmap renderer ─────────────────────────────────────────────────────

  static Future<String> _renderMoon(int tithiNumber,
      {required bool isDark}) async {
    const sz = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Dark side of the moon (background disk).
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2,
      Paint()..color = const Color(0xFF1C2147),
    );

    // Lit portion — same terminator-ellipse algorithm as MoonPhaseWidget.
    _paintMoonPhase(
      canvas,
      tithiNumber,
      sz,
      Paint()
        ..color = const Color(0xFFF7F2DC)
        ..style = PaintingStyle.fill,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(sz.toInt(), sz.toInt());
    final bytes =
        (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();

    final dir = await getApplicationSupportDirectory();
    final file =
        File('${dir.path}/moon_widget_${isDark ? 'dark' : 'light'}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static void _paintMoonPhase(
      Canvas canvas, int tithiNumber, double sz, Paint litPaint) {
    final cx = sz / 2, cy = sz / 2, r = sz / 2;
    final elongRad = (tithiNumber - 0.5) * 12.0 * pi / 180.0;
    final factor = cos(elongRad);

    if (tithiNumber <= 15) {
      _drawPhase(canvas, cx, cy, r, factor, litPaint);
    } else {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(-1, 1);
      canvas.translate(-cx, -cy);
      _drawPhase(canvas, cx, cy, r, factor, litPaint);
      canvas.restore();
    }
  }

  static void _drawPhase(Canvas canvas, double cx, double cy, double r,
      double factor, Paint paint) {
    final path = Path();
    final circleRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    path.moveTo(cx, cy - r);
    path.arcTo(circleRect, -pi / 2, pi, false);

    if (factor.abs() < 0.02) {
      path.lineTo(cx, cy - r);
    } else if (factor > 0) {
      path.arcTo(
        Rect.fromCenter(
            center: Offset(cx, cy), width: 2 * r * factor, height: 2 * r),
        pi / 2,
        -pi,
        false,
      );
    } else {
      path.arcTo(
        Rect.fromCenter(
            center: Offset(cx, cy), width: -2 * r * factor, height: 2 * r),
        pi / 2,
        pi,
        false,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Localisation helpers ─────────────────────────────────────────────────────

  static String _tithiName(dynamic tithi, AppLanguage lang) =>
      tithi.fullName(lang) as String;

  static String _nakshatraName(dynamic nakshatra, AppLanguage lang) =>
      nakshatra.nameFor(lang) as String;

  static String _lunarMonthLabel(DayData dayData, AppLanguage lang) {
    final monthName  = dayData.lunarMonth.nameFor(lang);
    final pakshaStr  = AppStrings.paksha(dayData.tithi.paksha, lang);
    return '$monthName · $pakshaStr ${dayData.tithi.pakshaNumber}';
  }
}
