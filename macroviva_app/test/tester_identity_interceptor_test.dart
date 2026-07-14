import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macroviva_app/core/config/app_config.dart';
import 'package:macroviva_app/core/http/api_client.dart';
import 'package:macroviva_app/core/identity/installation_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const installationId = '11111111-1111-4111-8111-111111111111';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('adds the tester header while preserving existing headers', () async {
    final adapter = RecordingHttpClientAdapter();
    final dio = Dio(
      BaseOptions(headers: <String, Object>{'X-Existing': 'value'}),
    )..httpClientAdapter = adapter;
    final client = ApiClient(
      const AppConfig(apiBaseUrl: 'http://localhost:5169'),
      InstallationIdentityService(uuidGenerator: () => installationId),
      dio: dio,
    );

    await client.get<void>('/health');

    expect(
      adapter.requestOptions?.headers[InstallationIdentityService.headerName],
      installationId,
    );
    expect(adapter.requestOptions?.headers['X-Existing'], 'value');
  });
}

class RecordingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? requestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
