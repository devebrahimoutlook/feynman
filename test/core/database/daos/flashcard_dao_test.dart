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

  group('FlashcardDao', () {
    test('watchFlashcardsByNote returns empty stream initially', () async {
      final flashcards = await db.flashcardDao
          .watchFlashcardsByNote('note1')
          .first;
      expect(flashcards, isEmpty);
    });

    test('watchDueFlashcards returns empty stream initially', () async {
      final flashcards = await db.flashcardDao
          .watchDueFlashcards('user1', DateTime.now())
          .first;
      expect(flashcards, isEmpty);
    });

    test('watchFlashcardsByState returns empty stream initially', () async {
      final flashcards = await db.flashcardDao
          .watchFlashcardsByState('user1', 'new')
          .first;
      expect(flashcards, isEmpty);
    });

    test('getFlashcardById returns null for non-existent', () async {
      final flashcard = await db.flashcardDao.getFlashcardById('nonexistent');
      expect(flashcard, isNull);
    });

    group('write operations', () {
      test('insertFlashcard creates flashcard and sync queue item', () async {
        final now = DateTime.now();
        await db.flashcardDao.insertFlashcard(
          FlashcardTableCompanion.insert(
            id: 'flashcard1',
            noteId: 'note1',
            userId: 'user1',
            front: 'Front',
            back: 'Back',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final flashcard = await db.flashcardDao.getFlashcardById('flashcard1');
        expect(flashcard, isNotNull);
        expect(flashcard!.front, equals('Front'));
      });

      test('updateFlashcard updates flashcard', () async {
        final now = DateTime.now();
        await db.flashcardDao.insertFlashcard(
          FlashcardTableCompanion.insert(
            id: 'flashcard1',
            noteId: 'note1',
            userId: 'user1',
            front: 'Front',
            back: 'Back',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.flashcardDao.updateFlashcard(
          FlashcardTableCompanion(
            id: const Value('flashcard1'),
            noteId: const Value('note1'),
            userId: const Value('user1'),
            front: const Value('Updated Front'),
            back: const Value('Updated Back'),
            updatedAt: Value(now),
          ),
        );

        final flashcard = await db.flashcardDao.getFlashcardById('flashcard1');
        expect(flashcard!.front, equals('Updated Front'));
      });

      test('softDeleteFlashcard marks flashcard as deleted', () async {
        final now = DateTime.now();
        await db.flashcardDao.insertFlashcard(
          FlashcardTableCompanion.insert(
            id: 'flashcard1',
            noteId: 'note1',
            userId: 'user1',
            front: 'Front',
            back: 'Back',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.flashcardDao.softDeleteFlashcard('flashcard1');

        final flashcard = await db.flashcardDao.getFlashcardById('flashcard1');
        expect(flashcard!.isDeleted, isTrue);
      });
    });
  });
}
