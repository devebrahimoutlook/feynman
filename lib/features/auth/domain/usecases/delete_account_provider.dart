import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/profile_provider.dart';
import 'package:feynman/features/auth/domain/usecases/delete_account.dart';

part 'delete_account_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
DeleteAccount deleteAccount(DeleteAccountRef ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return DeleteAccount(repository);
}
