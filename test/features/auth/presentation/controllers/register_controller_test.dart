import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email_provider.dart';
import 'package:feynman/features/auth/presentation/controllers/register_controller.dart';
import 'package:feynman/core/error/app_exception.dart';

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

void main() {
  late MockSignUpWithEmail mockSignUp;
  late ProviderContainer container;

  setUp(() {
    mockSignUp = MockSignUpWithEmail();
    container = ProviderContainer(
      overrides: [signUpWithEmailProvider.overrideWithValue(mockSignUp)],
    );
  });

  tearDown(() {
    container.dispose();
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

  test('initial state is AsyncData(null)', () {
    final state = container.read(registerControllerProvider);
    expect(state, const AsyncData<void>(null));
  });

  test('register() emits loading then data on success', () async {
    when(
      () => mockSignUp.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => tUserProfile);

    final controller = container.read(registerControllerProvider.notifier);

    expect(
      container.listen(registerControllerProvider, (_, __) {}).read(),
      const AsyncData<void>(null),
    );

    final future = controller.register(email: tEmail, password: tPassword);

    expect(container.read(registerControllerProvider).isLoading, isTrue);

    await future;

    expect(
      container.read(registerControllerProvider),
      const AsyncData<void>(null),
    );
    verify(() => mockSignUp.call(email: tEmail, password: tPassword)).called(1);
  });

  test('register() emits error on failure (e.g. Account exists)', () async {
    const tException = AuthException(message: 'Account exists — please log in');
    when(
      () => mockSignUp.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(tException);

    final controller = container.read(registerControllerProvider.notifier);

    await controller.register(email: tEmail, password: tPassword);

    expect(container.read(registerControllerProvider).hasError, isTrue);
    expect(
      container.read(registerControllerProvider).error,
      equals(tException),
    );
  });
}
