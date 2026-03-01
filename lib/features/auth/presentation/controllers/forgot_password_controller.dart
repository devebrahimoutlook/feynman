import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/features/auth/domain/usecases/reset_password_provider.dart';

part 'forgot_password_controller.g.dart';

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  FutureOr<void> build() {}

  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(resetPasswordProvider);
      await usecase(email: email);
    });
  }
}
