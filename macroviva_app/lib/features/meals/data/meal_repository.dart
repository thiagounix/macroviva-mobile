import '../../../core/errors/api_exception.dart';
import '../../../core/http/api_client.dart';
import 'create_meal_request.dart';
import 'meal_model.dart';

class MealRepository {
  const MealRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MealModel>> getTodayMeals() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/api/meals/today');
      final body = response.data;

      if (body == null) {
        return const [];
      }

      return body
          .whereType<Map<String, dynamic>>()
          .map(MealModel.fromJson)
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Nao foi possivel ler as refeicoes de hoje.',
      );
    }
  }

  Future<MealModel> createMeal(CreateMealRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/meals',
        data: request.toJson(),
      );

      final body = response.data;
      if (body == null) {
        throw const ApiException(
          message: 'Refeicao criada, mas a resposta veio vazia.',
        );
      }

      return MealModel.fromJson(body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'Nao foi possivel criar a refeicao.');
    }
  }
}
