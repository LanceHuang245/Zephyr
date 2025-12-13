class AIProviderTemplate {
  final String label;
  final String providerId;
  final String baseUrl;
  final String defaultModel;

  const AIProviderTemplate({
    required this.label,
    required this.providerId,
    required this.baseUrl,
    required this.defaultModel,
  });
}

class AIProviderTemplates {
  static const String openAI = 'openai';
  static const String gemini = 'gemini';
  static const String claude = 'claude';
  static const String custom = 'custom';

  static const List<AIProviderTemplate> templates = [
    AIProviderTemplate(
      label: 'OpenAI',
      providerId: openAI,
      baseUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-4',
    ),
    AIProviderTemplate(
      label: 'Gemini',
      providerId: gemini,
      baseUrl:
          'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
      defaultModel: 'gemini-2.5-flash',
    ),
    AIProviderTemplate(
      label: 'Claude',
      providerId: claude,
      baseUrl: 'https://api.anthropic.com/v1/messages',
      defaultModel: 'claude-3-haiku-20240307',
    ),
    AIProviderTemplate(
      label: 'Custom',
      providerId: custom,
      baseUrl: '',
      defaultModel: '',
    ),
  ];

  static AIProviderTemplate getTemplate(String providerId) {
    return templates.firstWhere(
      (t) => t.providerId == providerId,
      orElse: () => templates.last, // Default to Custom
    );
  }
}
