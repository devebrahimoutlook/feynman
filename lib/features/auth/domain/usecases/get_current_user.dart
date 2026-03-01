import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';

/// Usecase to get the currently authenticated user profile.
class GetCurrentUser {
  final AuthRepository _repository;

  const GetCurrentUser(this._repository);

  /// Returns the current [UserProfile] or null if unauthenticated.
  Future<UserProfile?> call() async {
    return _repository.getCurrentUser();
  }
}
