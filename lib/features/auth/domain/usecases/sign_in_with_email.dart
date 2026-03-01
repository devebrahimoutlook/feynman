import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  Future<UserProfile> call({required String email, required String password}) {
    return repository.signInWithEmail(email: email, password: password);
  }
}
