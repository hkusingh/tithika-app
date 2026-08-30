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

// Notification ID ranges:
// 0–6:     daily reminders (7 days)
// 100–119: festival alerts
// 200–201: ekadashi alerts

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
    if (settings.festivalAlertsEnabled) {
      await _scheduleFestivalAlerts(effectiveLoc, tithiService, tzLocation);
    }
    if (settings.ekadashiAlertsEnabled) {
      await _scheduleEkadashiAlerts(effectiveLoc, tithiService, tzLocation);
    }

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

  static Future<void> _scheduleFestivalAlerts(
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    final now = tz.TZDateTime.now(tzLocation);
    var notifId = 100;

    for (var i = 1; i <= 7; i++) {
      if (notifId > 119) break;
      final date = DateTime.now().add(Duration(days: i));
      final scheduleTime =
          tz.TZDateTime(tzLocation, date.year, date.month, date.day, 6, 0)
              .subtract(const Duration(days: 1));
      if (scheduleTime.isBefore(now)) continue;

      final raw = tithiService.calculateForDate(
        localDate: date, lat: location.lat, lon: location.lon,
        tzOffset: location.tzOffsetAt(date),
      );
      final nextDate = date.add(const Duration(days: 1));
      final nextRaw = tithiService.calculateForDate(
        localDate: nextDate, lat: location.lat, lon: location.lon,
        tzOffset: location.tzOffsetAt(nextDate),
      );
      final festivalNames =
          FestivalDetector.detectAll(_purnimanta(raw), _purnimanta(nextRaw));

      for (final festivalName in festivalNames) {
        if (notifId > 119) break;
        await _plugin.zonedSchedule(
          notifId++,
          '$festivalName tomorrow',
          'Wishing you a blessed celebration!',
          scheduleTime,
          _eventDetails,
          androidScheduleMode: _scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> _scheduleEkadashiAlerts(
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    final now = tz.TZDateTime.now(tzLocation);
    var notifId = 200;

    for (var i = 1; i <= 7 && notifId <= 201; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final raw = tithiService.calculateForDate(
        localDate: date, lat: location.lat, lon: location.lon,
        tzOffset: location.tzOffsetAt(date),
      );
      final isEkadashi = raw.tithi.special == SpecialTithi.ekadashi ||
          (raw.secondaryIsKshaya &&
           raw.secondaryTithi?.special == SpecialTithi.ekadashi);
      // Vruddhi first day: skip — the named festival alert fires the next day
      final isVruddhiFirstDay =
          raw.tithi.special == SpecialTithi.ekadashi && raw.secondaryTithi == null;
      if (!isEkadashi || isVruddhiFirstDay) continue;

      final scheduleTime =
          tz.TZDateTime(tzLocation, date.year, date.month, date.day, 6, 0)
              .subtract(const Duration(days: 1));
      if (scheduleTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        notifId++,
        'Ekadashi Tomorrow',
        'An auspicious day for fasting and devotion',
        scheduleTime,
        _eventDetails,
        androidScheduleMode: _scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}

DayData _purnimanta(DayData raw) {
  if (raw.isAdhika || raw.tithi.paksha != Paksha.krishna) return raw;
  return raw.copyWith(
      lunarMonth: LunarMonth.values[(raw.lunarMonth.index + 1) % 12]);
}
