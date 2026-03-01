import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpWithEmail usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignUpWithEmail(mockAuthRepository);
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

  test('should return UserProfile when sign up is successful', () async {
    when(
      () => mockAuthRepository.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => tUserProfile);

    final result = await usecase(email: tEmail, password: tPassword);

    expect(result, equals(tUserProfile));
    verify(
      () => mockAuthRepository.signUpWithEmail(
        email: tEmail,
        password: tPassword,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should throw an exception when sign up fails', () async {
    when(
      () => mockAuthRepository.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Account already exists'));

    expect(
      () => usecase(email: tEmail, password: tPassword),
      throwsA(isA<Exception>()),
    );
  });
}
