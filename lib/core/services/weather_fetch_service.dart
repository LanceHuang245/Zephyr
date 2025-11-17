import 'package:zephyr/core/services/forecast_widget_service.dart';

import '../import.dart';

class WeatherFetchService {
  static bool _isFetching = false;

  static Future<Map<String, dynamic>?> getFreshWeatherData(City city) async {
    try {
      if (kDebugMode) debugPrint('获取城市天气: ${city.name}');

      final prefs = await SharedPreferences.getInstance();

      final weather = await Api.fetchWeather(
        latitude: city.lat,
        longitude: city.lon,
        units: tempUnitNotifier.value,
      );

      List<WeatherWarning> warnings = [];
      try {
        warnings = await Api.fetchWarning(
          lat: city.lat,
          lon: city.lon,
        );
        if (warnings.isNotEmpty) {
          final title = warnings.first.title;
          final body = warnings.map((w) => w.text).join('\n');
          await NotificationService().showWarningNotification(title, body);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('获取天气预警失败: $e');
      }

      if (weather != null) {
        final timestamp = DateTime.now();
        await cacheWeather(city, weather, warnings, timestamp);
        weather.lastUpdated = timestamp;
        if (kDebugMode) debugPrint('天气数据获取并缓存成功 for ${city.name}');

        final citiesStr = prefs.getString('cities');
        if (citiesStr != null) {
          final cities = City.listFromJson(citiesStr);
          if (cities.isNotEmpty &&
              cities.first.lat == city.lat &&
              cities.first.lon == city.lon) {
            await ForecastWidgetService.updateAllWidgets(
              city: city,
              weatherData: weather,
            );
          }
        }

        return {'weather': weather, 'warnings': warnings};
      } else {
        if (kDebugMode) debugPrint('天气数据获取失败 for ${city.name}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('获取天气失败 for ${city.name}: $e');
      return null;
    }
  }

  static Future<void> fetchAndCacheWeather() async {
    if (_isFetching) {
      if (kDebugMode) debugPrint('已经在获取天气数据，跳过本次请求');
      return;
    }

    _isFetching = true;
    try {
      if (kDebugMode) debugPrint('后台任务开始获取天气数据...');

      final prefs = await SharedPreferences.getInstance();
      final citiesStr = prefs.getString('cities');
      if (citiesStr == null) {
        if (kDebugMode) debugPrint('后台任务: 没有配置城市信息');
        return;
      }

      final cities = City.listFromJson(citiesStr);
      if (cities.isEmpty) {
        if (kDebugMode) debugPrint('后台任务: 城市列表为空');
        return;
      }

      final mainCity = cities.first;
      final weatherData = await getFreshWeatherData(mainCity);

      if (weatherData != null) {
        final warnings = weatherData['warnings'] as List<WeatherWarning>? ?? [];
        if (warnings.isNotEmpty) {
          final title = warnings.first.title;
          final body = warnings.map((w) => w.text).join('\n');
          await NotificationService().showWarningNotification(title, body);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('后台任务获取天气失败: $e');
    } finally {
      _isFetching = false;
    }
  }
}
