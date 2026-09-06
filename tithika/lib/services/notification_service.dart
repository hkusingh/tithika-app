import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../models/lunar_month.dart';
import '../models/paksha.dart';
import '../models/special_tithi.dart';
import 'festival_detector.dart';
import 'muhurta_service.dart';
import 'tithi_service.dart';

// v2: Android locks a channel's importance at creation and never lets the
// app change it later — these were originally created at IMPORTANCE_DEFAULT
// (silent, drawer-only, no heads-up banner). Renaming forces a fresh
// channel at IMPORTANCE_HIGH for all users; the old channels become
// orphaned (harmless — they just stop receiving new notifications).
const _channelDaily = 'tithika_daily_v2';
const _channelEvents = 'tithika_events_v2';
const _rescheduleKey = 'notif_next_reschedule';

/// Android scheduling mode used for every notification.
///
/// Deliberately inexact. Exact alarms (`exactAllowWhileIdle`) only buy
/// punctuality — a few minutes — but require a Play-Store-restricted
/// permission that is denied by default on Android 14+, and the plugin's
/// native layer *throws* when an exact mode is requested without it. Since
/// [NotificationService.scheduleAll] cancels everything before rescheduling,
/// such a throw left users with no notifications at all, silently. Inexact
/// scheduling needs no permission and cannot fail that way.
const _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

// Notification ID ranges. Festival IDs are consumed per NAME, not per day, so
// a day carrying two festivals uses two slots. The observance ranges are sized
// for the widest lookahead (7 + maxAlertDaysBefore days).
// 0–6:     daily reminders (7 days)
// 100–139: festival alerts
// 200–209: ekadashi alerts
// 300–309: purnima alerts
// 310–319: amavasya alerts
const _idFestivalFirst = 100;
const _idFestivalLast = 139;
const _idEkadashiFirst = 200;
const _idEkadashiLast = 209;
const _idPurnimaFirst = 300;
const _idPurnimaLast = 309;
const _idAmavasyaFirst = 310;
const _idAmavasyaLast = 319;

const _dailyDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelDaily,
    'Daily Panchanga',
    channelDescription: 'Daily Hindu calendar reminder',
    // IMPORTANCE_DEFAULT posts silently to the drawer with no heads-up
    // banner — confirmed via emulator testing (notification only visible
    // after manually pulling down the shade). IMPORTANCE_HIGH is required
    // for the pop-up/heads-up presentation.
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
);

const _eventDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelEvents,
    'Festivals & Observances',
    channelDescription: 'Hindu festival and observance alerts',
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
);

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _refreshTimer;

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // No exact-alarm permission request: scheduling uses [_scheduleMode]
      // (inexact), which needs none.
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Prompts the user to exempt the app from battery optimization, on
  /// Android only. Several OEMs (Samsung One UI, ColorOS/Realme, MIUI)
  /// aggressively kill background processes even when AlarmManager is used
  /// correctly, silently preventing scheduled notifications from ever
  /// posting — this is the standard, Play-Store-compliant way to ask for an
  /// exemption. No-ops on iOS and when already granted.
  static Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Schedule the next 7 days of notifications and arm the weekly 2 AM refresh timer.
  static Future<void> scheduleAll({
    required NotificationSettings settings,
    required AppSettings appSettings,
    required TithiService tithiService,
    required SharedPreferences prefs,
  }) async {
    await cancelAll();
    _cancelTimer();

    if (!settings.enabled) {
      await prefs.remove(_rescheduleKey);
      return;
    }

    final effectiveLoc = appSettings.location ?? AppLocation.ujjain;
    final tzId = effectiveLoc.tzId.isNotEmpty ? effectiveLoc.tzId : 'Asia/Kolkata';
    final tzLocation = tz.getLocation(tzId);

    if (settings.dailyReminderEnabled) {
      await _scheduleDailyReminders(settings, effectiveLoc, tithiService, tzLocation);
    }
    // Festival, Ekadashi, Purnima and Amavasya alerts share one pass — they
    // walk the same days and each day's ephemeris is only computed once.
    await _scheduleObservanceAlerts(
        settings, effectiveLoc, tithiService, tzLocation);

    final nextReschedule = _next2am(tzLocation);
    await prefs.setString(_rescheduleKey, nextReschedule.toUtc().toIso8601String());
    _startTimer(nextReschedule, settings, appSettings, tithiService, prefs);
  }

  /// Called on every app open. Reschedules if the weekly window has expired,
  /// or re-arms the in-memory timer if the process was restarted.
  static Future<void> checkAndRescheduleIfDue({
    required NotificationSettings settings,
    required AppSettings appSettings,
    required TithiService tithiService,
    required SharedPreferences prefs,
  }) async {
    if (!settings.enabled) return;

    final stored = prefs.getString(_rescheduleKey);

    if (stored == null || DateTime.now().toUtc().isAfter(DateTime.parse(stored))) {
      await scheduleAll(
        settings: settings,
        appSettings: appSettings,
        tithiService: tithiService,
        prefs: prefs,
      );
    } else if (_refreshTimer == null) {
      // Process was restarted — re-arm the timer without rescheduling
      _startTimer(
        DateTime.parse(stored),
        settings, appSettings, tithiService, prefs,
      );
    }
  }

  static void _cancelTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  static void _startTimer(
    DateTime fireAt,
    NotificationSettings settings,
    AppSettings appSettings,
    TithiService tithiService,
    SharedPreferences prefs,
  ) {
    _cancelTimer();
    final delay = fireAt.toUtc().difference(DateTime.now().toUtc());
    if (delay.isNegative) {
      Timer.run(() async {
        await scheduleAll(
          settings: settings, appSettings: appSettings,
          tithiService: tithiService, prefs: prefs,
        );
      });
      return;
    }
    _refreshTimer = Timer(delay, () async {
      await scheduleAll(
        settings: settings, appSettings: appSettings,
        tithiService: tithiService, prefs: prefs,
      );
    });
  }

  /// 2 AM in the user's timezone, exactly 7 days from today.
  static DateTime _next2am(tz.Location tzLocation) {
    final now = tz.TZDateTime.now(tzLocation);
    return tz.TZDateTime(tzLocation, now.year, now.month, now.day, 2, 0)
        .add(const Duration(days: 7));
  }

  static Future<void> _scheduleDailyReminders(
    NotificationSettings settings,
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    final now = tz.TZDateTime.now(tzLocation);

    for (var i = 0; i < 7; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final scheduled = tz.TZDateTime(
        tzLocation, date.year, date.month, date.day,
        settings.dailyReminderHour, settings.dailyReminderMinute,
      );
      if (scheduled.isBefore(now)) continue;

      final raw = tithiService.calculateForDate(
        localDate: date, lat: location.lat, lon: location.lon,
        tzOffset: location.tzOffsetAt(date),
      );
      final nextDate = date.add(const Duration(days: 1));
      final nextRaw = tithiService.calculateForDate(
        localDate: nextDate, lat: location.lat, lon: location.lon,
        tzOffset: location.tzOffsetAt(nextDate),
      );

      String body = '${raw.tithi.fullNameEn} · ${raw.nakshatra.nameEn}';

      if (raw.sunriseUtc != null && raw.sunsetUtc != null && nextRaw.sunriseUtc != null) {
        final muhurta = MuhurtaService.calculate(
          sunriseUtc: raw.sunriseUtc!,
          sunsetUtc: raw.sunsetUtc!,
          nextSunriseUtc: nextRaw.sunriseUtc!,
          weekday: date.weekday,
        );
        final rahuStart = tz.TZDateTime.from(muhurta.rahuKaal.start, tzLocation);
        final rahuEnd = tz.TZDateTime.from(muhurta.rahuKaal.end, tzLocation);
        body += ' · Rahu Kaal ${_fmtTime(rahuStart)}–${_fmtTime(rahuEnd)}';
      }

      final festivals = FestivalDetector.detectAll(_purnimanta(raw), _purnimanta(nextRaw));
      if (festivals.isNotEmpty) body += ' · ${festivals.join(', ')}';

      await _plugin.zonedSchedule(
        i,
        'Tithika Panchanga',
        body,
        scheduled,
        _dailyDetails,
        androidScheduleMode: _scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static String _fmtTime(tz.TZDateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? "AM" : "PM"}';
  }

  /// Dispatches the planned observance alerts to the OS. The decision of what
  /// to schedule lives in [planObservanceAlerts] so it can be tested without
  /// the plugin; this is a thin loop over its output.
  static Future<void> _scheduleObservanceAlerts(
    NotificationSettings settings,
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    // Each day is looked up twice — once as the event day, once as the
    // previous iteration's lookahead — so cache to halve the ephemeris work.
    final cache = <DateTime, DayData>{};

    final plan = planObservanceAlerts(
      settings: settings,
      dayData: (date) => cache.putIfAbsent(
        DateTime(date.year, date.month, date.day),
        () => tithiService.calculateForDate(
          localDate: date,
          lat: location.lat,
          lon: location.lon,
          tzOffset: location.tzOffsetAt(date),
        ),
      ),
      tzLocation: tzLocation,
      now: tz.TZDateTime.now(tzLocation),
      today: DateTime.now(),
    );

    for (final alert in plan) {
      await _plugin.zonedSchedule(
        alert.id,
        alert.title,
        alert.body,
        alert.fireTime,
        _eventDetails,
        androidScheduleMode: _scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}

/// One planned notification, fully resolved and ready to hand to the plugin.
class PlannedAlert {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime fireTime;

  const PlannedAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.fireTime,
  });

  @override
  String toString() => 'PlannedAlert($id, "$title", $fireTime)';
}

/// Resolves a local date to its [DayData]. Injected so the planner can be
/// tested without an ephemeris.
typedef DayDataLookup = DayData Function(DateTime localDate);

/// Computes every festival / Ekadashi / Purnima / Amavasya alert due in the
/// scheduling window.
///
/// Pure given [dayData], and takes [now] and [today] as parameters rather
/// than reading the clock, so it can be tested directly.
/// [NotificationService] turns the result into `zonedSchedule` calls.
List<PlannedAlert> planObservanceAlerts({
  required NotificationSettings settings,
  required DayDataLookup dayData,
  required tz.Location tzLocation,
  required tz.TZDateTime now,
  required DateTime today,
}) {
  final alerts = <PlannedAlert>[];

  final wantFestivals = !settings.noFestivalAlerts;
  final wantEkadashi = settings.ekadashiAlertsEnabled;
  final wantPurnima = settings.purnimaAlertsEnabled;
  final wantAmavasya = settings.amavasyaAlertsEnabled;
  if (!wantFestivals && !wantEkadashi && !wantPurnima && !wantAmavasya) {
    return alerts;
  }

  var festivalId = _idFestivalFirst;
  var ekadashiId = _idEkadashiFirst;
  var purnimaId = _idPurnimaFirst;
  var amavasyaId = _idAmavasyaFirst;

  // An event on day +7 must be scheduled from day +(7 - alertDaysBefore), so
  // the scan has to reach that much further out to still cover a full week.
  final lookahead = 7 + settings.alertDaysBefore;

  for (var i = 1; i <= lookahead; i++) {
    final date = today.add(Duration(days: i));
    final fireTime = _alertTime(tzLocation, date, settings);
    // Already past — the weekly reschedule will pick up later occurrences.
    if (fireTime.isBefore(now)) continue;

    final raw = dayData(date);
    final nextRaw = dayData(date.add(const Duration(days: 1)));

    final day = _purnimanta(raw);
    final nextDay = _purnimanta(nextRaw);
    final festivalNames = FestivalDetector.detectAll(day, nextDay);
    // Named festivals the user will actually be told about. A festival that
    // is not subscribed doesn't suppress the generic Purnima/Amavasya alert.
    final notifiedNames =
        festivalNames.where(settings.notifiesFor).toList(growable: false);

    if (wantFestivals) {
      for (final name in notifiedNames) {
        if (festivalId > _idFestivalLast) break;
        alerts.add(PlannedAlert(
          id: festivalId++,
          title: '$name ${_whenSuffix(settings.alertDaysBefore)}',
          body: 'Wishing you a blessed celebration!',
          fireTime: fireTime,
        ));
      }
    }

    if (wantEkadashi && ekadashiId <= _idEkadashiLast) {
      final isEkadashi = raw.tithi.special == SpecialTithi.ekadashi ||
          (raw.secondaryIsKshaya &&
              raw.secondaryTithi?.special == SpecialTithi.ekadashi);
      // Vruddhi first day: skip — the alert fires on the second day instead.
      // The tomorrow-lookahead is more robust than `secondaryTithi == null`
      // alone, which misses an Ekadashi ending just before the next sunrise.
      final isVruddhiFirstDay = raw.tithi.special == SpecialTithi.ekadashi &&
          nextRaw.tithi.special == SpecialTithi.ekadashi;
      if (isEkadashi && !isVruddhiFirstDay) {
        alerts.add(PlannedAlert(
          id: ekadashiId++,
          title: 'Ekadashi ${_whenSuffix(settings.alertDaysBefore)}',
          body: 'An auspicious day for fasting and devotion',
          fireTime: fireTime,
        ));
      }
    }

    // A named festival on the same day is strictly more informative, so the
    // generic alert stands down — but only when that festival is subscribed.
    if (wantPurnima &&
        purnimaId <= _idPurnimaLast &&
        notifiedNames.isEmpty &&
        raw.tithi.number == 15 &&
        FestivalDetector.isObservedPurnima(day)) {
      alerts.add(PlannedAlert(
        id: purnimaId++,
        title: 'Purnima ${_whenSuffix(settings.alertDaysBefore)}',
        body: 'A day for reflection and devotion',
        fireTime: fireTime,
      ));
    }

    if (wantAmavasya &&
        amavasyaId <= _idAmavasyaLast &&
        notifiedNames.isEmpty &&
        FestivalDetector.isObservedAmavasya(day)) {
      alerts.add(PlannedAlert(
        id: amavasyaId++,
        title: 'Amavasya ${_whenSuffix(settings.alertDaysBefore)}',
        body: 'A day for remembrance and inner stillness',
        fireTime: fireTime,
      ));
    }
  }

  return alerts;
}

/// When an alert for an event on [eventDate] should fire.
///
/// Builds the event day's midnight first and subtracts whole days, rather
/// than offsetting the calendar date, so the result stays correct across DST
/// transitions.
tz.TZDateTime _alertTime(
    tz.Location tzLoc, DateTime eventDate, NotificationSettings s) {
  return tz.TZDateTime(
    tzLoc,
    eventDate.year,
    eventDate.month,
    eventDate.day,
    s.alertHour,
    s.alertMinute,
  ).subtract(Duration(days: s.alertDaysBefore));
}

/// Trailing phrase for an alert title, e.g. "Holi tomorrow".
String _whenSuffix(int daysBefore) => switch (daysBefore) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $daysBefore days',
    };

DayData _purnimanta(DayData raw) {
  if (raw.isAdhika || raw.tithi.paksha != Paksha.krishna) return raw;
  return raw.copyWith(
      lunarMonth: LunarMonth.values[(raw.lunarMonth.index + 1) % 12]);
}
