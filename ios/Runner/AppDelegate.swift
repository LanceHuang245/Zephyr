import UIKit
import Flutter
import workmanager_apple
import flutter_local_notifications
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
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
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        // WorkManager setup
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        // 设置后台任务最小刷新间隔
        if #available(iOS 13.0, *) {
            UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(15 * 60)) // 15分钟最小间隔
        }

        WorkmanagerPlugin.registerPeriodicTask(
            withIdentifier: "org.claret.easyweather.fetchWeatherTask",
            frequency: NSNumber(value: 30 * 60) // 30 分钟（iOS实际执行时间由系统决定）
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

