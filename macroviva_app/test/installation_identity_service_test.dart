import 'package:flutter_test/flutter_test.dart';
import 'package:macroviva_app/core/identity/installation_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const firstId = '11111111-1111-4111-8111-111111111111';
  const secondId = '22222222-2222-4222-8222-222222222222';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'generates and persists an installation UUID when storage is empty',
    () async {
      final service = InstallationIdentityService(uuidGenerator: () => firstId);

      final installationId = await service.getOrCreateId();
      final preferences = await SharedPreferences.getInstance();

      expect(installationId, firstId);
      expect(
        preferences.getString(InstallationIdentityService.storageKey),
        firstId,
      );
    },
  );

  test('reuses a valid persisted UUID', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      InstallationIdentityService.storageKey: firstId,
    });
    final service = InstallationIdentityService(uuidGenerator: () => secondId);

    expect(await service.getOrCreateId(), firstId);
  });

  test('replaces an invalid persisted value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      InstallationIdentityService.storageKey: 'not-a-uuid',
    });
    final service = InstallationIdentityService(uuidGenerator: () => secondId);

    expect(await service.getOrCreateId(), secondId);
  });

  test('caches one UUID across repeated and concurrent calls', () async {
    var generatedCount = 0;
    final service = InstallationIdentityService(
      uuidGenerator: () {
        generatedCount++;
        return firstId;
      },
    );

    final values = await Future.wait(<Future<String>>[
      service.getOrCreateId(),
      service.getOrCreateId(),
      service.getOrCreateId(),
    ]);

    expect(values, <String>[firstId, firstId, firstId]);
    expect(generatedCount, 1);
  });
}
