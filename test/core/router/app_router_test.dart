import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/router/app_router.dart';
import 'package:feynman/core/router/route_names.dart';

void main() {
  group('AppRouter', () {
    test('router is created successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isNotNull);
    });

    test('router has correct initial location', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(
        router.routeInformationProvider.value.uri.path,
        RouteNames.homePath,
      );
    });
  });
}
