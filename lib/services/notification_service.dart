import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data.dart';

/// Schedules one notification per day for the next 30 days, each with a different garden tip.
/// The schedule is refreshed every time the app opens, and Android re-creates it after a reboot.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _baseId = 1000;
  static const int _days = 30;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  /// Asks for the Android 13+ notification permission. Returns true if allowed.
  static Future<bool> requestPermission() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ok = await impl?.requestNotificationsPermission();
    return ok ?? true;
  }

  static NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_garden_tip',
        'Daily garden tip',
        channelDescription: 'A short gardening tip every morning',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
  }

  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required List<Tip> tips,
  }) async {
    await cancelAll();
    final now = DateTime.now();
    for (var i = 0; i < _days; i++) {
      final local = DateTime(now.year, now.month, now.day + i, hour, minute);
      if (!local.isAfter(now)) continue;
      final when = tz.TZDateTime.from(local, tz.local);
      final tip = tips[tipIndexFor(local, tips.length)];
      final body = '${tip.title}. ${tip.body}';
      await _plugin.zonedSchedule(
        _baseId + i,
        '🌱 Good morning, gardener!',
        body,
        when,
        _details(body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> showTest(Tip tip) {
    final body = '${tip.title}. ${tip.body}';
    return _plugin.show(999, '🌱 Good morning, gardener!', body, _details(body));
  }
}
