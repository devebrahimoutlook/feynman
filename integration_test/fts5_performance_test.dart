// FTS5 Performance Integration Test
//
// This test verifies the Full-Text Search (FTS5) performance requirements
// specified in T034 of tasks.md.
//
// Requirements:
// - Search performance must be < 500ms for 10k-note datasets
// - Search must work with native SQLite with FTS5 module enabled
//
// Note: This test requires native SQLite with FTS5 module.
// Memory-based SQLite (NativeDatabase.memory()) does NOT support FTS5.
//
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FTS5 Performance', () {
    test('searches 10k notes in under 500ms', () async {
      // TODO: Implement when native SQLite with FTS5 is available
      // This test is skipped in CI because:
      // 1. Unit tests use NativeDatabase.memory() which lacks FTS5
      // 2. FTS5 requires native SQLite compilation with FTS5 module
      //
      // To run this test locally:
      // 1. Use drift_flutter with a real database file
      // 2. Ensure SQLite is compiled with FTS5 support
      // 3. Seed 10,000 notes
      // 4. Measure search time
      //
      // Expected: < 500ms for typical search queries
      throw UnimplementedError(
        'FTS5 integration test requires native SQLite with FTS5 module. '
        'See docs/fts5-setup.md for configuration.',
      );
    });
  });
}
