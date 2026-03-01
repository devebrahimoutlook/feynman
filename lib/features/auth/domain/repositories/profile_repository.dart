import 'dart:io';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

/// Abstract contract for user profile management.
///
/// Handles updating profile information and uploading avatars.
abstract interface class ProfileRepository {
  /// Updates the authenticated user's profile.
  ///
  /// Only provided non-null fields will be updated.
  Future<UserProfile> updateProfile({String? displayName, String? avatarUrl});

  /// Uploads a new avatar image for the authenticated user to Storage.
  ///
  /// Returns the public URL of the uploaded image.
  Future<String> uploadAvatar(File imageFile);

  /// Permanently deletes the user's account and all associated data.
  ///
  /// This is an irreversible operation.
  Future<void> deleteAccount();
}
