import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  if (kDebugMode) {
    print(
        "Handling notification tap in background: ${notificationResponse.payload}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      await Permission.notification.request();
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true);

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
          if (kDebugMode) {
            debugPrint('notification payload: ${response.payload}');
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      // TODO: iOS测试通知待删除
      await NotificationService().showWarningNotification("TEST", "TEst");
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error initializing NotificationService: $e");
      }
    }
  }

  Future<void> showWarningNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weather_warnings_channel',
      'Weather Warnings',
      channelDescription: 'Channel for weather warning notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _notificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'weather_warning',
      );
      if (kDebugMode) {
        debugPrint("Showing notification: $title");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error showing notification: $e");
      }
    }
  }
}
