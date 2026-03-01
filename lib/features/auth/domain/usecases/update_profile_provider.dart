import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/profile_provider.dart';
import 'package:feynman/features/auth/domain/usecases/update_profile.dart';

part 'update_profile_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
UpdateProfile updateProfile(UpdateProfileRef ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfile(repository);
}
