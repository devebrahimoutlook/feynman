import 'dart:io';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';

/// Usecase for uploading a user avatar to Storage.
class UploadAvatar {
  final ProfileRepository _repository;

  const UploadAvatar(this._repository);

  /// Uploads [imageFile] and returns the public URL.
  Future<String> call(File imageFile) async {
    return _repository.uploadAvatar(imageFile);
  }
}
