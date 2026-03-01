import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/quiz_table.dart';
import 'package:feynman/core/database/tables/quiz_question_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'quiz_dao.g.dart';

@DriftAccessor(tables: [QuizTable, QuizQuestionTable, SyncQueueItemTable])
class QuizDao extends DatabaseAccessor<AppDatabase> with _$QuizDaoMixin {
  QuizDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<QuizTableData>> watchQuizzesByNote(String noteId) {
    return (select(quizTable)
          ..where((t) => t.noteId.equals(noteId) & t.isDeleted.equals(false)))
        .watch();
  }

  Future<QuizTableData?> getQuizById(String id) {
    return (select(quizTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<QuizQuestionTableData>> getQuestionsForQuiz(String quizId) {
    return (select(
      quizQuestionTable,
    )..where((t) => t.quizId.equals(quizId))).get();
  }

  Stream<List<QuizQuestionTableData>> watchQuestionsForQuiz(String quizId) {
    return (select(
      quizQuestionTable,
    )..where((t) => t.quizId.equals(quizId))).watch();
  }

  Future<void> insertQuizWithQuestions(
    QuizTableCompanion quiz,
    List<QuizQuestionTableCompanion> questions,
  ) async {
    try {
      await transaction(() async {
        await into(quizTable).insert(quiz);
        for (final q in questions) {
          await into(quizQuestionTable).insert(q);
        }
        await _enqueue('quiz', quiz.id.value, 'create', _quizToJson(quiz));
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('QuizDao', 'Failed to insert quiz: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> updateQuiz(QuizTableCompanion quiz) async {
    try {
      final existing = await getQuizById(quiz.id.value);
      await transaction(() async {
        await (update(
          quizTable,
        )..where((t) => t.id.equals(quiz.id.value))).write(quiz);
        await _enqueue(
          'quiz',
          quiz.id.value,
          'update',
          _quizToJson(
            quiz.copyWith(version: Value((existing?.version ?? 0) + 1)),
          ),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('QuizDao', 'Failed to update quiz: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> softDeleteQuiz(String id) async {
    try {
      final existing = await getQuizById(id);
      await transaction(() async {
        await (update(quizTable)..where((t) => t.id.equals(id))).write(
          QuizTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            version: Value((existing?.version ?? 0) + 1),
          ),
        );
        await _enqueue('quiz', id, 'delete', '');
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('QuizDao', 'Failed to delete quiz: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> _enqueue(
    String entityType,
    String entityId,
    String operation,
    String payload,
  ) async {
    await into(syncQueueItemTable).insert(
      SyncQueueItemTableCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        status: const Value('pending'),
        createdAt: DateTime.now(),
      ),
    );
  }

  String _quizToJson(QuizTableCompanion quiz) {
    return jsonEncode({
      'id': quiz.id.value,
      'noteId': quiz.noteId.value,
      'userId': quiz.userId.value,
      'title': quiz.title.value,
      'bestScore': quiz.bestScore.present ? quiz.bestScore.value : 0,
      'attemptCount': quiz.attemptCount.present ? quiz.attemptCount.value : 0,
      'version': quiz.version.present ? quiz.version.value : 1,
    });
  }
}
