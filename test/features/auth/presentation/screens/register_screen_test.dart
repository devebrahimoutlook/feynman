import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/presentation/screens/register_screen.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:feynman/features/auth/domain/usecases/sign_up_with_email_provider.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:feynman/core/router/route_names.dart';

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

void main() {
  late MockSignUpWithEmail mockSignUp;

  setUp(() {
    mockSignUp = MockSignUpWithEmail();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const RegisterScreen()),
        GoRoute(
          path: '/verify-email',
          name: RouteNames.verifyEmail,
          builder: (context, state) =>
              const Scaffold(body: Text('Verify Email')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [signUpWithEmailProvider.overrideWithValue(mockSignUp)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('displays register fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Email, Password, Confirm Password
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('shows validation error for mismatched passwords', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'password456');

    final registerButton = find.widgetWithText(ElevatedButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('calls register provider on valid submit', (tester) async {
    when(
      () => mockSignUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => UserProfile(
        id: '123',
        email: 'test@example.com',
        authProvider: 'email',
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');

    // Tap register button
    final registerButton = find.widgetWithText(ElevatedButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    verify(
      () => mockSignUp(email: 'test@example.com', password: 'password123'),
    ).called(1);
  });
}
