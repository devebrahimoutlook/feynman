import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email_provider.dart';
import 'package:feynman/features/auth/presentation/controllers/login_controller.dart';
import 'package:feynman/core/error/app_exception.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

void main() {
  late MockSignInWithEmail mockSignIn;
  late ProviderContainer container;

  setUp(() {
    mockSignIn = MockSignInWithEmail();
    container = ProviderContainer(
      overrides: [signInWithEmailProvider.overrideWithValue(mockSignIn)],
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
    final state = container.read(loginControllerProvider);
    expect(state, const AsyncData<void>(null));
  });

  test('login() emits loading then data on success', () async {
    when(
      () => mockSignIn.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => tUserProfile);

    final controller = container.read(loginControllerProvider.notifier);

    expect(
      container.listen(loginControllerProvider, (_, __) {}).read(),
      const AsyncData<void>(null),
    );

    final future = controller.login(email: tEmail, password: tPassword);

    expect(container.read(loginControllerProvider).isLoading, isTrue);

    await future;

    expect(
      container.read(loginControllerProvider),
      const AsyncData<void>(null),
    );
    verify(() => mockSignIn.call(email: tEmail, password: tPassword)).called(1);
  });

  test('login() emits error on failure', () async {
    const tException = AuthException(message: 'Invalid credentials');
    when(
      () => mockSignIn.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(tException);

    final controller = container.read(loginControllerProvider.notifier);

    await controller.login(email: tEmail, password: tPassword);

    expect(container.read(loginControllerProvider).hasError, isTrue);
    expect(container.read(loginControllerProvider).error, equals(tException));
  });
}
