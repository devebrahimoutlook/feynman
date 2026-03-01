import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/logging/app_logger.dart';

final loggerProvider = Provider<AppLogger>((ref) {
  ref.keepAlive();
  return AppLogger();
});
