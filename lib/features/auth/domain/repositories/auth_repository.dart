import 'package:feynman/features/auth/domain/entities/auth_state.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

/// Abstract repository contract for authentication operations.
///
/// Constitution I: pure domain interface — NO framework or SDK imports.
/// The Data layer provides the concrete implementation via Riverpod DI.
abstract interface class AuthRepository {
  /// Emits the current [AuthState] and any subsequent changes.
  Stream<AuthState> get authStateChanges;

  /// Signs in with [email] and [password].
  ///
  /// Returns the authenticated [UserProfile] on success.
  /// Throws [AuthException] on failure.
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with [email] and [password].
  ///
  /// Triggers an email verification; the user must verify before logging in.
  /// Returns the newly created [UserProfile].
  /// Throws [AuthException] on failure.
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Initiates Google OAuth sign-in.
  ///
  /// On Android, uses the native Google Sign-In SDK and exchanges the
  /// ID token with Supabase (`signInWithIdToken`).
  /// On Web, redirects via `signInWithOAuth`.
  /// Returns the authenticated [UserProfile].
  Future<UserProfile> signInWithGoogle();

  /// Sends a password-reset email to [email].
  ///
  /// Does NOT reveal whether the address corresponds to an existing account.
  Future<void> resetPassword({required String email});

  /// Returns the currently authenticated [UserProfile], or `null` if not
  /// authenticated.
  Future<UserProfile?> getCurrentUser();

  /// Signs out the current user and clears all local auth tokens.
  Future<void> signOut();
}
