class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const developmentFallbackBaseUrl = 'http://localhost:5169';

  factory AppConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: developmentFallbackBaseUrl,
    );

    return const AppConfig(apiBaseUrl: configuredBaseUrl);
  }

  final String apiBaseUrl;
}
