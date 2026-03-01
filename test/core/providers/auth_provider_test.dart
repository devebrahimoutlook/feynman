import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/core/providers/supabase_provider.dart';
import 'package:feynman/core/providers/logger_provider.dart';
import 'package:feynman/core/logging/app_logger.dart';
import 'package:feynman/features/auth/domain/entities/auth_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late ProviderContainer container;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockAppLogger mockLogger;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockLogger = MockAppLogger();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabaseClient),
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );
  });

  group('AuthNotifier Session Initialization', () {
    test('initializes as unauthenticated when no session exists', () async {
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      // We wait for the first state since it's an AsyncNotifier
      final state = await container.read(authStateProvider.future);

      expect(state, const AuthState.unauthenticated());
      verifyNever(
        () => mockLogger.info(
          any(),
          'Auth → unauthenticated (AuthChangeEvent.initialSession)',
        ),
      );
    });

    test('initializes as authenticated when session exists', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(
        () => mockUser.createdAt,
      ).thenReturn(DateTime(2023).toIso8601String());
      when(() => mockUser.userMetadata).thenReturn({});
      when(() => mockUser.appMetadata).thenReturn({'provider': 'email'});
      when(() => mockUser.emailConfirmedAt).thenReturn(null);

      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);

      final state = await container.read(authStateProvider.future);

      state.maybeWhen(
        authenticated: (user) {
          expect(user.id, 'user-123');
          expect(user.email, 'test@example.com');
        },
        orElse: () => fail('Expected AuthState.authenticated'),
      );

      verify(
        () => mockLogger.info(any(), 'Existing session restored on startup'),
      ).called(1);
    });
  });
}
