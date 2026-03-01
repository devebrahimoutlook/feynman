import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email_provider.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_google_provider.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  FutureOr<void> build() {}

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(signUpWithEmailProvider);
      await usecase(email: email, password: password);
    });
  }

  Future<void> registerWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(signInWithGoogleProvider);
      await usecase();
    });
  }
}
