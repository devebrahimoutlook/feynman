import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/core/error/app_exception.dart';

/// Remote datasource for user profile interactions with Supabase.
abstract interface class ProfileRemoteDatasource {
  /// Fetches the remote profile by [userId].
  Future<UserProfile> getProfile(String userId);

  /// Updates profile metadata on Supabase.
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  });

  /// Uploads an avatar image and returns its public URL.
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
    required String extension,
  });

  /// Deletes the user's account via Edge Function.
  Future<void> deleteAccount({required String userId});
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final SupabaseClient _supabase;

  const ProfileRemoteDatasourceImpl(this._supabase);

  @override
  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profile')
          .select()
          .eq('id', userId)
          .single();
      return _profileFromJson(response);
    } on PostgrestException catch (e) {
      throw AuthException(message: e.message, cause: e);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('user_profile')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return _profileFromJson(response);
    } on PostgrestException catch (e) {
      throw AuthException(message: e.message, cause: e);
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
    required String extension,
  }) async {
    try {
      final path = '$userId/profile.$extension';
      await _supabase.storage
          .from('avatars')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      // Append a timestamp to bypass CDN caching
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      throw AuthException(message: e.message, cause: e);
    }
  }

  @override
  Future<void> deleteAccount({required String userId}) async {
    try {
      await _supabase.functions.invoke(
        'delete-account',
        body: {'userId': userId},
      );
    } on PostgrestException catch (e) {
      throw AuthException(message: e.message, cause: e);
    } catch (e) {
      throw AuthException(message: 'Failed to delete account: $e', cause: e);
    }
  }

  UserProfile _profileFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      level: json['level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      authProvider: json['auth_provider'] as String? ?? 'email',
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
