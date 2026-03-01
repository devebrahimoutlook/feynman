import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:feynman/core/providers/auth_provider.dart';

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});
