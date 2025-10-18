import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "org.claret.easyweather.fetchWeatherTask",frequency: NSNumber(value: 30 * 60))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

