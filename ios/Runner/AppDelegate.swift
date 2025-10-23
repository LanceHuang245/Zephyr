import UIKit
import Flutter
import workmanager_apple

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }

        WorkmanagerPlugin.registerPeriodicTask(
            withIdentifier: "org.claret.easyweather.fetchWeatherTask",
            frequency: NSNumber(value: 30 * 60) // 30 分钟
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

