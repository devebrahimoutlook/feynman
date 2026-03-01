import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInWithGoogle usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInWithGoogle(mockRepository);
  });

  group('SignInWithGoogle', () {
    test('returns UserProfile from repository on success', () async {
      // Arrange
      final userProfile = UserProfile(
        id: '123',
        email: 'google@example.com',
        authProvider: 'google',
        emailVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => userProfile);

      // Act
      final result = await usecase();

      // Assert
      expect(result, equals(userProfile));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('rethrows exception from repository on failure', () async {
      // Arrange
      final exception = Exception('Google sign-in failed');
      when(() => mockRepository.signInWithGoogle()).thenThrow(exception);

      // Act & Assert
      expect(() => usecase(), throwsA(exception));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });
}
