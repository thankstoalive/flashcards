import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/flashcard.dart';

/// NotificationService implementation for supported platforms (mobile, desktop)
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize plugin and timezone data
  Future<void> init() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// Schedule a daily reminder at [hour]:[minute]
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await flutterLocalNotificationsPlugin.cancel(0);
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: '매일 복습 대상 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '복습 알림',
      await _composeBody(),
      scheduledDate,
      platformDetails,
      // Android 12+ requires exact alarm permission for exact scheduling.
      // Use inexactAllowWhileIdle to avoid requiring the permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_reminder',
      'Test Reminder',
      channelDescription: '테스트 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      1,
      '테스트 알림',
      await _composeBody(),
      platformDetails,
    );
  }

  Future<String> _composeBody() async {
    final box = Hive.box<Flashcard>('flashcards');
    final dueCount = box.values.where((c) => !c.due.isAfter(DateTime.now())).length;
    return '오늘 복습할 카드가 $dueCount장 있습니다!';
  }
}