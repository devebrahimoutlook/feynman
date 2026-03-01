import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient supabaseClient;

  AuthRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('User not found');
    }

    return _mapUser(response.user!);
  }

  @override
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Registration failed');
    }

    return _mapUser(response.user!);
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    final googleSignIn = google.GoogleSignIn(scopes: ['email', 'profile']);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign in aborted by user');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw const AuthException('No tracking or ID Token found from Google');
    }

    final response = await supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.user == null) {
      throw const AuthException('Unexpected error during Supabase Google auth');
    }

    return _mapUser(response.user!);
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.feynman.app://reset-password',
    );
  }

  UserProfile _mapUser(User user) {
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
