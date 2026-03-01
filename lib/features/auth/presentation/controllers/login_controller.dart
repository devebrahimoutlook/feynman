import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email_provider.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_google_provider.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {}

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(signInWithEmailProvider);
      await usecase(email: email, password: password);
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(signInWithGoogleProvider);
      await usecase();
    });
  }
}
