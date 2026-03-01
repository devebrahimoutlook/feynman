import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// Domain entity for the authenticated user's profile.
///
/// Extends the 001-Foundation UserProfile concept by adding [authProvider]
/// and [emailVerified], as per the 002-auth data model.
///
/// Constitution I: zero framework imports (no Flutter, no Supabase SDK).
/// Constitution V: @freezed immutable value object.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default(1) int level,
    @Default(0) int totalXp,
    @Default('email') String authProvider,
    @Default(false) bool emailVerified,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
