import 'package:http/http.dart' as http;
import '../import.dart';

class Api {
  static String _getApiLang([String defaultLang = 'en-US']) {
    final localeKey = appLanguages
        .firstWhere((l) => l.code == localeCodeNotifier.value,
            orElse: () => appLanguages.first)
        .code;
    return localeToApiLang[localeKey] ?? defaultLang;
  }

  static Future<String?> _getWeatherSource() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString('weather_source');
    if (source == 'QWeather') {
      return 'qweather';
    } else if (source == 'OpenMeteo') {
      return 'om';
    }
    return null;
  }

  static String _getUnitParameter({required String units, String? ws}) {
    if (ws == 'om') {
      return units == 'F' ? 'fahrenheit' : 'celsius';
    }
    return units == 'F' ? 'i' : 'm';
  }

  // 获取天气预警信息
  static Future<List<WeatherWarning>> fetchWarning({
    required double lat,
    required double lon,
  }) async {
    try {
      final lang = _getApiLang();
      final url = Uri.parse(
        '${AppConstants.alertUrl}?location=$lon,$lat&lang=$lang',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        kDebugMode ? debugPrint('Weather Alert response: $data') : null;
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
    required String units,
  }) async {
    try {
      final lang = _getApiLang();
      final ws = await _getWeatherSource();
      final unitParam = _getUnitParameter(units: units, ws: ws);

      final url = Uri.parse('${AppConstants.forecastUrl}'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&accept-language=$lang'
          '&source=$ws'
          '&unit=$unitParam');

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        kDebugMode
            ? debugPrint('Weather API response: ${response.body}')
            : null;
        return WeatherData.fromJson(json.decode(response.body));
      } else {
        kDebugMode
            ? debugPrint('Weather API fetch error: ${response.body}')
            : null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Weather API fetch error: $e');
    }
    return null;
  }

  // 搜索城市
  static Future<List<City>> searchCity(String query) async {
    try {
      final lang = _getApiLang();
      final ws = await _getWeatherSource();
      final url = Uri.parse(
          '${AppConstants.searchUrl}?query=$query&accept-language=$lang&source=$ws');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
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
    } catch (e) {
      if (kDebugMode) debugPrint('Weather Search fetch error: $e');
    }
    return [];
  }
}
