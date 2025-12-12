import 'package:zephyr/core/import.dart';

class PromptBuilder {
  static String buildHealthPrompt(WeatherData weather, String cityName) {
    return '''
你是一个专业的健康生活顾问，请根据以下天气数据提供简明扼要的建议。

天气信息：
- 城市：$cityName
- 温度：${weather.current!.temperature}°C（体感温度 ${weather.current!.apparentTemperature}°C）
- 湿度：${weather.current!.humidity}%
- 风速：${weather.current!.windSpeed} m/s
- 降水量：${weather.hourly[0].precipitation} mm
- 天气状况：${getWeatherDescForWidget(weather.current!.weatherCode, 'zh_CN')}
- 能见度：${weather.current!.visibility} km

请提供以下四个方面的建议（每条建议不超过20个字，简洁实用）：

1. 穿衣建议
2. 运动建议
3. 出行建议
4. 健康提醒

请严格按照以下JSON格式回复，不要添加任何其他文字：
{
  "clothing": "建议内容",
  "exercise": "建议内容",
  "travel": "建议内容",
  "health": "建议内容"
}

示例：
{
  "clothing": "穿轻薄长袖，带件薄外套....",
  "exercise": "适合户外慢跑，注意防晒....",
  "travel": "适宜出行，携带雨具以防万一....",
  "health": "紫外线强，记得涂抹防晒霜...."
}
''';
  }
}
