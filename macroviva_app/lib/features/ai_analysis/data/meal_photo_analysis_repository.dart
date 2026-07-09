import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/http/api_client.dart';
import 'analyze_meal_photo_response.dart';
import 'confirm_meal_analysis_request.dart';

class MealPhotoAnalysisRepository {
  const MealPhotoAnalysisRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AnalyzeMealPhotoResponse> analyzeMealPhoto(
    XFile photo, {
    String mealType = 'Lunch',
  }) async {
    try {
      final bytes = await photo.readAsBytes();
      final filename = photo.name.trim().isNotEmpty
          ? photo.name.trim()
          : 'meal-photo.jpg';
      final multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
      final formData = FormData.fromMap({
        'file': multipartFile,
        'mealType': mealType,
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/ai/meal-photo/analyze',
        data: formData,
      );
      final body = response.data;

      if (body == null) {
        throw const ApiException(
          message: 'Análise criada, mas a resposta veio vazia.',
        );
      }

      final result = AnalyzeMealPhotoResponse.fromJson(body);
      if (result.analysisId.isEmpty) {
        throw const ApiException(
          message: 'A resposta da análise veio sem identificador.',
        );
      }

      return result;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Não foi possível enviar a foto para análise.',
      );
    }
  }

  Future<void> confirmMealAnalysis(
    String analysisId,
    ConfirmMealAnalysisRequest request,
  ) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/ai/meal-photo/$analysisId/confirm',
        data: request.toJson(),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Não foi possível confirmar a análise da refeição.',
      );
    }
  }
}
