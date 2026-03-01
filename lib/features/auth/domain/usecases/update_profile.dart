import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';

/// Usecase for updating the user profile.
class UpdateProfile {
  final ProfileRepository _repository;

  const UpdateProfile(this._repository);

  Future<UserProfile> call({String? displayName, String? avatarUrl}) async {
    return _repository.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
