import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zephyr/core/services/notification_service.dart';
import 'package:zephyr/core/services/weather_fetch_service.dart';
import 'notifiers.dart';
import 'package:flutter/material.dart';
import 'languages.dart';

// 运行后台自动获取天气数据任务
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await NotificationService().init();

    switch (task) {
      case "fetchWeatherTask":
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

  final systemLocale = PlatformDispatcher.instance.locale;
  if (kDebugMode) {
    debugPrint('systemLocale: $systemLocale');
  }

  if (prefs.containsKey('locale_code')) {
    // 用户已手动设置过语言
    localeCodeNotifier.value = prefs.getString('locale_code') ?? 'en';
  } else {
    // 根据系统语言自动设置默认语言
    final localeString = systemLocale.toString();
    final languageCode = systemLocale.languageCode;

    // 优先使用完整locale字符串匹配，然后回退到语言代码匹配
    final matched = appLanguages.firstWhere(
      (l) => l.code == localeString || l.code == languageCode,
      orElse: () => appLanguages.firstWhere((l) => l.code == 'en'),
    );
    localeCodeNotifier.value = matched.code;
  }

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
    "1",
    "fetchWeatherTask",
    frequency: const Duration(minutes: 30),
  );
}
