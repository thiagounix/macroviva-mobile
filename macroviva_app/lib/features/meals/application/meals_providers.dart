import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client_provider.dart';
import '../data/create_meal_request.dart';
import '../data/meal_model.dart';
import '../data/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(apiClientProvider));
});

final todayMealsProvider = FutureProvider.autoDispose<List<MealModel>>((ref) {
  return ref.watch(mealRepositoryProvider).getTodayMeals();
});

final createMealControllerProvider =
    AsyncNotifierProvider<CreateMealController, MealModel?>(
      CreateMealController.new,
    );

class CreateMealController extends AsyncNotifier<MealModel?> {
  @override
  Future<MealModel?> build() async {
    return null;
  }

  Future<MealModel> createMeal(CreateMealRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(mealRepositoryProvider);
      final result = await repository.createMeal(request);

      ref.invalidate(todayMealsProvider);
      state = AsyncData(result);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
