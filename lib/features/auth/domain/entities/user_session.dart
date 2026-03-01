import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_session.freezed.dart';

/// Domain representation of an active auth session.
///
/// Supabase manages sessions server-side; this entity is the local view used
/// in the domain layer only — it MUST NOT import Supabase SDK types.
///
/// Constitution I: zero framework imports.
/// Constitution V: @freezed immutable value object.
@freezed
class UserSession with _$UserSession {
  const factory UserSession({
    required String userId,
    required String authProvider,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    @Default(true) bool isActive,
  }) = _UserSession;

  const UserSession._();

  /// Returns true if the session token has passed its expiry timestamp.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
