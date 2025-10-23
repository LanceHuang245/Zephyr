import Flutter
import UIKit
import workmanager_apple

func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Enable background fetch.
    UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

    // Register the background task with the scheduler.
    WorkmanagerPlugin.registerBGTaskScheduler(withIdentifier: "org.claret.easyweather.fetchWeatherTask")

    // Set the plugin registrant callback to register plugins in the background isolate.
    WorkmanagerPlugin.setPluginRegistrantCallback(registerPlugins)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

