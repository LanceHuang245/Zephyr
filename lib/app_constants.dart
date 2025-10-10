import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Zephyr';
  static const String appVersion = 'v2.2.0';
  static const String appDescription =
      'Simple and fast real-time weather forecast software.';
  static const String appUrl = 'https://github.com/LanceHuang245/Zephyr';

  static const List<String> weatherSources = [
    'OpenMeteo',
    'QWeather',
  ];

  // OpenMeteo API Url 用于获取天气数据
  // static const String omForecastUrl = 'https://api.open-meteo.com/v1/forecast';
  // static const String omAirQualityUrl =
  // 'https://air-quality-api.open-meteo.com/v1/air-quality';
}

// API url (Lance免费特供，有一定用量限制，请勿滥用或攻击该服务器)
String weatherUrl = dotenv.env['WEATHER_URL'] ?? '';

// Forecast API Url 用于获取天气数据
String forecastUrl = '$weatherUrl/weather/forecast';

// Alerts API Url 用于获取全球天气预警
String alertUrl = '$weatherUrl/weather/alert';

// City Search API Url 用于城市搜索
String searchUrl = '$weatherUrl/city/search';
