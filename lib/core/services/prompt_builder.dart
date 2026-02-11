import 'package:zephyr/core/import.dart';

class PromptBuilder {
  // 构建AI建议
  static String buildHealthPrompt(WeatherData weather, String cityName) {
    final current = weather.current;
    final firstHourly = weather.hourly.isNotEmpty ? weather.hourly.first : null;

    String visibilityKm = '-';
    final currentVisibility = current?.visibility;
    if (currentVisibility != null && currentVisibility > 0) {
      visibilityKm = currentVisibility.toStringAsFixed(1);
    } else {
      for (final h in weather.hourly) {
        final v = h.visibility;
        if (v != null && v > 0) {
          visibilityKm = (v / 1000).toStringAsFixed(1);
          break;
        }
      }
    }

    final temp = current?.temperature.toStringAsFixed(1) ?? '-';
    final feelsLike = current?.apparentTemperature?.toStringAsFixed(1) ?? '-';
    final humidity = current?.humidity?.toStringAsFixed(0) ?? '-';
    final windSpeed = current?.windSpeed.toStringAsFixed(1) ?? '-';
    final precipitation = firstHourly?.precipitation?.toStringAsFixed(1) ?? '-';
    final weatherDesc =
        getWeatherDescForWidget(current?.weatherCode ?? 0, 'en');

    return '''
Act as a professional health and wellness advisor API. Please provide recommendations based on the following weather data.

Weather Data:
- City: $cityName
- Temperature: $temp°, Feels Like $feelsLike°
- Humidity: $humidity%
- Wind Speed: $windSpeed m/s
- Precipitation: $precipitation mm
- Weather: $weatherDesc
- Visibility: $visibilityKm km

Please provide recommendations based on location and weather conditions in the following areas: Clothing suggestions, Exercise recommendations, Travel advice, Health reminders.
Keep your response warm and friendly after synthesizing multiple areas, without greetings. Please use the ${localeCodeNotifier.value} in your reply. Keep your reply around 160 characters.
Please strictly adhere to the following JSON format when replying. No extra text or fences.
Example Output:
{
  "suggestion": "Today's temperature is 20°C, with comfortable conditions but strong winds. We recommend wearing long sleeves and pants, paired with a lightweight windproof jacket or windbreaker to effectively ward off the chill. Outdoor activities are not ideal. With low humidity, opt for breathable fabrics in your clothing choices. Consider bringing a thin scarf to prevent catching a chill from the wind."
}
''';
  }
}
