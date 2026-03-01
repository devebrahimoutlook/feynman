import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/features/auth/domain/usecases/reset_password.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetPassword usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = ResetPassword(mockAuthRepository);
  });

  const tEmail = 'test@example.com';

  test('should call resetPassword on the repository', () async {
    when(
      () => mockAuthRepository.resetPassword(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    await usecase(email: tEmail);

    verify(() => mockAuthRepository.resetPassword(email: tEmail)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should throw when repository throws', () async {
    when(
      () => mockAuthRepository.resetPassword(email: any(named: 'email')),
    ).thenThrow(Exception('Network error'));

    expect(() => usecase(email: tEmail), throwsA(isA<Exception>()));
  });
}
