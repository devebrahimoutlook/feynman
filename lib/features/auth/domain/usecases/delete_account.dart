import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';

class DeleteAccount {
  final ProfileRepository _repository;

  DeleteAccount(this._repository);

  Future<void> call() {
    return _repository.deleteAccount();
  }
}
