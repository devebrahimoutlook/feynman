import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmail usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithEmail(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tUserProfile = UserProfile(
    id: 'user_id',
    email: tEmail,
    authProvider: 'email',
    emailVerified: true,
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
  );

  test('should return UserProfile when sign in is successful', () async {
    when(
      () => mockAuthRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => tUserProfile);

    final result = await usecase(email: tEmail, password: tPassword);

    expect(result, equals(tUserProfile));
    verify(
      () => mockAuthRepository.signInWithEmail(
        email: tEmail,
        password: tPassword,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should throw an exception when sign in fails', () async {
    when(
      () => mockAuthRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Invalid credentials'));

    expect(
      () => usecase(email: tEmail, password: tPassword),
      throwsA(isA<Exception>()),
    );
  });
}
