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
  static const String openAICompatible = 'openai_compatible';
  static const String openAIResponses = 'openai_responses';
  static const String anthropic = 'anthropic';
  static const String gemini = 'gemini';

  static const List<AIProviderTemplate> templates = [
    AIProviderTemplate(
      label: 'OpenAI Compatible',
      providerId: openAICompatible,
      baseUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-4o-mini',
    ),
    AIProviderTemplate(
      label: 'OpenAI Responses',
      providerId: openAIResponses,
      baseUrl: 'https://api.openai.com/v1/responses',
      defaultModel: 'gpt-4o-mini',
    ),
    AIProviderTemplate(
      label: 'Anthropic',
      providerId: anthropic,
      baseUrl: 'https://api.anthropic.com/v1/messages',
      defaultModel: 'claude-3-haiku-20240307',
    ),
    AIProviderTemplate(
      label: 'Gemini Official Endpoint',
      providerId: gemini,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
      defaultModel: 'gemini-2.5-flash',
    ),
  ];

  static String resolveEndpointType(String providerId) {
    switch (providerId) {
      case openAICompatible:
      case openAIResponses:
      case anthropic:
      case gemini:
        return providerId;
      default:
        return openAICompatible;
    }
  }

  static AIProviderTemplate getTemplate(String providerId) {
    return templates.firstWhere(
      (t) => t.providerId == resolveEndpointType(providerId),
      orElse: () => templates.first,
    );
  }
}
