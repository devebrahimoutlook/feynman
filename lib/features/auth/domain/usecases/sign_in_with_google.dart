import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  Future<UserProfile> call() async {
    return await _repository.signInWithGoogle();
  }
}
