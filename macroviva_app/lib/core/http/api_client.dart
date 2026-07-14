import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../identity/installation_identity_service.dart';
import 'tester_identity_interceptor.dart';

class ApiClient {
  ApiClient(
    AppConfig config,
    InstallationIdentityService installationIdentityService, {
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               headers: const {'Accept': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      TesterIdentityInterceptor(installationIdentityService),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Response<T>> post<T>(String path, {Object? data}) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(message: 'Tempo de conexão esgotado.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Não foi possível conectar a API local.',
      );
    }

    if (statusCode == 400) {
      return ApiException(
        message: _readProblemMessage(error.response?.data, 'Dados inválidos.'),
        statusCode: statusCode,
      );
    }

    if (statusCode == 404) {
      return ApiException(
        message: _readProblemMessage(
          error.response?.data,
          'Recurso não encontrado.',
        ),
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: 'Erro interno na API local.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: 'Erro ao comunicar com a API.',
      statusCode: statusCode,
    );
  }

  String _readProblemMessage(Object? data, String fallback) {
    if (data is Map<String, dynamic>) {
      final title = data['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title;
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}
