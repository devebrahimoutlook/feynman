import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository _repository;

  ResetPassword(this._repository);

  Future<void> call({required String email}) {
    return _repository.resetPassword(email: email);
  }
}
