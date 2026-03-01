import 'dart:io';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/features/auth/domain/usecases/update_profile_provider.dart';
import 'package:feynman/features/auth/domain/usecases/upload_avatar_provider.dart';
import 'package:feynman/core/providers/auth_provider.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {
    // Initial state is empty since data is managed by AuthNotifier
  }

  Future<void> updateDisplayName(String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(updateProfileProvider);
      final updatedProfile = await usecase(displayName: displayName);

      // Update session in AuthNotifier
      ref.read(authStateProvider.notifier).updateProfile(updatedProfile);
    });
  }

  Future<void> uploadAvatar(File imageFile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(uploadAvatarProvider);
      final url = await usecase(imageFile);

      // Updating profile happens inside uploadAvatar usecase,
      // but we need to update our AuthState with the latest profile now.
      // Easiest is to fetch profile again or just dispatch a change:
      final user = ref
          .read(authStateProvider)
          .value
          ?.mapOrNull(authenticated: (s) => s.user);
      if (user != null) {
        final newProfile = user.copyWith(avatarUrl: url);
        ref.read(authStateProvider.notifier).updateProfile(newProfile);
      }
    });
  }
}
