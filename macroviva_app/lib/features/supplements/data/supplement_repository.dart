import '../../../core/errors/api_exception.dart';
import '../../../core/http/api_client.dart';
import 'supplement_model.dart';
import 'user_supplement_model.dart';

class SupplementRepository {
  const SupplementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SupplementModel>> getSupplements() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/api/supplements');
      final body = response.data;

      if (body == null) {
        return const [];
      }

      return body
          .whereType<Map<String, dynamic>>()
          .map(SupplementModel.fromJson)
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Nao foi possivel ler a lista de suplementos.',
      );
    }
  }

  Future<UserSupplementModel> checkIn({
    required String supplementId,
    required DateTime checkInDate,
    required double servings,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/user-supplements/check-in',
        data: {
          'supplementId': supplementId,
          'checkInDate': _dateOnly(checkInDate),
          'servings': servings,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ApiException(
          message: 'Check-in criado, mas a resposta veio vazia.',
        );
      }

      return UserSupplementModel.fromJson(body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Nao foi possivel registrar o check-in.',
      );
    }
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
