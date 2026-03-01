import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email.dart';

final signInWithEmailProvider = Provider((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});
