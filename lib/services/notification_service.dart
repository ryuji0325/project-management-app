import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return; // flutter_local_notifications tak support web
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    if (kIsWeb) return; // Skip di web
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel_v3', 'Reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    // MESTI ADA NAMA (id:, title:, etc)
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    // MESTI ADA 'id:'
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails('reminder_channel_v3', 'Reminders', importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true);
    // MESTI ADA NAMA
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> scheduleRecurringReminder({required int id, required String title, required String body, required DateTime startDateTime, required String repeatFrequency, required int repeatCount, required String repeatUnit, required String payload}) async {}

  void startAutoSync() {
    if (kIsWeb) return; // Skip di web
    FirebaseFirestore.instance.collectionGroup('reminders').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;

          final title = data['title'] ?? 'Reminder';
          final allDay = data['allDay'] ?? false;
          final ts = data['dateTime'];
          
          if (ts is Timestamp) {
            final scheduledDateTime = ts.toDate();
            // Cuma schedule kalau masa belum lepas
            if (scheduledDateTime.isAfter(DateTime.now())) {
               final body = allDay ? 'Reminder for today (All Day)' : 'Reminder: ${scheduledDateTime.hour.toString().padLeft(2, '0')}:${scheduledDateTime.minute.toString().padLeft(2, '0')}';
               final notificationId = change.doc.id.hashCode;
               
               scheduleReminderNotification(
                 id: notificationId,
                 title: 'Reminder: $title',
                 body: body,
                 scheduledDateTime: scheduledDateTime,
               );
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
           cancelNotification(change.doc.id.hashCode);
        }
      }
    });
  }
}