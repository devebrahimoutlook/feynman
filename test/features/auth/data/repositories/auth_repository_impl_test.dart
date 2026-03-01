import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/core/error/app_exception.dart';
import 'package:feynman/core/logging/app_logger.dart';
import 'package:feynman/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:feynman/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDatasource mockRemoteDatasource;
  late MockAppLogger mockLogger;

  setUp(() {
    mockRemoteDatasource = MockAuthRemoteDatasource();
    mockLogger = MockAppLogger();
    repository = AuthRepositoryImpl(mockRemoteDatasource, mockLogger);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tUserProfile = UserProfile(
    id: 'user_id',
    email: tEmail,
    authProvider: 'email',
    emailVerified: false,
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
  );

  group('signInWithEmail', () {
    test('should return UserProfile when sign in successful', () async {
      when(
        () => mockRemoteDatasource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserProfile);

      final result = await repository.signInWithEmail(
        email: tEmail,
        password: tPassword,
      );

      expect(result, equals(tUserProfile));
      verify(
        () => mockRemoteDatasource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should throw AuthException when sign in fails', () async {
      when(
        () => mockRemoteDatasource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const supa.AuthException('Invalid login credentials'));

      expect(
        () => repository.signInWithEmail(email: tEmail, password: tPassword),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUpWithEmail', () {
    test('should return UserProfile when sign up is successful', () async {
      when(
        () => mockRemoteDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserProfile);

      final result = await repository.signUpWithEmail(
        email: tEmail,
        password: tPassword,
      );

      expect(result, equals(tUserProfile));

      verify(
        () => mockRemoteDatasource.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test(
      'T017a: should throw user-friendly AuthException on EC-001 (User already registered)',
      () async {
        when(
          () => mockRemoteDatasource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const supa.AuthException('User already registered'));

        expect(
          () => repository.signUpWithEmail(email: tEmail, password: tPassword),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Account exists — please log in',
            ),
          ),
        );
      },
    );

    test(
      'should throw generic AuthException for other AuthExceptions',
      () async {
        when(
          () => mockRemoteDatasource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const supa.AuthException('Weak password'));

        expect(
          () => repository.signUpWithEmail(email: tEmail, password: tPassword),
          throwsA(isA<AuthException>()),
        );
      },
    );
  });

  group('signInWithGoogle', () {
    test(
      'should return UserProfile when Google sign in is successful',
      () async {
        when(
          () => mockRemoteDatasource.signInWithGoogle(),
        ).thenAnswer((_) async => tUserProfile);

        final result = await repository.signInWithGoogle();

        expect(result, equals(tUserProfile));
        verify(() => mockRemoteDatasource.signInWithGoogle()).called(1);
      },
    );

    test('should throw AuthException when Google sign in fails', () async {
      when(
        () => mockRemoteDatasource.signInWithGoogle(),
      ).thenThrow(const supa.AuthException('Google sign in aborted'));

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
