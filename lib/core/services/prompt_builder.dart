import 'package:zephyr/core/import.dart';

class PromptBuilder {
  static String buildHealthPrompt(WeatherData weather, String cityName) {
    return '''
Act as a professional health and wellness advisor API. Please provide recommendations based on the following weather data.

Weather Data：
- City：$cityName
- Temperature：${weather.current!.temperature}°（Feels Like ${weather.current!.apparentTemperature}°）
- Humidity：${weather.current!.humidity}%
- WindSpeed：${weather.current!.windSpeed} m/s
- Precipitation：${weather.hourly[0].precipitation} mm
- Weather：${getWeatherDescForWidget(weather.current!.weatherCode, 'en')}
- Visibility：${weather.current!.visibility} km

Please provide recommendations based on location and weather conditions in the following areas: Clothing suggestions, Exercise recommendations, Travel advice, Health reminders
Keep your response friendly and warm, without formal greetings. Please use the ${localeCodeNotifier.value} in your reply. Keep your reply around 160 characters.
Please strictly adhere to the following JSON format when replying. No extra text or fences.
Example Output:
{
  "suggestion": "Today's temperature is 20°C, with comfortable conditions but strong winds. We recommend wearing long sleeves and pants, paired with a lightweight windproof jacket or windbreaker to effectively ward off the chill. Outdoor activities are not ideal. With low humidity, opt for breathable fabrics in your clothing choices. Consider bringing a thin scarf to prevent catching a chill from the wind."
}
''';
  }
}
