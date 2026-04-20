import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/utils/formatters.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Channel IDs
  static const String _dueDateChannelId = 'utangku_due_date';
  static const String _overdueChannelId = 'utangku_overdue';

  /// Initialize notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — can be extended to navigate to specific debt
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permission (iOS)
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }

    return false;
  }

  /// Check if notifications are enabled
  Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return true; // Android defaults to enabled unless revoked
  }

  /// Schedule a due-date reminder notification
  Future<void> scheduleDueDateReminder(DebtModel debt) async {
    if (debt.dueDate == null || debt.status.value == 'LUNAS') return;
    if (!_isInitialized) await init();

    final scheduledDate = _getReminderDate(debt.dueDate!, 1); // 1 day before
    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId = debt.id ?? debt.hashCode;

    const androidDetails = AndroidNotificationDetails(
      _dueDateChannelId,
      'Jatuh Tempo',
      channelDescription: 'Pengingat jatuh tempo utang/piutang',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Pengingat Jatuh Tempo',
      'Utang/piutang "${debt.name}" jatuh tempo besok!\n${CurrencyFormatter.format(debt.amount)}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'due_date_${debt.id}',
    );
  }

  /// Schedule an overdue notification (for debts past due date)
  Future<void> scheduleOverdueNotification(DebtModel debt) async {
    if (debt.dueDate == null || debt.status.value == 'LUNAS') return;
    if (debt.dueDate!.isAfter(DateTime.now())) return; // Not overdue yet
    if (!_isInitialized) await init();

    final notificationId = (debt.id ?? debt.hashCode) + 100000; // Offset to avoid clash

    const androidDetails = AndroidNotificationDetails(
      _overdueChannelId,
      'Lewat Jatuh Tempo',
      channelDescription: 'Pemberitahuan utang/piutang yang lewat jatuh tempo',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show immediately
    await _notifications.show(
      notificationId,
      'Lewat Jatuh Tempo!',
      'Utang/piutang "${debt.name}" sudah lewat jatuh tempo!\n${CurrencyFormatter.format(debt.amount)}',
      details,
      payload: 'overdue_${debt.id}',
    );
  }

  /// Schedule notifications for all unpaid debts
  Future<void> scheduleAllReminders(List<DebtModel> debts) async {
    await cancelAllNotifications();

    for (final debt in debts) {
      if (debt.status.value == 'BELUM_LUNAS' && debt.dueDate != null) {
        if (debt.isOverdue) {
          await scheduleOverdueNotification(debt);
        } else {
          await scheduleDueDateReminder(debt);
        }
      }
    }
  }

  /// Cancel notification for a specific debt
  Future<void> cancelReminder(int debtId) async {
    await _notifications.cancel(debtId);
    await _notifications.cancel(debtId + 100000); // overdue offset
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get reminder date (N days before due date at 9:00 AM)
  DateTime _getReminderDate(DateTime dueDate, int daysBefore) {
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - daysBefore,
      9, // 9:00 AM
      0,
    );
  }
}
