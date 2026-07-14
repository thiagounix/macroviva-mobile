import 'package:dio/dio.dart';

import '../identity/installation_identity_service.dart';

class TesterIdentityInterceptor extends Interceptor {
  TesterIdentityInterceptor(this._installationIdentityService);

  final InstallationIdentityService _installationIdentityService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final installationId = await _installationIdentityService.getOrCreateId();
      options.headers[InstallationIdentityService.headerName] = installationId;
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
