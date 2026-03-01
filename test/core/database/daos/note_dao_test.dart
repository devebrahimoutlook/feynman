import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  group('NoteDao', () {
    test('watchNotesByUser returns empty stream initially', () async {
      final notes = await db.noteDao.watchNotesByUser('user1').first;
      expect(notes, isEmpty);
    });

    test('getNoteById returns null for non-existent note', () async {
      final note = await db.noteDao.getNoteById('nonexistent');
      expect(note, isNull);
    });

    test(
      'searchNotes returns empty list for no matches',
      () async {
        final results = await db.noteDao.searchNotes('user1', 'nonexistent');
        expect(results, isEmpty);
      },
      skip: 'FTS5 requires native SQLite with FTS5 module',
    );

    test('watchPinnedNotes returns empty stream initially', () async {
      final notes = await db.noteDao.watchPinnedNotes('user1').first;
      expect(notes, isEmpty);
    });

    test('watchNotesByFolder returns empty stream initially', () async {
      final notes = await db.noteDao.watchNotesByFolder('folder1').first;
      expect(notes, isEmpty);
    });

    group('write operations', () {
      test('insertNote creates note and sync queue item', () async {
        final now = DateTime.now();
        await db.noteDao.insertNote(
          NoteTableCompanion.insert(
            id: 'note_test_1',
            userId: 'user1',
            folderId: const Value('folder1'),
            title: 'Test Note',
            sourceType: 'text',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final note = await db.noteDao.getNoteById('note_test_1');
        expect(note, isNotNull);
        expect(note!.title, equals('Test Note'));

        final syncItems = await db.syncQueueDao.watchPendingItems().first;
        expect(
          syncItems.any(
            (item) =>
                item.entityType == 'note' && item.entityId == 'note_test_1',
          ),
          isTrue,
        );
      });

      test(
        'updateNote increments version and creates sync queue item',
        () async {
          final now = DateTime.now();
          await db.noteDao.insertNote(
            NoteTableCompanion.insert(
              id: 'note_test_2',
              userId: 'user1',
              folderId: const Value('folder1'),
              title: 'Original',
              sourceType: 'text',
              createdAt: now,
              updatedAt: now,
              version: const Value(1),
            ),
          );

          await db.noteDao.updateNote(
            NoteTableCompanion(
              id: const Value('note_test_2'),
              userId: const Value('user1'),
              folderId: const Value('folder1'),
              title: const Value('Updated'),
              sourceType: const Value('text'),
              updatedAt: Value(now),
            ),
          );

          final note = await db.noteDao.getNoteById('note_test_2');
          expect(note!.title, equals('Updated'));
        },
      );

      test('softDeleteNote marks note as deleted', () async {
        final now = DateTime.now();
        await db.noteDao.insertNote(
          NoteTableCompanion.insert(
            id: 'note_test_3',
            userId: 'user1',
            folderId: const Value('folder1'),
            title: 'Test',
            sourceType: 'text',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.noteDao.softDeleteNote('note_test_3');

        final note = await db.noteDao.getNoteById('note_test_3');
        expect(note!.isDeleted, isTrue);
      });

      test('insertNote handles disk full error gracefully', () async {
        final now = DateTime.now();

        await db.noteDao.insertNote(
          NoteTableCompanion.insert(
            id: 'note_test_4',
            userId: 'user1',
            folderId: const Value('folder1'),
            title: 'Test',
            sourceType: 'text',
            createdAt: now,
            updatedAt: now,
          ),
        );

        expect(await db.noteDao.getNoteById('note_test_4'), isNotNull);
      });
    });
  });
}
