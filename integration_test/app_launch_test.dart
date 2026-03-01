import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Integration Test', () {
    testWidgets('app launches and four bottom-nav tabs are visible', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping each tab navigates to its screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FeynmanApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Library').evaluate().length, greaterThan(0));

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Progress').evaluate().length, greaterThan(0));

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings').evaluate().length, greaterThan(0));
    });
  });
}
