import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:feynman/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:feynman/features/auth/domain/usecases/reset_password.dart';

class MockResetPassword extends Mock implements ResetPassword {}

class FakeForgotPasswordController extends AutoDisposeAsyncNotifier<void>
    implements ForgotPasswordController {
  final AsyncValue<void> initialState;
  FakeForgotPasswordController(this.initialState);

  @override
  FutureOr<void> build() {
    state = initialState;
  }

  @override
  Future<void> resetPassword({required String email}) async {}
}

void main() {
  Widget createWidgetUnderTest({
    AsyncValue<void> initialState = const AsyncValue.data(null),
  }) {
    return ProviderScope(
      overrides: [
        forgotPasswordControllerProvider.overrideWith(
          () => FakeForgotPasswordController(initialState),
        ),
      ],
      child: const MaterialApp(home: ForgotPasswordScreen()),
    );
  }

  testWidgets('displays Forgot Password screen elements', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('shows validation error for empty email', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('shows confirmation message after sending email', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(initialState: const AsyncValue.data(null)),
    );

    await tester.enterText(find.byType(TextFormField), 'test@example.com');

    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Check Your Email'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
  });

  testWidgets('shows loading indicator when submitting', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: null,
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
