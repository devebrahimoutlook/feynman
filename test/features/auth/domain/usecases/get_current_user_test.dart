import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/features/auth/domain/usecases/get_current_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockRepository);
  });

  group('GetCurrentUser', () {
    const tUserId = 'user-123';
    final tUserProfile = UserProfile(
      id: tUserId,
      email: 'test@example.com',
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
    );

    test(
      'should return UserProfile from repository when authenticated',
      () async {
        // arrange
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => tUserProfile);

        // act
        final result = await usecase();

        // assert
        expect(result, equals(tUserProfile));
        verify(() => mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should return null from repository when unauthenticated', () async {
      // arrange
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);

      // act
      final result = await usecase();

      // assert
      expect(result, isNull);
      verify(() => mockRepository.getCurrentUser()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
