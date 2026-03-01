import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/domain/usecases/get_current_user.dart';

part 'get_current_user_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
GetCurrentUser getCurrentUser(GetCurrentUserRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUser(repository);
}
