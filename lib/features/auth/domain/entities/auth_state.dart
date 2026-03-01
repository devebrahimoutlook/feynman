import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

part 'auth_state.freezed.dart';

/// Represents the current authentication status.
///
/// Constitution V: immutable freezed union with the async triad
/// (loading ≡ loading, data ≡ authenticated/unauthenticated, error ≡ error).
@freezed
class AuthState with _$AuthState {
  /// No session present or session expired.
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Checking for an existing session (app launch / refreshing token).
  const factory AuthState.loading() = _Loading;

  /// A valid session exists; [user] is the authenticated profile.
  const factory AuthState.authenticated({required UserProfile user}) =
      _Authenticated;

  /// Auth operation failed; [message] is user-facing.
  const factory AuthState.error({required String message}) = _AuthError;
}
