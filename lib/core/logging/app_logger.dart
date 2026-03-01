import 'package:logger/logger.dart';

class AppLogger {
  final Logger _logger;

  AppLogger({bool isDebug = true, LogOutput? output})
    : _logger = Logger(
        printer: isDebug
            ? PrettyPrinter(
                methodCount: 2,
                errorMethodCount: 8,
                lineLength: 120,
                colors: true,
              )
            : SimplePrinter(colors: false),
        output: output,
      );

  void verbose(String tag, String message, [Map<String, dynamic>? metadata]) {
    _log(Level.trace, tag, message, metadata);
  }

  void debug(String tag, String message, [Map<String, dynamic>? metadata]) {
    _log(Level.debug, tag, message, metadata);
  }

  void info(String tag, String message, [Map<String, dynamic>? metadata]) {
    _log(Level.info, tag, message, metadata);
  }

  void warning(String tag, String message, [Map<String, dynamic>? metadata]) {
    _log(Level.warning, tag, message, metadata);
  }

  void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    final meta = {...?metadata};
    if (error != null) meta['error'] = error.toString();
    if (stackTrace != null) meta['stackTrace'] = stackTrace.toString();
    _log(Level.error, tag, message, meta.isNotEmpty ? meta : null);
  }

  void fatal(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    final meta = {...?metadata};
    if (error != null) meta['error'] = error.toString();
    if (stackTrace != null) meta['stackTrace'] = stackTrace.toString();
    _log(Level.fatal, tag, message, meta.isNotEmpty ? meta : null);
  }

  void _log(
    Level level,
    String tag,
    String message,
    Map<String, dynamic>? metadata,
  ) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'timestamp': timestamp,
      'tag': tag,
      'message': message,
      if (metadata != null && metadata.isNotEmpty) ...metadata,
    };
    _logger.log(level, payload);
  }
}
