class AppConstants {
  static const String appName = 'Zephyr';
  static const String appVersion = 'v2.1.2';
  static const String appDescription =
      'Simple and fast real-time weather forecast software.';
  static const String appUrl = 'https://github.com/LanceHuang245/Zephyr';

  static const List<String> weatherSources = [
    'OpenMeteo',
    // 'QWeather',
  ];

  // OpenMeteo API Url 用于获取天气数据
  static const String omForecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String omAirQualityUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  // API url (Lance免费特供，有一定用量限制，请勿滥用或攻击该服务器)
  static const String weatherUrl = 'http://192.168.6.120:3899/api/v1';

  // Alerts API Url 用于获取全球天气预警
  static const String alertUrl = '$weatherUrl/weather/alert';

  // City Search API Url 用于城市搜索
  static const String searchUrl = '$weatherUrl/city/search';
}
