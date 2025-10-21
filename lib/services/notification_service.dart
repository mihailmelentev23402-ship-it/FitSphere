import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Инициализация уведомлений
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);
    print('✅ NotificationService initialized');
  }

  /// 📲 Мгновенное уведомление (для проверки)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'main_channel', // ID канала
      'Main Notifications', // Имя канала
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0, // ID уведомления
      title,
      body,
      details,
    );

    print('📤 Мгновенное уведомление отправлено: $title');
  }

  /// ❌ Отмена всех уведомлений (по желанию)
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ Все уведомления отменены');
  }
}
