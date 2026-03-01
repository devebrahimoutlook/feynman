import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:feynman/core/storage/secure_local_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureLocalStorage secureLocalStorage;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    secureLocalStorage = SecureLocalStorage(mockSecureStorage);
  });

  group('SecureLocalStorage', () {
    const value = 'test_value';

    test('initialize does nothing', () async {
      // Supabase calls initialize() on custom local storage, we just need it to not crash.
      await expectLater(secureLocalStorage.initialize(), completes);
    });

    test('hasAccessToken returns true if token exists', () async {
      when(
        () => mockSecureStorage.containsKey(key: supabasePersistSessionKey),
      ).thenAnswer((_) async => true);

      final result = await secureLocalStorage.hasAccessToken();
      expect(result, isTrue);
      verify(
        () => mockSecureStorage.containsKey(key: supabasePersistSessionKey),
      ).called(1);
    });

    test('hasAccessToken returns false if token does not exist', () async {
      when(
        () => mockSecureStorage.containsKey(key: supabasePersistSessionKey),
      ).thenAnswer((_) async => false);

      final result = await secureLocalStorage.hasAccessToken();
      expect(result, isFalse);
    });

    test('accessToken returns value if it exists', () async {
      when(
        () => mockSecureStorage.read(key: supabasePersistSessionKey),
      ).thenAnswer((_) async => value);

      final result = await secureLocalStorage.accessToken();
      expect(result, value);
      verify(
        () => mockSecureStorage.read(key: supabasePersistSessionKey),
      ).called(1);
    });

    test('persistSession writes value to storage', () async {
      when(
        () => mockSecureStorage.write(
          key: supabasePersistSessionKey,
          value: value,
        ),
      ).thenAnswer((_) async {});

      await secureLocalStorage.persistSession(value);
      verify(
        () => mockSecureStorage.write(
          key: supabasePersistSessionKey,
          value: value,
        ),
      ).called(1);
    });

    test('removePersistedSession deletes value from storage', () async {
      when(
        () => mockSecureStorage.delete(key: supabasePersistSessionKey),
      ).thenAnswer((_) async {});

      await secureLocalStorage.removePersistedSession();
      verify(
        () => mockSecureStorage.delete(key: supabasePersistSessionKey),
      ).called(1);
    });
  });
}
