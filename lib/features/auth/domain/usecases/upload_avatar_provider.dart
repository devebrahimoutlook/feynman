import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/profile_provider.dart';
import 'package:feynman/features/auth/domain/usecases/upload_avatar.dart';

part 'upload_avatar_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
UploadAvatar uploadAvatar(UploadAvatarRef ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UploadAvatar(repository);
}
