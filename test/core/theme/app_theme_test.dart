import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feynman/core/theme/app_theme.dart';
import 'package:feynman/core/theme/app_spacing.dart';

void main() {
  group('AppTheme', () {
    test('light theme has correct primary colour seed', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('dark theme has correct primary colour seed', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('spacing constants are defined', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
      expect(AppSpacing.xxxl, 48.0);
      expect(AppSpacing.xxxxl, 64.0);
    });

    test('border radii are defined', () {
      expect(AppSpacing.radiusSm, 8.0);
      expect(AppSpacing.radiusMd, 12.0);
      expect(AppSpacing.radiusLg, 16.0);
      expect(AppSpacing.radiusXl, 24.0);
    });
  });
}
