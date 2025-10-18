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

  // API url (免费提供，有一定用量限制，请勿滥用或攻击该服务器)
  static const String weatherUrl = "http://zephyr.claret.space:3899/api/v1";
}

// Forecast API Url 用于获取天气数据
String forecastUrl = '${AppConstants.weatherUrl}/weather/forecast';

// Alerts API Url 用于获取全球天气预警
String alertUrl = '${AppConstants.weatherUrl}/weather/alert';

// City Search API Url 用于城市搜索
String searchUrl = '${AppConstants.weatherUrl}/city/search';
