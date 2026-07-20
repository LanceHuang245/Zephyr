import 'package:zephyr/core/import.dart';

class PromptBuilder {
  // Builds a compact, localized recommendation from the supplied weather data.
  static String buildHealthPrompt(WeatherData weather, String cityName) {
    final current = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    final now = DateTime.now();
    final upcomingHours = weather.hourly
        .where((hour) {
          final time = DateTime.tryParse(hour.time);
          return time == null ||
              time.add(const Duration(hours: 1)).isAfter(now);
        })
        .take(6)
        .map((hour) {
          return _compactWeatherJson(hour.toJson(), hour.weatherCode);
        })
        .toList();
    final weatherContext = <String, dynamic>{
      'city': cityName,
      'temperature_unit': '°${tempUnitNotifier.value}',
      if (current != null)
        'current': _compactWeatherJson(
          current.toJson(),
          current.weatherCode,
        ),
      if (today != null)
        'today': _compactWeatherJson(today.toJson(), today.weatherCode),
      if (upcomingHours.isNotEmpty) 'next_6_hours': upcomingHours,
    };

    return '''
You are a concise weather-life advisor. Base your recommendation only on the supplied weather data.

Weather Data (JSON):
${jsonEncode(weatherContext)}

Write one natural, coherent paragraph in ${localeCodeNotifier.value}. Prioritize unusual or high-impact conditions; if there is a safety risk, state the most important precaution first. Give specific, practical advice about clothing, outdoor activity or travel, and health, omitting irrelevant categories. Mention weather values only when they explain the advice.
Keep the suggestion between 60 and 90 characters, including punctuation. Avoid repetition, greetings, headings, bullet points, exaggerated warnings, medical diagnoses, and unsupported claims.
Return valid JSON only, without Markdown fences or extra text: {"suggestion":"..."}
''';
  }

  // Removes unavailable values and adds a readable weather description.
  static Map<String, dynamic> _compactWeatherJson(
    Map<String, dynamic> json,
    int? weatherCode,
  ) {
    return {
      for (final entry in json.entries)
        if (entry.value != null) entry.key: entry.value,
      if (weatherCode != null)
        'weather_description': getWeatherDescForWidget(weatherCode, 'en'),
    };
  }
}
