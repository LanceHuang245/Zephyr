import '../import.dart';
import 'dart:math' as math;

class ForecastWidgetService {
  static const String _forecastWidgetDataKey = 'flutter.forecast_widget_data';

  // 更新7日预报小部件数据
  static Future<void> updateForecastWidget({
    required City city,
    WeatherData? weatherData,
  }) async {
    try {
      if (weatherData == null) {
        final cached = await loadCachedWeather(city);
        weatherData = cached?['weather'] as WeatherData?;
        if (weatherData == null || weatherData.daily.isEmpty) {
          await _showNoForecastDataWidget(city);
          return;
        }
      }

      if (weatherData.daily.isEmpty) {
        await _showNoForecastDataWidget(city);
        return;
      }

      final daily = weatherData.daily;
      final forecastData = <Map<String, dynamic>>[];

      // 获取当前语言设置
      final lang = localeCodeNotifier.value;

      // 处理7日预报数据
      final maxDays = math.min(7, daily.length);
      for (int i = 0; i < maxDays; i++) {
        final dayWeather = daily[i];
        final dateStr = dayWeather.date;
        final weatherCode = dayWeather.weatherCode ?? 0;
        final weatherDesc = getWeatherDescForWidget(weatherCode, lang);

        // API返回的温度已经是根据用户设置转换过的
        final tempMax = dayWeather.tempMax != null
            ? '${dayWeather.tempMax!.round()}°'
            : '--°';
        final tempMin = dayWeather.tempMin != null
            ? '${dayWeather.tempMin!.round()}°'
            : '--°';

        forecastData.add({
          'date': dateStr,
          'weather_code': weatherCode,
          'weather_desc': weatherDesc,
          'temp_max': tempMax,
          'temp_min': tempMin,
        });
      }

      // 准备小部件数据
      final widgetData = {
        'city_name': city.name,
        'forecast_data': forecastData,
        'temp_unit': tempUnitNotifier.value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(widgetData);
      await prefs.setString(_forecastWidgetDataKey, jsonData);

      try {
        // 使用HomeWidget保存数据
        await HomeWidget.saveWidgetData(
            'forecast_city_name', widgetData['city_name']);
        await HomeWidget.saveWidgetData(
            'forecast_data', jsonEncode(forecastData));
        await HomeWidget.saveWidgetData(
            'forecast_temp_unit', widgetData['temp_unit']);
        await HomeWidget.saveWidgetData(
            'forecast_timestamp', widgetData['timestamp']);

        // 更新小部件
        await HomeWidget.updateWidget(
          androidName: 'ForecastWidgetProvider',
          // iOSName: 'ForecastWidget',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HomeWidget forecast update failed: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating forecast widget: $e');
      }
    }
  }

  
  // 显示无数据时的7日预报小部件
  static Future<void> _showNoForecastDataWidget(City city) async {
    try {
      final cityName = city.name;
      final forecastData = <Map<String, dynamic>>[];

      // 生成7天的默认数据
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        forecastData.add({
          'date': dateStr,
          'weather_code': 0,
          'weather_desc': '--',
          'temp_max': '--°',
          'temp_min': '--°',
        });
      }

      // 获取当前温度单位设置
      final tempUnit = tempUnitNotifier.value;

      final widgetData = {
        'city_name': cityName,
        'forecast_data': forecastData,
        'temp_unit': tempUnit,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(widgetData);
      await prefs.setString(_forecastWidgetDataKey, jsonData);

      try {
        await HomeWidget.saveWidgetData(
            'forecast_city_name', widgetData['city_name']);
        await HomeWidget.saveWidgetData(
            'forecast_data', jsonEncode(forecastData));
        await HomeWidget.saveWidgetData(
            'forecast_temp_unit', widgetData['temp_unit']);
        await HomeWidget.saveWidgetData(
            'forecast_timestamp', widgetData['timestamp']);

        await HomeWidget.updateWidget(
          androidName: 'ForecastWidgetProvider',
          // iOSName: 'ForecastWidget',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HomeWidget forecast update failed: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing no forecast data widget: $e');
      }
    }
  }

  // 批量更新所有小部件（当前天气 + 7日预报）
  static Future<void> updateAllWidgets({
    required City city,
    WeatherData? weatherData,
  }) async {
    try {
      // 并行更新两个小部件
      await Future.wait([
        WidgetService.updateWidget(city: city, weatherData: weatherData),
        updateForecastWidget(city: city, weatherData: weatherData),
      ]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating all widgets: $e');
      }
    }
  }
}
