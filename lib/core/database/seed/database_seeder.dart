import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/daos/note_dao.dart';
import 'package:feynman/core/database/daos/folder_dao.dart';
import 'package:feynman/core/database/daos/flashcard_dao.dart';

class DatabaseSeeder {
  final NoteDao _noteDao;
  final FolderDao _folderDao;
  final FlashcardDao _flashcardDao;

  DatabaseSeeder(AppDatabase db)
    : _noteDao = NoteDao(db),
      _folderDao = FolderDao(db),
      _flashcardDao = FlashcardDao(db);

  Future<void> seedDemoData() async {
    const demoUserId = 'demo_user';
    final now = DateTime.now();

    const folderId = 'folder_getting_started';
    final existingFolder = await _folderDao.getFolderById(folderId);
    if (existingFolder == null) {
      await _folderDao.insertFolder(
        FolderTableCompanion.insert(
          id: folderId,
          userId: demoUserId,
          name: 'Getting Started',
          color: const Value('#4CAF50'),
          icon: const Value('school'),
          sortOrder: const Value(0),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );
    }

    const note1Id = 'note_welcome';
    final existingNote1 = await _noteDao.getNoteById(note1Id);
    if (existingNote1 == null) {
      await _noteDao.insertNote(
        NoteTableCompanion.insert(
          id: note1Id,
          userId: demoUserId,
          folderId: const Value<String>(folderId),
          title: 'Welcome to Feynman',
          sourceType: 'text',
          summary: const Value('Learn about the Feynman Technique'),
          content: const Value(
            'The Feynman Technique is a learning method that involves explaining a concept in simple terms as if teaching it to someone else.',
          ),
          isPinned: const Value(true),
          isArchived: const Value(false),
          processingStatus: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );

      await _flashcardDao.insertFlashcard(
        FlashcardTableCompanion.insert(
          id: 'flashcard_1',
          noteId: note1Id,
          userId: demoUserId,
          front: 'What is the Feynman Technique?',
          back:
              'A learning method where you explain a concept in simple terms as if teaching it to someone else.',
          state: const Value('new'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );

      await _flashcardDao.insertFlashcard(
        FlashcardTableCompanion.insert(
          id: 'flashcard_2',
          noteId: note1Id,
          userId: demoUserId,
          front: 'Who invented the Feynman Technique?',
          back: 'Richard Feynman, a Nobel Prize-winning physicist.',
          state: const Value('new'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );
    }

    const note2Id = 'note_spaced_repetition';
    final existingNote2 = await _noteDao.getNoteById(note2Id);
    if (existingNote2 == null) {
      await _noteDao.insertNote(
        NoteTableCompanion.insert(
          id: note2Id,
          userId: demoUserId,
          folderId: const Value<String>(folderId),
          title: 'Spaced Repetition',
          sourceType: 'text',
          summary: const Value('Optimize your learning with spaced repetition'),
          content: const Value(
            'Spaced repetition is a learning technique that involves reviewing information at increasing intervals.',
          ),
          isPinned: const Value(false),
          isArchived: const Value(false),
          processingStatus: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );

      await _flashcardDao.insertFlashcard(
        FlashcardTableCompanion.insert(
          id: 'flashcard_3',
          noteId: note2Id,
          userId: demoUserId,
          front: 'What is spaced repetition?',
          back:
              'A learning technique that involves reviewing information at increasing intervals to optimize memory retention.',
          state: const Value('new'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );

      await _flashcardDao.insertFlashcard(
        FlashcardTableCompanion.insert(
          id: 'flashcard_4',
          noteId: note2Id,
          userId: demoUserId,
          front: 'What is the forgetting curve?',
          back:
              'A graph showing how information is lost over time when there is no attempt to retain it.',
          state: const Value('new'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );

      await _flashcardDao.insertFlashcard(
        FlashcardTableCompanion.insert(
          id: 'flashcard_5',
          noteId: note2Id,
          userId: demoUserId,
          front: 'What is an ideal interval for review?',
          back:
              'Reviews should be spaced at increasing intervals: 1 day, 3 days, 7 days, 14 days, 30 days, etc.',
          state: const Value('new'),
          createdAt: now,
          updatedAt: now,
          version: const Value(1),
        ),
      );
    }
  }
}
