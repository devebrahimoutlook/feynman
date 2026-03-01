import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/features/auth/domain/usecases/sign_out.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOut usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignOut(mockAuthRepository);
  });

  test('should call signOut on the repository', () async {
    when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

    await usecase();

    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should throw when repository throws', () async {
    when(
      () => mockAuthRepository.signOut(),
    ).thenThrow(Exception('Network error'));

    expect(() => usecase(), throwsA(isA<Exception>()));
  });
}
