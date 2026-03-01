import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:feynman/core/error/app_exception.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';
import 'package:feynman/features/auth/data/datasources/profile_local_datasource.dart';
import 'package:feynman/features/auth/data/datasources/profile_remote_datasource.dart';
import 'package:feynman/core/logging/app_logger.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource localDatasource;
  final ProfileRemoteDatasource remoteDatasource;
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  ProfileRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.supabaseClient,
    required this.logger,
  });

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User session not found');
    }

    try {
      // Try remote update first
      final updatedProfile = await remoteDatasource.updateProfile(
        userId: user.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      // Persist to local cache
      await localDatasource.saveProfile(updatedProfile);
      logger.info('ProfileRepository', 'Profile updated remotely & locally', {
        'id': user.id,
      });
      return updatedProfile;
    } catch (e) {
      // Offline-first: if remote fails, update local if record exists
      final currentLocal = await localDatasource.getProfile(user.id);
      if (currentLocal != null) {
        final newLocal = currentLocal.copyWith(
          displayName: displayName ?? currentLocal.displayName,
          avatarUrl: avatarUrl ?? currentLocal.avatarUrl,
          updatedAt: DateTime.now(),
        );
        await localDatasource.saveProfile(newLocal);
        logger.warning(
          'ProfileRepository',
          'Profile updated locally (offline)',
          {'id': user.id},
        );
        // In a real app, we'd add this to a sync queue here.
        return newLocal;
      }

      // If no local record and remote fails, we must rethrow
      logger.error(
        'ProfileRepository',
        'Profile update failed (no local fallback)',
        e,
      );
      if (e is AuthException) rethrow;
      throw AuthException(message: e.toString(), cause: e);
    }
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User session not found');
    }

    try {
      final extension = imageFile.path.split('.').last;
      final publicUrl = await remoteDatasource.uploadAvatar(
        userId: user.id,
        imageFile: imageFile,
        extension: extension,
      );

      // After successful upload, update the profile record with the new URL
      await updateProfile(avatarUrl: publicUrl);

      logger.info('ProfileRepository', 'Avatar uploaded', {'url': publicUrl});
      return publicUrl;
    } catch (e, st) {
      logger.error('ProfileRepository', 'Avatar upload failed', e, st);
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to upload avatar: $e', cause: e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'User session not found');
    }

    try {
      await remoteDatasource.deleteAccount(userId: user.id);
      await localDatasource.clearProfile(user.id);
      await supabaseClient.auth.signOut();
      logger.info('ProfileRepository', 'Account deleted successfully', {
        'id': user.id,
      });
    } catch (e, st) {
      logger.error('ProfileRepository', 'Account deletion failed', e, st);
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Failed to delete account: $e', cause: e);
    }
  }
}
