import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';
import 'package:feynman/features/auth/domain/usecases/delete_account.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late DeleteAccount usecase;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    usecase = DeleteAccount(mockProfileRepository);
  });

  test('should call deleteAccount on the repository', () async {
    when(() => mockProfileRepository.deleteAccount()).thenAnswer((_) async {});

    await usecase();

    verify(() => mockProfileRepository.deleteAccount()).called(1);
    verifyNoMoreInteractions(mockProfileRepository);
  });

  test('should throw when repository throws', () async {
    when(
      () => mockProfileRepository.deleteAccount(),
    ).thenThrow(Exception('Deletion failed'));

    expect(() => usecase(), throwsA(isA<Exception>()));
  });
}
