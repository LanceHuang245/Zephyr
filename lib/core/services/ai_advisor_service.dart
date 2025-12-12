// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/ai_config.dart';
// import '../models/ai_advice.dart';
// import '../models/weather.dart';
// import 'prompt_builder.dart';

// class AIAdvisorService {
//   static const String _aiConfigKey = 'ai_config';
//   static const String _adviceCacheKey = 'ai_advice_cache_';
//   static const Duration _cacheDuration = Duration(hours: 2);

//   // AI配置获取方法
//   static Map<String, AIProvider> getProviders(List<AIConfig> configs) {
//     final providers = <String, AIProvider>{};
//     for (final config in configs) {
//       if (config.enabled) {
//         providers[config.provider] = AIProvider(
//           name: config.provider,
//           endpoint: config.customEndpoint.isNotEmpty ? config.customEndpoint : '',
//           model: config.model.isNotEmpty ? config.model : '',
//           headers: config.customHeaders,
//           description: '用户自定义的AI提供商',
//         );
//       }
//     }
//     return providers;
//   }

//   /// 获取AI配置
//   static Future<AIConfig?> getConfig() async {
//     final prefs = await SharedPreferences.getInstance();
//     final configJson = prefs.getString(_aiConfigKey);

//     if (configJson != null) {
//       try {
//         final Map<String, dynamic> json = jsonDecode(configJson);
//         return AIConfig.fromJson(json);
//       } catch (e) {
//         // 忽略错误，返回null
//       }
//     }
//     return null;
//   }

//   /// 保存AI配置
//   static Future<bool> saveConfig(AIConfig config) async {
//     final prefs = await SharedPreferences.getInstance();
//     final json = config.toJson();
//     return await prefs.setString(_aiConfigKey, jsonEncode(json));
//   }

//   /// 获取缓存的建议
//   static Future<AIAdvice?> getCachedAdvice(String city) async {
//     final prefs = await SharedPreferences.getInstance();
//     final cacheKey = _adviceCacheKey + city;
//     final adviceJson = prefs.getString(cacheKey);

//     if (adviceJson != null) {
//       try {
//         final Map<String, dynamic> json = jsonDecode(adviceJson);
//         final advice = AIAdvice.fromJson(json);

//         // 检查缓存是否过期
//         if (DateTime.now().difference(advice.timestamp) < _cacheDuration) {
//           return advice;
//         }
//       } catch (e) {
//         // 忽略错误
//       }
//     }
//     return null;
//   }

//   /// 缓存建议
//   static Future<bool> cacheAdvice(AIAdvice advice) async {
//     final prefs = await SharedPreferences.getInstance();
//     final cacheKey = _adviceCacheKey + advice.city;
//     final json = advice.toJson();
//     return await prefs.setString(cacheKey, jsonEncode(json));
//   }

//   /// 获取AI建议
//   static Future<AIAdviceResponse> getAdvice(
//     WeatherData weather,
//     String cityName,
//   ) async {
//     try {
//       // 首先检查缓存
//       final cachedAdvice = await getCachedAdvice(cityName);
//       if (cachedAdvice != null) {
//         return AIAdviceResponse.success(cachedAdvice);
//       }

//       // 获取AI配置
//       final config = await getConfig();
//       if (config == null || !config.enabled) {
//         return AIAdviceResponse.error('AI功能未启用');
//       }

//       // 构建请求
//       final prompt = PromptBuilder.buildHealthPrompt(weather, cityName);
//       final response = await _makeAIRequest(prompt, config);

//       if (response.statusCode == 200) {
//         final advice = _parseAIResponse(response.body, cityName);
//         if (advice != null) {
//           // 缓存建议
//           await cacheAdvice(advice);
//           return AIAdviceResponse.success(advice);
//         } else {
//           return AIAdviceResponse.error('解析AI响应失败');
//         }
//       } else {
//         return AIAdviceResponse.error('AI请求失败: ${response.statusCode}');
//       }
//     } catch (e) {
//       return AIAdviceResponse.error('获取AI建议时出错: $e');
//     }
//   }

//   /// 发送请求到AI服务
//   static Future<http.Response> _makeAIRequest(
//       String prompt, AIConfig config) async {
//     // 使用用户自定义的配置
//     if (config.customEndpoint.isEmpty) {
//       throw Exception('未配置AI服务端点地址');
//     }

//     final endpoint = config.customEndpoint;
//     final model = config.model.isNotEmpty ? config.model : 'default';

//     // 构建请求头
//     final headers = <String, String>{};
//     headers.addAll(config.customHeaders);

//     // 替换API密钥占位符
//     for (final key in headers.keys) {
//       if (headers[key]!.contains('{api_key}')) {
//         headers[key] = headers[key]!.replaceAll('{api_key}', config.apiKey);
//       }
//     }

//     headers['Content-Type'] = 'application/json';

//     // // 构建请求体
//     // Map<String, dynamic> body;
//     // switch (config.provider) {

//     // }

//     // return await http.post(
//     //   Uri.parse(endpoint),
//     //   headers: headers,
//     //   body: jsonEncode(body),
//     // );
//   }

//   /// 解析AI响应
//   static AIAdvice? _parseAIResponse(String responseBody, String cityName) {
//     try {
//       // 尝试直接解析为JSON
//       Map<String, dynamic> content;

//       try {
//         content = jsonDecode(responseBody);
//       } catch (e) {
//         // 如果不是直接JSON，尝试提取JSON字符串
//         final RegExp jsonRegex = RegExp(r'\{.*\}', dotAll: true);
//         final match = jsonRegex.firstMatch(responseBody);
//         if (match != null) {
//           content = jsonDecode(match.group(0)!);
//         } else {
//           throw Exception('无法从响应中提取JSON');
//         }
//       }

//       // 如果响应包含嵌套的消息结构，尝试提取内容
//       if (content.containsKey('choices')) {
//         // 类似OpenAI的格式
//         final messageContent = content['choices']?[0]?['message']?['content'];
//         if (messageContent != null) {
//           content = jsonDecode(messageContent);
//         }
//       } else if (content.containsKey('content')) {
//         // 类似Anthropic的格式
//         final text = content['content']?[0]?['text'];
//         if (text != null) {
//           content = jsonDecode(text);
//         }
//       } else if (content.containsKey('message')) {
//         // 类似Ollama的格式
//         final messageContent = content['message']?['content'];
//         if (messageContent != null) {
//           content = jsonDecode(messageContent);
//         }
//       }

//       // 提取建议内容
//       return AIAdvice(
//         clothing: content['clothing'] ?? '暂无建议',
//         exercise: content['exercise'] ?? '暂无建议',
//         travel: content['travel'] ?? '暂无建议',
//         health: content['health'] ?? '暂无建议',
//         timestamp: DateTime.now(),
//         city: cityName,
//       );
//     } catch (e) {
//       // 解析失败
//       return null;
//     }
//   }

//   /// 清除所有缓存
//   static Future<void> clearCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     for (final key in keys) {
//       if (key.startsWith(_adviceCacheKey)) {
//         await prefs.remove(key);
//       }
//     }
//   }
// }
