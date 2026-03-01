import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/presentation/screens/login_screen.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:feynman/features/auth/domain/usecases/sign_in_with_email_provider.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

void main() {
  late MockSignInWithEmail mockSignIn;

  setUp(() {
    mockSignIn = MockSignInWithEmail();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [signInWithEmailProvider.overrideWithValue(mockSignIn)],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('displays email and password fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('calls sign in provider on valid submit', (tester) async {
    when(
      () => mockSignIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => UserProfile(
        id: '123',
        email: 'test@example.com',
        authProvider: 'email',
        emailVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    verify(
      () => mockSignIn(email: 'test@example.com', password: 'password123'),
    ).called(1);
  });
}
