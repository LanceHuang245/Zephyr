import UIKit
import Flutter
import workmanager_apple
import flutter_local_notifications
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Plugin registration
        GeneratedPluginRegistrant.register(with: self)

        // Required for flutter_local_notifications to handle notification actions in the background.
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        // Set the notification center delegate.
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        // WorkManager setup
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        WorkmanagerPlugin.registerPeriodicTask(
            withIdentifier: "org.claret.easyweather.fetchWeatherTask",
            frequency: NSNumber(value: 30 * 60) // 30 分钟
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handles notification presentation when the app is in the foreground.
    override func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .badge, .sound])
    }

    // Handles the user opening notification settings from the system.
    @available(iOS 12.0, *)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.flutter_local_notifications_example/settings",
            binaryMessenger: controller.binaryMessenger)

        channel.invokeMethod("showNotificationSettings", arguments: nil)
    }
}

