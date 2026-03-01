import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/domain/usecases/sign_out.dart';

part 'sign_out_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
SignOut signOut(SignOutRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
}
