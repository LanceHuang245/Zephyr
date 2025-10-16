import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zephyr/core/models/city.dart';
import 'package:zephyr/core/models/weather.dart';
import '../models/weather_warning.dart';
import '../notifiers.dart';
import '../utils/locale_language_map.dart';
import '../languages.dart';

// WARNING: This APIs is server by Lance's free server, which has usage limits.
// Please do not abuse or attack this server.

class Api {
  // 获取天气预警信息
  static Future<List<WeatherWarning>> fetchWarning({
    required double lat,
    required double lon,
  }) async {
    // 获取当前locale并映射为API支持的lang
    String qweatherLang = 'en';
    final localeKey =
        appLanguages.firstWhere((l) => l.code == localeCodeNotifier.value).code;
    qweatherLang = localeToApiLang[localeKey] ?? 'en';
    final url = Uri.parse(
      '$alertUrl?location=$lon,$lat&lang=$qweatherLang',
    );
    try {
      final response = await http.get(url).timeout(Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['code'] == '200') {
          final List warnings = data['warning'] ?? [];
          return warnings.map((e) => WeatherWarning.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Weather Alert fetch error: $e');
    }
    return [];
  }

  // 获取天气数据
  static Future<WeatherData?> fetchWeather({
    required double latitude,
    required double longitude,
    String lang = 'zh',
    required String units,
  }) async {
    // 根据当前语言设置API请求的语言参数
    String lang = 'en-US';
    String? ws;
    final localeKey =
        appLanguages.firstWhere((l) => l.code == localeCodeNotifier.value).code;
    lang = localeToApiLang[localeKey] ?? 'en-US';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('weather_source') == 'QWeather') {
      ws = 'qweather';
    } else if (prefs.getString('weather_source') == 'OpenMeteo') {
      ws = 'om';
    }
    final url = Uri.parse('$forecastUrl'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&accept-language=$lang'
        '&source=$ws'
        '&unit=${units == 'F' ? 'fahrenheit' : 'celsius'}');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      kDebugMode ? debugPrint('Weather API response: ${response.body}') : null;
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      kDebugMode
          ? debugPrint('Weather API fetch error: ${response.body}')
          : null;
    }
    return null;
  }

  static Future<List<City>> searchCity(String query) async {
    // 根据当前语言设置API请求的语言参数
    String lang = 'en-US';
    String? ws;
    final localeKey =
        appLanguages.firstWhere((l) => l.code == localeCodeNotifier.value).code;
    lang = localeToApiLang[localeKey] ?? 'en-US';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('weather_source') == 'QWeather') {
      ws = 'qweather';
    } else if (prefs.getString('weather_source') == 'OpenMeteo') {
      ws = 'om';
    }
    final url =
        Uri.parse('$searchUrl?query=$query&accept-language=$lang&source=$ws');
    try {
      final response = await http.get(url).timeout(Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map((item) {
              final address = item['address'] ?? {};
              String name = item['name'] ?? '';
              String? admin = address['state'];
              String country = address['country'] ?? '';
              return City(
                name: name,
                admin: admin,
                country: country,
                lat: double.tryParse(item['lat'] ?? '') ?? 0,
                lon: double.tryParse(item['lon'] ?? '') ?? 0,
              );
            })
            .where((e) => e.lat != 0 && e.lon != 0)
            .toList();
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) debugPrint('Weather Search fetch error: $e');
    }
    return [];
  }
}
