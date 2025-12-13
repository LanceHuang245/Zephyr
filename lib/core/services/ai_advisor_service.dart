import 'package:http/http.dart' as http;
import '../import.dart';

class AIAdvisorService {
  static const String _aiConfigKey = 'ai_config';
  // static const String _adviceCacheKey = 'ai_advice_cache_';
  // static const Duration _cacheDuration = Duration(hours: 2);

  // 获取AI配置
  static Future<AIConfig?> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_aiConfigKey);

    if (configJson != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(configJson);
        return AIConfig.fromJson(json);
      } catch (e) {
        debugPrint('Unmarshal failed: $e');
      }
    }
    return null;
  }

  // 保存AI配置
  static Future<bool> saveConfig(AIConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final json = config.toJson();
    return await prefs.setString(_aiConfigKey, jsonEncode(json));
  }

  // 获取缓存的建议
  // static Future<AIAdvice?> getCachedAdvice(String city) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cacheKey = _adviceCacheKey + city;
  //   final adviceJson = prefs.getString(cacheKey);

  //   if (adviceJson != null) {
  //     try {
  //       final Map<String, dynamic> json = jsonDecode(adviceJson);
  //       final advice = AIAdvice.fromJson(json);

  //       if (DateTime.now().difference(advice.timestamp) < _cacheDuration) {
  //         return advice;
  //       }
  //     } catch (e) {
  //       debugPrint('解析缓存建议失败: $e');
  //     }
  //   }
  //   return null;
  // }

  // 缓存建议
  // static Future<bool> cacheAdvice(AIAdvice advice) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cacheKey = _adviceCacheKey + advice.city;
  //   final json = advice.toJson();
  //   return await prefs.setString(cacheKey, jsonEncode(json));
  // }

  // 获取AI建议
  static Future<AIAdviceResponse> getAdvice(
    WeatherData weather,
    String cityName,
  ) async {
    try {
      // final cachedAdvice = await getCachedAdvice(cityName);
      // if (cachedAdvice != null) {
      //   return AIAdviceResponse.success(cachedAdvice);
      // }

      final config = await getConfig();
      if (config == null || !config.enabled) {
        return AIAdviceResponse.error('AI功能未启用');
      }

      if (config.customEndpoint.isEmpty) {
        return AIAdviceResponse.error('未配置AI服务端点地址');
      }

      final prompt = PromptBuilder.buildHealthPrompt(weather, cityName);
      final response = await _sendRequest(prompt, config);

      if (response.statusCode == 200) {
        final advice = _parseAIResponse(response.body, cityName);
        if (advice != null) {
          // await cacheAdvice(advice);
          return AIAdviceResponse.success(advice);
        } else {
          return AIAdviceResponse.error('解析AI响应失败');
        }
      } else {
        return AIAdviceResponse.error('AI请求失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取AI建议时出错: $e');
      return AIAdviceResponse.error('获取AI建议时出错: $e');
    }
  }

  // 发送请求到AI服务
  static Future<http.Response> _sendRequest(
    String prompt,
    AIConfig config,
  ) async {
    debugPrint('发送请求到AI服务: $prompt');
    String endpoint = config.customEndpoint;
    final model = config.model.isNotEmpty ? config.model : 'default';
    final provider = config.provider.toLowerCase();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    headers.addAll(config.customHeaders);

    // 处理不同提供商的特定逻辑 (URL参数替换, Headers)
    if (provider == AIProviderTemplates.claude) {
      headers['x-api-key'] = config.apiKey;
      headers['anthropic-version'] = '2023-06-01';
    } else {
      if (!headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }
    }

    // 替换Header中的占位符 (如果用户在Custom Headers里用了)
    for (final key in headers.keys) {
      if (headers[key]!.contains('{api_key}')) {
        headers[key] = headers[key]!.replaceAll('{api_key}', config.apiKey);
      }
    }

    final body = _buildRequestBody(prompt, model, provider);

    return await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // 构建请求体
  static Map<String, dynamic> _buildRequestBody(
    String prompt,
    String model,
    String provider,
  ) {
    switch (provider) {
      case AIProviderTemplates.claude:
        return {
          'model': model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        };
      case AIProviderTemplates.openAI:
      default:
        return {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        };
    }
  }

  // 解析AI响应
  static AIAdvice? _parseAIResponse(String responseBody, String cityName) {
    try {
      Map<String, dynamic> content;

      try {
        content = jsonDecode(responseBody);
      } catch (e) {
        final RegExp jsonRegex = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonRegex.firstMatch(responseBody);
        if (match != null) {
          content = jsonDecode(match.group(0)!);
        } else {
          throw Exception('Unable to parse JSON');
        }
      }

      String suggestionText = '';

      // Gemini Response Format
      if (content.containsKey('candidates')) {
        final parts = content['candidates']?[0]?['content']?['parts'];
        if (parts != null && parts is List && parts.isNotEmpty) {
          suggestionText = parts[0]['text'] ?? '';
        }
      }
      // OpenAI / Generic Format
      else if (content.containsKey('choices')) {
        final messageContent = content['choices']?[0]?['message']?['content'];
        if (messageContent != null) {
          suggestionText = messageContent;
        }
      } else if (content.containsKey('content')) {
        // Claude returning list of content blocks
        final contentList = content['content'];
        if (contentList is List && contentList.isNotEmpty) {
          suggestionText = contentList[0]['text'] ?? '';
        } else if (contentList is String) {
          suggestionText = contentList;
        }
      } else if (content.containsKey('message')) {
        final messageContent = content['message']?['content'];
        if (messageContent != null) {
          suggestionText = messageContent;
        }
      } else if (content.containsKey('response')) {
        suggestionText = content['response'];
      } else if (content.containsKey('suggestion')) {
        suggestionText = content['suggestion'];
      }

      // 尝试从文本中提取JSON
      if (suggestionText.isNotEmpty) {
        final suggestionJson = _extractJsonFromText(suggestionText);
        if (suggestionJson != null &&
            suggestionJson.containsKey('suggestion')) {
          suggestionText = suggestionJson['suggestion'];
        }
      }

      if (suggestionText.isEmpty) {
        throw Exception('无法从响应中提取建议内容');
      }

      return AIAdvice(
        suggestion: suggestionText,
        timestamp: DateTime.now(),
        city: cityName,
      );
    } catch (e) {
      debugPrint('解析AI响应失败: $e');
      return null;
    }
  }

  // 从文本中提取JSON
  static Map<String, dynamic>? _extractJsonFromText(String text) {
    try {
      final RegExp jsonRegex =
          RegExp(r'\{[^{}]*"suggestion"[^{}]*\}', dotAll: true);
      final match = jsonRegex.firstMatch(text);
      if (match != null) {
        return jsonDecode(match.group(0)!);
      }
    } catch (e) {
      debugPrint('Extract json failed: $e');
    }
    return null;
  }

  // 清除所有缓存
  // static Future<void> clearCache() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final keys = prefs.getKeys();
  //   for (final key in keys) {
  //     if (key.startsWith(_adviceCacheKey)) {
  //       await prefs.remove(key);
  //     }
  //   }
  // }
}
