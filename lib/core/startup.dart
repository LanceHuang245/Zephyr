import 'import.dart';

// 运行后台自动获取天气数据任务
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService().init();
    final prefs = await SharedPreferences.getInstance();
    localeCodeNotifier.value = prefs.getString('locale_code') ?? 'en';
    switch (task) {
      case "org.claret.easyweather.fetchWeatherTask":
        await WeatherFetchService.fetchAndCacheWeather();
        break;
    }
    return Future.value(true);
  });
}

Future<void> initAppSettings() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();

  // 必要的监听器
  themeModeNotifier.value = ThemeMode.values[prefs.getInt('theme_mode') ?? 0];
  tempUnitNotifier.value = prefs.getString('temp_unit') ?? 'C';
  dynamicColorEnabledNotifier.value =
      prefs.getBool('dynamic_color_enabled') ?? false;

  String determineLocaleCode() {
    final savedLocale = prefs.getString('locale_code');
    if (savedLocale != null && savedLocale.isNotEmpty) {
      return savedLocale;
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    if (kDebugMode) {
      debugPrint('systemLocale: $systemLocale');
    }
    final localeString = systemLocale.toString();
    final languageCode = systemLocale.languageCode;

    return appLanguages
        .firstWhere(
          (l) => l.code == localeString || l.code == languageCode,
          orElse: () => appLanguages.firstWhere((l) => l.code == 'en'),
        )
        .code;
  }

  localeCodeNotifier.value = determineLocaleCode();

  if (prefs.containsKey('weather_source')) {
    weatherSourceNotifier.value =
        prefs.getString('weather_source') ?? 'OpenMeteo';
  } else {
    weatherSourceNotifier.value = 'OpenMeteo';
    prefs.setString('weather_source', 'OpenMeteo');
    kDebugMode ? debugPrint('默认天气源设置为OpenMeteo') : null;
  }
  await Workmanager().initialize(
    callbackDispatcher,
  );

  Workmanager().registerPeriodicTask(
    "org.claret.easyweather.fetchWeatherTask",
    "org.claret.easyweather.fetchWeatherTask",
    frequency: const Duration(minutes: 30),
  );
}
