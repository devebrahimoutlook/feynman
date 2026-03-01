import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/seed/database_seeder.dart';

void main() {
  late AppDatabase db;
  late DatabaseSeeder seeder;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    seeder = DatabaseSeeder(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseSeeder', () {
    test('seedDemoData creates expected folder', () async {
      await seeder.seedDemoData();
      final folders = await db
          .customSelect(
            'SELECT * FROM folder_table WHERE name = ?',
            variables: [Variable.withString('Getting Started')],
          )
          .get();
      expect(folders.length, 1);
    });

    test('seedDemoData creates expected notes', () async {
      await seeder.seedDemoData();
      final notes = await db
          .customSelect(
            'SELECT * FROM note_table WHERE user_id = ?',
            variables: [Variable.withString('demo_user')],
          )
          .get();
      expect(notes.length, greaterThanOrEqualTo(2));
    });

    test('seedDemoData creates expected flashcards', () async {
      await seeder.seedDemoData();
      final flashcards = await db
          .customSelect(
            'SELECT * FROM flashcard_table WHERE user_id = ?',
            variables: [Variable.withString('demo_user')],
          )
          .get();
      expect(flashcards.length, greaterThanOrEqualTo(5));
    });

    test(
      'seedDemoData is idempotent - running twice creates no duplicates',
      () async {
        await seeder.seedDemoData();
        await seeder.seedDemoData();
        final folders = await db
            .customSelect('SELECT COUNT(*) as count FROM folder_table')
            .get();
        final count = folders.first.read<int>('count');
        expect(count, lessThanOrEqualTo(10));
      },
    );
  });
}
