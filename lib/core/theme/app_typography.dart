import 'package:flutter/material.dart';

/// App typography using the default Material 3 text theme.
/// No external font packages — fonts load instantly, no HTTP, no caching issues.
class AppTypography {
  static final TextTheme lightTextTheme = ThemeData.light().textTheme;
  static final TextTheme darkTextTheme = ThemeData.dark().textTheme;
}
