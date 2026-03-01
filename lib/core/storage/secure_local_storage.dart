import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _secureStorage;

  SecureLocalStorage(this._secureStorage);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return _secureStorage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return _secureStorage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: supabasePersistSessionKey);
  }
}
