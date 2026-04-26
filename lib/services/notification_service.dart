// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/warranty.dart';
import '../models/vehicle.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleAllNotifications() async {
    await _plugin.cancelAll();

    final db = DatabaseService();
    final alertDays = await db.getAlertDays();
    final warranties = await db.getWarranties();
    final vehicles = await db.getVehicles();

    int notifId = 0;

    for (final w in warranties) {
      if (w.daysRemaining >= 0 && w.daysRemaining <= alertDays) {
        await _scheduleNow(
          id: notifId++,
          title: '⚠️ Гаранция изтича скоро',
          body: '${w.title} изтича след ${w.daysRemaining} дни',
        );
      }

      // Schedule notification on expiry day
      if (w.daysRemaining >= 0) {
        await _scheduleOnDate(
          id: notifId++,
          title: '🔴 Гаранция изтича днес!',
          body: '${w.title} — гаранцията изтича днес',
          date: w.expiryDate,
        );
      }

      // Schedule notification X days before
      final alertDate =
          w.expiryDate.subtract(Duration(days: alertDays));
      if (alertDate.isAfter(DateTime.now())) {
        await _scheduleOnDate(
          id: notifId++,
          title: '⚠️ Гаранция изтича след $alertDays дни',
          body: '${w.title} изтича на ${_formatDate(w.expiryDate)}',
          date: alertDate,
        );
      }
    }

    for (final v in vehicles) {
      for (final doc in v.documents) {
        if (doc.validTo == null) continue;

        if (doc.daysRemaining >= 0 && doc.daysRemaining <= alertDays) {
          await _scheduleNow(
            id: notifId++,
            title: '⚠️ ${v.name} — ${doc.type} изтича',
            body: '${doc.type} изтича след ${doc.daysRemaining} дни',
          );
        }

        if (doc.daysRemaining >= 0) {
          await _scheduleOnDate(
            id: notifId++,
            title: '🔴 ${v.name} — ${doc.type} изтича днес!',
            body: '${doc.type} за ${v.licensePlate} изтича днес',
            date: doc.validTo!,
          );
        }

        final alertDate =
            doc.validTo!.subtract(Duration(days: alertDays));
        if (alertDate.isAfter(DateTime.now())) {
          await _scheduleOnDate(
            id: notifId++,
            title: '⚠️ ${v.name} — ${doc.type} изтича след $alertDays дни',
            body: '${doc.type} изтича на ${_formatDate(doc.validTo!)}',
            date: alertDate,
          );
        }
      }
    }
  }

  Future<void> _scheduleNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mygarage_channel',
          'MyGarage Известия',
          channelDescription: 'Известия за изтичащи документи',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _scheduleOnDate({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final scheduledDate = tz.TZDateTime.from(date, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mygarage_channel',
          'MyGarage Известия',
          channelDescription: 'Известия за изтичащи документи',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
