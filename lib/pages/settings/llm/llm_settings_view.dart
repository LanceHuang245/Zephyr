import 'dart:convert';
import '../import.dart';

// 本地配置模型，用于UI列表管理
class LLMProviderConfig {
  String id;
  String name;
  String templateId; // 'openai', 'gemini', 'custom' 等
  String apiKey;
  String endpoint;
  String model;

  LLMProviderConfig({
    required this.id,
    required this.name,
    required this.templateId,
    this.apiKey = '',
    this.endpoint = '',
    this.model = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templateId': templateId,
        'apiKey': apiKey,
        'endpoint': endpoint,
        'model': model,
      };

  factory LLMProviderConfig.fromJson(Map<String, dynamic> json) {
    return LLMProviderConfig(
      id: json['id'],
      name: json['name'],
      templateId: json['templateId'],
      apiKey: json['apiKey'] ?? '',
      endpoint: json['endpoint'] ?? '',
      model: json['model'] ?? '',
    );
  }
}

class LLMSettingsPage extends StatefulWidget {
  const LLMSettingsPage({super.key});

  @override
  State<LLMSettingsPage> createState() => _LLMSettingsPageState();
}

class _LLMSettingsPageState extends State<LLMSettingsPage> {
  // 已配置的Provider列表
  List<LLMProviderConfig> _providers = [];
  // 当前选中的Provider ID (用于编辑和激活)
  String? _selectedProviderId;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // 加载数据
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 加载保存的Provider列表
    final providersJson = prefs.getString('llm_configured_providers');
    if (providersJson != null) {
      try {
        final List<dynamic> list = jsonDecode(providersJson);
        _providers = list.map((e) => LLMProviderConfig.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Failed to load providers: $e');
      }
    }

    // 2. 加载当前生效的全局配置
    final activeConfig = await AIAdvisorService.getConfig();

    // 如果列表为空但有旧配置，尝试迁移 (Optional: 这里的策略是"默认空"，但为了不丢失用户现有配置，还是迁移一下比较好)
    if (_providers.isEmpty &&
        activeConfig != null &&
        activeConfig.apiKey.isNotEmpty) {
      final migratedProvider = LLMProviderConfig(
        id: 'migrated_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Default (${activeConfig.provider})',
        templateId: activeConfig.provider.isNotEmpty
            ? activeConfig.provider
            : AIProviderTemplates.gemini,
        apiKey: activeConfig.apiKey,
        endpoint: activeConfig.customEndpoint,
        model: activeConfig.model,
      );
      _providers.add(migratedProvider);
      _selectedProviderId = migratedProvider.id;
      _saveProvidersList(); // 保存迁移结果
    } else if (activeConfig != null) {
      // 尝试匹配当前激活的配置到列表中的某一项
      // 这里没有严格的ID匹配机制(因为全局Config没存ID)，所以我们主要依赖用户手动选择。
      // 简单起见，如果列表不为空，我们默认选中第一个。
      if (_providers.isNotEmpty) {
        _selectedProviderId = _providers.first.id;
      }
    }

    // 填充UI
    _updateControllersFromSelection();

    setState(() {
      _loading = false;
    });
  }

  // 根据当前选中的ID更新输入框
  void _updateControllersFromSelection() {
    if (_selectedProviderId == null) {
      _apiKeyController.clear();
      _endpointController.clear();
      _modelController.clear();
      return;
    }

    final provider = _providers.firstWhere((p) => p.id == _selectedProviderId,
        orElse: () => _providers.first);

    _apiKeyController.text = provider.apiKey;
    _endpointController.text = provider.endpoint;
    _modelController.text = provider.model;
  }

  // 保存当前输入框的内容到内存列表
  void _saveCurrentInputToMemory() {
    if (_selectedProviderId == null) return;

    final index = _providers.indexWhere((p) => p.id == _selectedProviderId);
    if (index != -1) {
      _providers[index].apiKey = _apiKeyController.text;
      _providers[index].endpoint = _endpointController.text;
      _providers[index].model = _modelController.text;
    }
  }

  // 持久化列表到磁盘
  Future<void> _saveProvidersList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _providers.map((e) => e.toJson()).toList();
    await prefs.setString('llm_configured_providers', jsonEncode(jsonList));
  }

  // 切换选中
  void _onSelectionChanged(String? newId) {
    if (newId == null) return;

    // 切换前保存当前输入
    _saveCurrentInputToMemory();

    setState(() {
      _selectedProviderId = newId;
      _updateControllersFromSelection();
    });
  }

  // 添加新Provider的对话框
  Future<void> _showAddProviderDialog() async {
    String selectedTemplateId = AIProviderTemplates.gemini;
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).llmAddProvider),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedTemplateId,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).template),
                items: AIProviderTemplates.templates.map((t) {
                  return DropdownMenuItem(
                    value: t.providerId,
                    child: Text(t.label),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedTemplateId = v);
                },
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).name,
                  hintText: 'e.g. My Personal Gemini',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _addNewProvider(name, selectedTemplateId);
                  Navigator.pop(context);
                }
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewProvider(String name, String templateId) {
    final template = AIProviderTemplates.getTemplate(templateId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    final newProvider = LLMProviderConfig(
      id: newId,
      name: name,
      templateId: templateId,
      endpoint: template.baseUrl, // 预填默认Endpoint
      model: template.defaultModel, // 预填默认Model
    );

    setState(() {
      _saveCurrentInputToMemory(); // 保存之前的
      _providers.add(newProvider);
      _selectedProviderId = newId; // 选中新建的
      _updateControllersFromSelection(); // 更新UI
    });

    _saveProvidersList();
  }

  void _deleteProvider(String id) {
    setState(() {
      if (_selectedProviderId == id) {
        _selectedProviderId = null;
        _apiKeyController.clear();
        _endpointController.clear();
        _modelController.clear();
      }
      _providers.removeWhere((p) => p.id == id);
    });
    _saveProvidersList();

    // 如果删除后列表不为空且没选中，默认选中第一个
    if (_providers.isNotEmpty && _selectedProviderId == null) {
      setState(() {
        _selectedProviderId = _providers.first.id;
        _updateControllersFromSelection();
      });
    }
  }

  // 保存并激活配置
  Future<void> _saveAndActivate() async {
    if (_selectedProviderId == null) return;

    _saveCurrentInputToMemory();
    await _saveProvidersList();

    final provider = _providers.firstWhere((p) => p.id == _selectedProviderId);

    // 获取之前的配置以保留enabled状态
    final existingConfig = await AIAdvisorService.getConfig();
    final enabled = existingConfig?.enabled ?? false;

    final newConfig = AIConfig(
      provider: provider.templateId,
      apiKey: provider.apiKey,
      customEndpoint: provider.endpoint,
      model: provider.model,
      enabled: enabled,
      customHeaders: existingConfig?.customHeaders ?? {},
    );

    await AIAdvisorService.saveConfig(newConfig);

    if (mounted) {
      NotificationUtils.showSnackBar(
          context, AppLocalizations.of(context).llmSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar:
            AppBar(title: Text(AppLocalizations.of(context).llmConfiguration)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).llmConfiguration),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).llmProviders,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _showAddProviderDialog,
                      icon: const Icon(Icons.add),
                      color: colorScheme.primary,
                    )
                  ],
                ),
                if (_providers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).llmNoProviders,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _providers.map((p) {
                      return RadioListTile<String>(
                        title: Text(p.name),
                        subtitle: Text(
                          AIProviderTemplates.getTemplate(p.templateId).label,
                          style: textTheme.bodySmall,
                        ),
                        value: p.id,
                        groupValue: _selectedProviderId,
                        onChanged: _onSelectionChanged,
                        contentPadding: EdgeInsets.zero,
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteProvider(p.id),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedProviderId != null) ...[
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
                    AppLocalizations.of(context).settings,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // API Key
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
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
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

                  // Endpoint
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.onInverseSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _endpointController,
                      style: textTheme.bodyLarge,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'URL',
                        hintStyle: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
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

                  // Model
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
                        hintText: 'Model',
                        hintStyle: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
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
                      // 测试前先暂存当前输入
                      _saveCurrentInputToMemory();

                      // 执行保存操作，确保测试的是最新数据
                      await _saveAndActivate();

                      final mockWeather = WeatherData(
                        current: CurrentWeather(
                          temperature: 20,
                          weatherCode: 48,
                          windSpeed: 10,
                          apparentTemperature: 24,
                          humidity: 20,
                          visibility: 1,
                        ),
                        hourly: [HourlyWeather(time: "7:00", precipitation: 0)],
                        daily: [],
                      );

                      final adviceResponse = await AIAdvisorService.getAdvice(
                          mockWeather, "Beijing");

                      if (adviceResponse.success &&
                          adviceResponse.advice != null) {
                        if (mounted) {
                          NotificationUtils.showSnackBar(
                              context, "Test Success: Advice received");
                        }
                      } else {
                        if (mounted) {
                          NotificationUtils.showSnackBar(
                              context, "Test Failed: ${adviceResponse.error}");
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context).test),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveAndActivate,
                    child:
                        Text(MaterialLocalizations.of(context).saveButtonLabel),
                  ),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
