import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../models/lunar_month.dart';
import '../models/paksha.dart';
import 'festival_detector.dart';
import 'tithi_service.dart';

const _channelDaily = 'tithika_daily';
const _channelEvents = 'tithika_events';

const _dailyDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelDaily,
    'Daily Panchanga',
    channelDescription: 'Daily Hindu calendar reminder',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  iOS: DarwinNotificationDetails(),
);

const _eventDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelEvents,
    'Festivals & Observances',
    channelDescription: 'Hindu festival and observance alerts',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  iOS: DarwinNotificationDetails(),
);

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

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
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> scheduleAll({
    required NotificationSettings settings,
    required AppSettings appSettings,
    required TithiService tithiService,
  }) async {
    await cancelAll();
    if (!settings.enabled) return;

    final effectiveLoc = appSettings.location ?? AppLocation.ujjain;
    final tzId =
        effectiveLoc.tzId.isNotEmpty ? effectiveLoc.tzId : 'Asia/Kolkata';
    final tzLocation = tz.getLocation(tzId);

    if (settings.dailyReminderEnabled) {
      await _scheduleDailyReminder(settings, tzLocation);
    }
    if (settings.festivalAlertsEnabled) {
      await _scheduleFestivalAlerts(effectiveLoc, tithiService, tzLocation);
    }
    if (settings.ekadashiAlertsEnabled) {
      await _scheduleEkadashiAlerts(effectiveLoc, tithiService, tzLocation);
    }
  }

  static Future<void> _scheduleDailyReminder(
    NotificationSettings settings,
    tz.Location location,
  ) async {
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      settings.dailyReminderHour,
      settings.dailyReminderMinute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      0,
      'Tithika Panchanga',
      'Tap to see today\'s tithi, nakshatra, and more',
      scheduled,
      _dailyDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _scheduleFestivalAlerts(
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    final now = tz.TZDateTime.now(tzLocation);
    var notifId = 1;

    for (final year in [now.year, now.year + 1]) {
      if (notifId > 200) break;
      for (var month = 1; month <= 12; month++) {
        if (notifId > 200) break;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        for (var day = 1; day <= daysInMonth; day++) {
          if (notifId > 200) break;
          final date = DateTime(year, month, day);
          final scheduleTime =
              tz.TZDateTime(tzLocation, year, month, day, 8, 0);
          if (scheduleTime.isBefore(now)) continue;

          final raw = tithiService.calculateForDate(
            localDate: date,
            lat: location.lat,
            lon: location.lon,
            tzOffset: location.tzOffsetAt(date),
          );
          final festivalName = FestivalDetector.detect(_purnimanta(raw));
          if (festivalName == null) continue;

          await _plugin.zonedSchedule(
            notifId++,
            festivalName,
            'Wishing you a blessed celebration!',
            scheduleTime,
            _eventDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  static Future<void> _scheduleEkadashiAlerts(
    AppLocation location,
    TithiService tithiService,
    tz.Location tzLocation,
  ) async {
    final now = tz.TZDateTime.now(tzLocation);
    var notifId = 201;
    var found = 0;

    for (var i = 0; i < 60 && found < 30; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final raw = tithiService.calculateForDate(
        localDate: date,
        lat: location.lat,
        lon: location.lon,
        tzOffset: location.tzOffsetAt(date),
      );
      if (raw.tithi.number != 11) continue;

      final scheduleTime =
          tz.TZDateTime(tzLocation, date.year, date.month, date.day, 6, 0);
      if (scheduleTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        notifId++,
        'Ekadashi Today',
        'An auspicious day for fasting and devotion',
        scheduleTime,
        _eventDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      found++;
    }
  }
}

DayData _purnimanta(DayData raw) {
  if (raw.isAdhika || raw.tithi.paksha != Paksha.krishna) return raw;
  return raw.copyWith(
      lunarMonth: LunarMonth.values[(raw.lunarMonth.index + 1) % 12]);
}
