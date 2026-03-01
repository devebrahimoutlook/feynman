import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  Future<UserProfile> call({required String email, required String password}) {
    return repository.signUpWithEmail(email: email, password: password);
  }
}
