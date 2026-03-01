import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feynman/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Migration Tests', () {
    test('database starts at schema version 3', () async {
      expect(db.schemaVersion, equals(3));
    });

    test(
      'migration adds isDeleted and deletedAt columns to noteTable',
      () async {
        final column = await db
            .customSelect('PRAGMA table_info(note_table)')
            .get();

        final columns = column.map((row) => row.read<String>('name')).toList();
        expect(columns, contains('is_deleted'));
        expect(columns, contains('deleted_at'));
      },
    );

    test(
      'migration adds isDeleted and deletedAt columns to flashcardTable',
      () async {
        final column = await db
            .customSelect('PRAGMA table_info(flashcard_table)')
            .get();

        final columns = column.map((row) => row.read<String>('name')).toList();
        expect(columns, contains('is_deleted'));
        expect(columns, contains('deleted_at'));
      },
    );

    test(
      'migration adds isDeleted and deletedAt columns to quizTable',
      () async {
        final column = await db
            .customSelect('PRAGMA table_info(quiz_table)')
            .get();

        final columns = column.map((row) => row.read<String>('name')).toList();
        expect(columns, contains('is_deleted'));
        expect(columns, contains('deleted_at'));
      },
    );

    test(
      'migration adds isDeleted and deletedAt columns to feynmanSessionTable',
      () async {
        final column = await db
            .customSelect('PRAGMA table_info(feynman_session_table)')
            .get();

        final columns = column.map((row) => row.read<String>('name')).toList();
        expect(columns, contains('is_deleted'));
        expect(columns, contains('deleted_at'));
      },
    );

    test('all tables have version column', () async {
      final tables = [
        'note_table',
        'flashcard_table',
        'quiz_table',
        'feynman_session_table',
        'folder_table',
        'achievement_table',
        'daily_goal_table',
        'streak_table',
      ];

      for (final tableName in tables) {
        final column = await db
            .customSelect('PRAGMA table_info($tableName)')
            .get();

        final columns = column.map((row) => row.read<String>('name')).toList();
        expect(
          columns,
          contains('version'),
          reason: '$tableName should have version column',
        );
      }
    });
  });
}
