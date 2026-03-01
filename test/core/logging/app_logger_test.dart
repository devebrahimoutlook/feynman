import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:feynman/core/logging/app_logger.dart';

/// Captures log output for assertion
class _TestOutput extends LogOutput {
  final List<OutputEvent> events = [];

  @override
  void output(OutputEvent event) {
    events.add(event);
  }
}

void main() {
  group('AppLogger', () {
    test('info method produces log at info level', () {
      final out = _TestOutput();
      final logger = AppLogger(output: out);
      logger.info('TestTag', 'Hello');
      expect(out.events, isNotEmpty);
      expect(out.events.last.lines.join(), contains('[TestTag] Hello'));
    });

    test('error method includes error and stack trace in metadata', () {
      final out = _TestOutput();
      final logger = AppLogger(output: out);
      final error = Exception('boom');
      final stack = StackTrace.current;
      logger.error('TestTag', 'Failed', error, stack);
      expect(out.events, isNotEmpty);
      expect(out.events.last.lines.join(), contains('Failed'));
    });

    test('metadata map is included when provided', () {
      final out = _TestOutput();
      final logger = AppLogger(output: out);
      logger.info('TestTag', 'With meta', {'key': 'value'});
      expect(out.events, isNotEmpty);
      expect(out.events.last.lines.join(), contains('key'));
    });
  });
}
