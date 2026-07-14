import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InstallationIdentityService {
  InstallationIdentityService({
    Future<SharedPreferences> Function()? preferencesLoader,
    String Function()? uuidGenerator,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _uuidGenerator = uuidGenerator ?? const Uuid().v4;

  static const storageKey = 'macroviva.installation_id.v1';
  static const headerName = 'X-MacroViva-Tester-Id';

  static final RegExp _canonicalUuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final Future<SharedPreferences> Function() _preferencesLoader;
  final String Function() _uuidGenerator;
  Future<String>? _identityFuture;

  Future<String> getOrCreateId() {
    return _identityFuture ??= _loadOrCreateId();
  }

  Future<String> _loadOrCreateId() async {
    final preferences = await _preferencesLoader();
    final storedValue = preferences.getString(storageKey);

    if (storedValue != null && _canonicalUuidPattern.hasMatch(storedValue)) {
      return storedValue.toLowerCase();
    }

    final installationId = _uuidGenerator().toLowerCase();
    await preferences.setString(storageKey, installationId);
    return installationId;
  }
}
