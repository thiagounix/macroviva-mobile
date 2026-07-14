import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../identity/installation_identity_service.dart';
import 'api_client.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final installationIdentityServiceProvider =
    Provider<InstallationIdentityService>((ref) {
      return InstallationIdentityService();
    });

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(appConfigProvider),
    ref.watch(installationIdentityServiceProvider),
  );
});
