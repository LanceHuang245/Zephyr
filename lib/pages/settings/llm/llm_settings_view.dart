import 'package:zephyr/core/import.dart';

import '../import.dart';

// LLM配置页面
class LLMSettingsPage extends StatefulWidget {
  const LLMSettingsPage({super.key});

  @override
  State<LLMSettingsPage> createState() => _LLMSettingsPageState();
}

class _LLMSettingsPageState extends State<LLMSettingsPage> {
  String _provider = AIProviderTemplates.gemini;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  bool _loading = true;
  bool _isEndpointReadOnly = true;

  // AI提供者模板列表
  final List<AIProviderTemplate> _templates = AIProviderTemplates.templates;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // 加载AI配置
  Future<void> _loadSettings() async {
    final config = await AIAdvisorService.getConfig();

    setState(() {
      if (config != null) {
        _provider = config.provider.isNotEmpty
            ? config.provider
            : AIProviderTemplates.gemini;
        _apiKeyController.text = config.apiKey;
        _endpointController.text = config.customEndpoint;
        _modelController.text = config.model;
      } else {
        final defaultTemplate =
            AIProviderTemplates.getTemplate(AIProviderTemplates.gemini);
        _provider = defaultTemplate.providerId;
        _endpointController.text = defaultTemplate.baseUrl;
        _modelController.text = defaultTemplate.defaultModel;
      }

      _checkEndpointReadOnly();
      _loading = false;
    });
  }

  // 检查Endpoint是否可编辑
  void _checkEndpointReadOnly() {
    _isEndpointReadOnly = _provider != AIProviderTemplates.custom;
  }

  // 保存AI配置
  Future<void> _saveSettings() async {
    // 获取现有配置，并保留enabled状态
    final existingConfig = await AIAdvisorService.getConfig();
    final enabled = existingConfig?.enabled ?? false;

    final newConfig = AIConfig(
      provider: _provider,
      apiKey: _apiKeyController.text,
      customEndpoint: _endpointController.text,
      model: _modelController.text,
      enabled: enabled,
      customHeaders: existingConfig?.customHeaders ?? {},
    );

    await AIAdvisorService.saveConfig(newConfig);
  }

  void _onProviderChanged(String? newValue) {
    if (newValue == null) return;

    final template = AIProviderTemplates.getTemplate(newValue);

    setState(() {
      _provider = newValue;
      _checkEndpointReadOnly();

      if (_provider == AIProviderTemplates.custom) {
        _apiKeyController.clear();
        _endpointController.clear();
        _modelController.clear();
      } else {
        _endpointController.text = template.baseUrl;
        _modelController.text = template.defaultModel;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('LLM Configuration')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 提供者选择区域
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _templates.map((template) {
                    return RadioListTile<String>(
                      title: Text(template.label),
                      subtitle:
                          template.providerId != AIProviderTemplates.custom
                              ? Text(template.baseUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall)
                              : null,
                      value: template.providerId,
                      groupValue: _provider,
                      contentPadding: EdgeInsets.zero,
                      activeColor: colorScheme.primary,
                      onChanged: _onProviderChanged,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 配置字段区域
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // API Key输入框
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.onInverseSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _apiKeyController,
                    style: textTheme.bodyLarge,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'API Key',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 24),
                // Endpoint输入框
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isEndpointReadOnly
                        ? colorScheme.onInverseSurface.withValues(alpha: 0.5)
                        : colorScheme.onInverseSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _endpointController,
                    enabled: !_isEndpointReadOnly,
                    style: textTheme.bodyLarge,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Endpoint URL',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.link_outlined),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Model输入框
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.onInverseSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _modelController,
                    style: textTheme.bodyLarge,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Model Name',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.model_training_outlined),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _saveSettings();

                    final mockWeather = WeatherData(
                      current: CurrentWeather(
                        temperature: 20,
                        weatherCode: 48,
                        windSpeed: 10,
                        apparentTemperature: 24,
                        humidity: 20,
                        visibility: 1,
                      ),
                      hourly: [
                        HourlyWeather(
                          time: "7:00",
                          precipitation: 0,
                        )
                      ],
                      daily: [],
                    );

                    final adviceResponse = await AIAdvisorService.getAdvice(
                        mockWeather, "Beijing");

                    if (adviceResponse.success &&
                        adviceResponse.advice != null) {
                      debugPrint(
                          'AI Advice Success: ${adviceResponse.advice!.suggestion}');
                    } else {
                      debugPrint('AI Advice Error: ${adviceResponse.error}');
                      NotificationUtils.showSnackBar(context, "获取建议失败");
                    }
                  },
                  child: const Text('Test'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('Save'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
