import 'package:feynman/features/auth/domain/entities/user_profile.dart';

abstract class AuthRemoteDatasource {
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signInWithGoogle();

  Future<UserProfile?> getCurrentUser();

  Future<void> signOut();

  Future<void> resetPassword({required String email});
}
