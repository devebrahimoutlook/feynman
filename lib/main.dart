import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:feynman/app.dart';
import 'package:feynman/core/config/app_config.dart';
import 'package:feynman/core/logging/app_logger.dart';
import 'package:feynman/core/providers/logger_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:feynman/core/storage/secure_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();

  final logger = AppLogger(isDebug: kDebugMode);

  // Initialize Supabase with graceful fallback (FR-007)
  if (AppConfig.isConfigured) {
    AppConfig.validate(); // Throws descriptive StateError if misconfigured
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureLocalStorage(const FlutterSecureStorage()),
        ),
      );
      logger.info('Main', 'Supabase initialized successfully');
    } catch (e, st) {
      logger.error('Main', 'Supabase init failed — offline mode', e, st);
    }
  } else {
    logger.warning(
      'Main',
      'Supabase credentials not configured — offline mode',
    );
  }

  // Global Flutter framework error handler
  FlutterError.onError = (details) {
    logger.error(
      'FlutterError',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    // Default behavior: in debug mode, dump to console
    FlutterError.presentError(details);
  };

  // Global async/platform error handler
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.fatal('PlatformDispatcher', 'Uncaught async error', error, stack);
    return true; // Prevents app crash
  };

  runApp(
    ProviderScope(
      overrides: [loggerProvider.overrideWithValue(logger)],
      child: const FeynmanApp(),
    ),
  );
}
