class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Validates that required build-time configuration is present.
  ///
  /// Throws [StateError] with a descriptive message when Supabase credentials
  /// are not injected via `--dart-define`, satisfying the spec requirement that
  /// missing configuration "MUST fail with a descriptive error message
  /// indicating which configuration values are missing" (spec.md edge cases).
  ///
  /// Guard with [isConfigured] before calling if running in intentional
  /// offline-only mode.
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      final missing = <String>[
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      ];
      throw StateError(
        'Missing required build-time configuration: ${missing.join(', ')}.\n'
        'Provide them via:\n'
        '  flutter run --dart-define=SUPABASE_URL=<url> '
        '--dart-define=SUPABASE_ANON_KEY=<key>\n'
        'For offline-only mode, guard with AppConfig.isConfigured before '
        'calling validate().',
      );
    }
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether the app should operate in offline-only mode.
  /// True when Supabase credentials are missing/empty.
  static bool get isOfflineMode => !isConfigured;
}
