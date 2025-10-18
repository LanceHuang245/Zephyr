import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

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
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'weather_warnings_channel',
        'Weather Warnings',
        description: 'Channel for weather warning notifications.',
        importance: Importance.max,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      final prefs = await SharedPreferences.getInstance();
      final hasRequested =
          prefs.getBool('has_requested_notification_permission') ?? false;

      if (!hasRequested) {
        await manuallyRequestPermissions();
        await prefs.setBool('has_requested_notification_permission', true);
      }

      if (kDebugMode) {
        debugPrint("NotificationService initialized.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error initializing NotificationService: $e");
      }
    }
  }

  Future<void> manuallyRequestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> showWarningNotification(String title, String body) async {
    if (await Permission.notification.isGranted) {
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
    } else {
      if (kDebugMode) {
        debugPrint(
            "Notification permission not granted. Skipping notification.");
      }
    }
  }
}
