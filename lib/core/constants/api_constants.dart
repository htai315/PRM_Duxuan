class ApiConstants {
  ApiConstants._();

  static const String openAiApiKey =
      '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';

  static const String openAiResponsesUrl =
      'https://api.openai.com/v1/responses';

  static const String openAiModel = 'gpt-4o-mini';

  static const String publicShareApiBaseUrl = String.fromEnvironment(
    'PUBLIC_SHARE_API_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );

  static bool get hasOpenAiApiKey => openAiApiKey.trim().isNotEmpty;

  static bool get hasPublicShareApi => publicShareApiBaseUrl.trim().isNotEmpty;
}
