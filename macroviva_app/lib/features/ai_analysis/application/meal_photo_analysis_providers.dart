import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/http/api_client_provider.dart';
import '../../meals/application/meals_providers.dart';
import '../data/analyze_meal_photo_response.dart';
import '../data/confirm_meal_analysis_request.dart';
import '../data/meal_photo_analysis_repository.dart';

final mealPhotoAnalysisRepositoryProvider =
    Provider<MealPhotoAnalysisRepository>((ref) {
      return MealPhotoAnalysisRepository(ref.watch(apiClientProvider));
    });

final analyzeMealPhotoControllerProvider =
    AsyncNotifierProvider<
      AnalyzeMealPhotoController,
      AnalyzeMealPhotoResponse?
    >(AnalyzeMealPhotoController.new);

final confirmMealAnalysisControllerProvider =
    AsyncNotifierProvider<ConfirmMealAnalysisController, void>(
      ConfirmMealAnalysisController.new,
    );

class AnalyzeMealPhotoController
    extends AsyncNotifier<AnalyzeMealPhotoResponse?> {
  @override
  Future<AnalyzeMealPhotoResponse?> build() async {
    return null;
  }

  Future<AnalyzeMealPhotoResponse> analyze(
    XFile photo, {
    String mealType = 'Lunch',
  }) async {
    state = const AsyncLoading();

    try {
      final result = await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .analyzeMealPhoto(photo, mealType: mealType);
      state = AsyncData(result);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

class ConfirmMealAnalysisController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> confirm(
    String analysisId,
    ConfirmMealAnalysisRequest request,
  ) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .confirmMealAnalysis(analysisId, request);
      ref.invalidate(todayMealsProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
