class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.showDebugToolsEnabled = showDebugTools,
    this.mockPhotoAnalysisEnabled = enableMockPhotoAnalysis,
  });

  static const developmentFallbackBaseUrl = 'http://localhost:5169';
  static const showDebugTools = bool.fromEnvironment(
    'SHOW_DEBUG_TOOLS',
    defaultValue: false,
  );
  static const enableMockPhotoAnalysis = bool.fromEnvironment(
    'ENABLE_MOCK_PHOTO_ANALYSIS',
    defaultValue: false,
  );

  factory AppConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: developmentFallbackBaseUrl,
    );

    return const AppConfig(apiBaseUrl: configuredBaseUrl);
  }

  final String apiBaseUrl;
  final bool showDebugToolsEnabled;
  final bool mockPhotoAnalysisEnabled;
}
