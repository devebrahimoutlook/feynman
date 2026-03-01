import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/error/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ErrorBoundary(child: Text('Test'))),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('shows fallback screen when child throws', (tester) async {
      // Suppress expected Flutter build errors from intentional throws
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  throw Exception('Test error');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      FlutterError.onError = FlutterError.presentError;

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry re-renders child after error is cleared', (
      tester,
    ) async {
      var shouldThrow = true;

      // Suppress expected Flutter build errors from intentional throws
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) => errors.add(details);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return ErrorBoundary(
                  child: Builder(
                    builder: (context) {
                      if (shouldThrow) throw Exception('Test error');
                      return const Text('Recovered');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Error state is visible
      expect(find.text('Something went wrong'), findsOneWidget);

      // Restore error handler before the retry (no more expected throws)
      shouldThrow = false;
      FlutterError.onError = FlutterError.presentError;

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered'), findsOneWidget);
    });
  });
}
