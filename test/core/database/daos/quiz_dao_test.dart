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

  group('QuizDao', () {
    test('watchQuizzesByNote returns empty stream initially', () async {
      final quizzes = await db.quizDao.watchQuizzesByNote('note1').first;
      expect(quizzes, isEmpty);
    });

    test('getQuizById returns null for non-existent', () async {
      final quiz = await db.quizDao.getQuizById('nonexistent');
      expect(quiz, isNull);
    });

    test('getQuestionsForQuiz returns empty list initially', () async {
      final questions = await db.quizDao.getQuestionsForQuiz('quiz1');
      expect(questions, isEmpty);
    });

    group('write operations', () {
      test('insertQuizWithQuestions creates quiz and questions', () async {
        final now = DateTime.now();
        await db.quizDao.insertQuizWithQuestions(
          QuizTableCompanion.insert(
            id: 'quiz1',
            noteId: 'note1',
            userId: 'user1',
            title: 'Test Quiz',
            createdAt: now,
            updatedAt: now,
          ),
          [
            QuizQuestionTableCompanion.insert(
              id: 'q1',
              quizId: 'quiz1',
              questionText: 'Question 1',
              questionType: 'multiple_choice',
              correctAnswer: 'a',
              options: const Value('["a","b","c"]'),
              createdAt: now,
            ),
          ],
        );

        final quiz = await db.quizDao.getQuizById('quiz1');
        expect(quiz, isNotNull);
        expect(quiz!.title, equals('Test Quiz'));

        final questions = await db.quizDao.getQuestionsForQuiz('quiz1');
        expect(questions.length, equals(1));
      });

      test('updateQuiz updates quiz', () async {
        final now = DateTime.now();
        await db.quizDao.insertQuizWithQuestions(
          QuizTableCompanion.insert(
            id: 'quiz1',
            noteId: 'note1',
            userId: 'user1',
            title: 'Original',
            createdAt: now,
            updatedAt: now,
          ),
          [],
        );

        await db.quizDao.updateQuiz(
          QuizTableCompanion(
            id: const Value('quiz1'),
            noteId: const Value('note1'),
            userId: const Value('user1'),
            title: const Value('Updated'),
            bestScore: const Value(100),
            updatedAt: Value(now),
          ),
        );

        final quiz = await db.quizDao.getQuizById('quiz1');
        expect(quiz!.title, equals('Updated'));
      });

      test('softDeleteQuiz marks quiz as deleted', () async {
        final now = DateTime.now();
        await db.quizDao.insertQuizWithQuestions(
          QuizTableCompanion.insert(
            id: 'quiz1',
            noteId: 'note1',
            userId: 'user1',
            title: 'Test',
            createdAt: now,
            updatedAt: now,
          ),
          [],
        );

        await db.quizDao.softDeleteQuiz('quiz1');

        final quiz = await db.quizDao.getQuizById('quiz1');
        expect(quiz!.isDeleted, isTrue);
      });
    });
  });
}
