import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client_provider.dart';
import '../data/food_model.dart';
import '../data/food_repository.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(apiClientProvider));
});

final foodsProvider = FutureProvider.autoDispose
    .family<List<FoodModel>, String>((ref, query) {
      final repository = ref.watch(foodRepositoryProvider);

      return repository.searchFoods(search: query);
    });
