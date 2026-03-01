// ignore_for_file: avoid_build_context_in_providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:feynman/core/providers/supabase_provider.dart';
import 'package:feynman/core/providers/logger_provider.dart';
import 'package:feynman/core/providers/database_provider.dart';
import 'package:feynman/features/auth/domain/entities/auth_state.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

import 'package:feynman/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:feynman/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/features/auth/data/repositories/auth_repository_impl.dart';

const _tag = 'AuthNotifier';

/// Riverpod [AsyncNotifier] for authentication state.
///
/// Constitution V: [AuthState] is a freezed immutable union.
/// Constitution VIII: Every state transition is logged at the domain boundary.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final client = ref.read(supabaseProvider);
    final logger = ref.read(loggerProvider);

    if (client == null) {
      logger.warning(_tag, 'Supabase not initialized — unauthenticated');
      return const AuthState.unauthenticated();
    }

    // Restore existing session on startup
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      logger.info(_tag, 'Existing session restored on startup');
      return AuthState.authenticated(user: _profileFromUser(currentUser));
    }

    // Subscribe to ongoing auth events
    client.auth.onAuthStateChange.listen(
      (event) {
        final su = event.session?.user;
        if (su != null) {
          logger.info(_tag, 'Auth → authenticated (${event.event.name})');
          state = AsyncData(
            AuthState.authenticated(user: _profileFromUser(su)),
          );
        } else {
          logger.info(_tag, 'Auth → unauthenticated (${event.event.name})');
          state = const AsyncData(AuthState.unauthenticated());
          ref.read(databaseProvider).clearAllData().catchError((
            Object e,
            StackTrace st,
          ) {
            logger.error(_tag, 'Failed to clear local data on sign out', e, st);
          });
        }
      },
      // C01 remediation: token refresh failure caught here
      onError: (Object e, StackTrace st) {
        logger.error(_tag, 'Auth stream error — forcing login redirect', e, st);
        state = const AsyncData(
          AuthState.error(message: 'Session expired. Please sign in again.'),
        );
      },
    );

    return const AuthState.unauthenticated();
  }

  /// Updates the current user profile in the state without requiring a full re-auth.
  void updateProfile(UserProfile profile) {
    state = AsyncData(AuthState.authenticated(user: profile));
  }

  /// Maps a Supabase [User] object to our domain [UserProfile].
  UserProfile _profileFromUser(User user) {
    final meta = user.userMetadata ?? {};
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: meta['full_name'] as String?,
      avatarUrl: meta['avatar_url'] as String?,
      authProvider: (user.appMetadata['provider'] as String?) ?? 'email',
      emailVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: DateTime.now(),
    );
  }
}

/// The primary auth state provider. All UI observes this.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Convenience: `true` when there is a valid authenticated session.
///
/// Used by the GoRouter guard and protected widgets.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref
      .watch(authStateProvider)
      .when(
        data: (s) => s.map(
          unauthenticated: (_) => false,
          loading: (_) => false,
          authenticated: (_) => true,
          error: (_) => false,
        ),
        loading: () => false,
        error: (_, __) => false,
      );
});

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final supabase = ref.watch(supabaseProvider);
  if (supabase == null) throw Exception('Supabase not initialized');
  return AuthRemoteDatasourceImpl(supabase);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
    ref.watch(loggerProvider),
  );
});
