import '../../../core/errors/api_exception.dart';
import '../../../core/http/api_client.dart';
import 'food_model.dart';

class FoodRepository {
  const FoodRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FoodModel>> searchFoods({String? search}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/foods',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      final body = response.data;
      if (body == null) {
        return const [];
      }

      return FoodSearchResponse.fromJson(body).foods;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Nao foi possivel ler a lista de alimentos.',
      );
    }
  }

  Future<FoodModel> getFood(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/foods/$id',
      );

      final body = response.data;
      if (body == null) {
        throw const ApiException(message: 'Alimento nao encontrado.');
      }

      return FoodModel.fromJson(body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(message: 'Nao foi possivel ler o alimento.');
    }
  }
}
