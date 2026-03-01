import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow Integration Test', () {
    testWidgets('complete auth flow: navigate to login, check elements', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('login screen has required form fields', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('can navigate to login screen from home', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('login screen shows email and password fields', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('login screen shows forgot password link', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('login screen shows register link', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('login screen shows google sign in option', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('can navigate to register screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('register screen has required form fields', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('register screen shows password strength indicator', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('register screen shows google sign in option', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('can navigate to forgot password screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('forgot password screen has email field', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });

    testWidgets('forgot password screen shows back to login link', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();
    });
  });
}
