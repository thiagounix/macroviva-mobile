import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client_provider.dart';
import '../data/supplement_model.dart';
import '../data/supplement_repository.dart';
import '../data/user_supplement_model.dart';

final supplementRepositoryProvider = Provider<SupplementRepository>((ref) {
  return SupplementRepository(ref.watch(apiClientProvider));
});

final supplementsProvider = FutureProvider.autoDispose<List<SupplementModel>>((
  ref,
) {
  return ref.watch(supplementRepositoryProvider).getSupplements();
});

final supplementCheckInControllerProvider =
    AsyncNotifierProvider<SupplementCheckInController, UserSupplementModel?>(
      SupplementCheckInController.new,
    );

class SupplementCheckInController extends AsyncNotifier<UserSupplementModel?> {
  @override
  Future<UserSupplementModel?> build() async {
    return null;
  }

  Future<UserSupplementModel> checkIn(String supplementId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(supplementRepositoryProvider);
      final result = await repository.checkIn(
        supplementId: supplementId,
        checkInDate: DateTime.now(),
        servings: 1,
      );

      state = AsyncData(result);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
