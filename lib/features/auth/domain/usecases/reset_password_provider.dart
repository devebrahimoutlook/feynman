import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/domain/usecases/reset_password.dart';

part 'reset_password_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
ResetPassword resetPassword(ResetPasswordRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPassword(repository);
}
