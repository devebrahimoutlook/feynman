import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:feynman/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase', () {
    test('database has correct schema version', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      expect(db.schemaVersion, 3);
    });

    test('database creates all 11 tables', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();

      final tableNames = tables.map((r) => r.read<String>('name')).toSet();

      const expected = {
        'user_profile_table',
        'folder_table',
        'note_table',
        'flashcard_table',
        'quiz_table',
        'quiz_question_table',
        'feynman_session_table',
        'achievement_table',
        'daily_goal_table',
        'streak_table',
        'sync_queue_item_table',
      };

      for (final table in expected) {
        expect(tableNames, contains(table), reason: 'Missing table: $table');
      }
    });
  });
}
