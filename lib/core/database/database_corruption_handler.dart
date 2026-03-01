import 'package:drift/native.dart';
import 'package:feynman/core/logging/app_logger.dart';
import 'package:feynman/core/database/app_database.dart';

enum CorruptionRecoveryOption { resyncFromRemote, startFresh }

abstract class DatabaseCorruptionHandler {
  Future<CorruptionRecoveryOption?> handleCorruption(Exception error);

  /// Returns `true` if [error] indicates an irrecoverable SQLite corruption.
  ///
  /// Covers SQLite error strings: "malformed", "disk image is malformed",
  /// "database disk image", "not a database", as well as generic corruption,
  /// migration, and schema keywords. (spec 001 edge case; spec 003 T035)
  static bool isCorruptionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('malformed') ||
        msg.contains('disk image') ||
        msg.contains('not a database') ||
        msg.contains('corrupt') ||
        msg.contains('database') ||
        msg.contains('sqlite') ||
        msg.contains('migration') ||
        msg.contains('schema');
  }
}

class DefaultDatabaseCorruptionHandler implements DatabaseCorruptionHandler {
  final void Function(String message) onRecoveryDialog;
  final AppLogger? logger;

  DefaultDatabaseCorruptionHandler({
    required this.onRecoveryDialog,
    this.logger,
  });

  @override
  Future<CorruptionRecoveryOption?> handleCorruption(Exception error) async {
    if (!DatabaseCorruptionHandler.isCorruptionError(error)) {
      throw error;
    }

    logger?.fatal(
      'DatabaseCorruptionHandler',
      'Irrecoverable database corruption detected — prompting recovery',
      error,
    );

    onRecoveryDialog(
      'Database corruption detected. Would you like to:\n'
      '1. Re-sync from remote (retain local changes not yet synced)\n'
      '2. Start fresh (clear local data and re-download)',
    );

    return null;
  }
}

Future<AppDatabase> openDatabaseWithCorruptionHandling({
  required DatabaseCorruptionHandler handler,
}) async {
  try {
    return AppDatabase(NativeDatabase.memory());
  } catch (e) {
    final exception = e is Exception ? e : Exception(e.toString());
    final recoveryOption = await handler.handleCorruption(exception);
    if (recoveryOption == CorruptionRecoveryOption.startFresh) {
      return AppDatabase(NativeDatabase.memory());
    }
    rethrow;
  }
}
