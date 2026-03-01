import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/flashcard_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'flashcard_dao.g.dart';

@DriftAccessor(tables: [FlashcardTable, SyncQueueItemTable])
class FlashcardDao extends DatabaseAccessor<AppDatabase>
    with _$FlashcardDaoMixin {
  FlashcardDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<FlashcardTableData>> watchFlashcardsByNote(String noteId) {
    return (select(flashcardTable)
          ..where((t) => t.noteId.equals(noteId) & t.isDeleted.equals(false)))
        .watch();
  }

  Stream<List<FlashcardTableData>> watchDueFlashcards(
    String userId,
    DateTime before,
  ) {
    return (select(flashcardTable)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false))
          ..where(
            (t) => t.dueDate.isSmallerOrEqualValue(before) | t.dueDate.isNull(),
          ))
        .watch();
  }

  Stream<List<FlashcardTableData>> watchFlashcardsByState(
    String userId,
    String state,
  ) {
    return (select(flashcardTable)
          ..where((t) => t.userId.equals(userId) & t.state.equals(state))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  Future<FlashcardTableData?> getFlashcardById(String id) {
    return (select(
      flashcardTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertFlashcard(FlashcardTableCompanion flashcard) async {
    try {
      await transaction(() async {
        await into(flashcardTable).insert(flashcard);
        await _enqueue(
          'flashcard',
          flashcard.id.value,
          'create',
          _flashcardToJson(flashcard),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FlashcardDao',
          'Failed to insert flashcard: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> updateFlashcard(FlashcardTableCompanion flashcard) async {
    try {
      final existing = await getFlashcardById(flashcard.id.value);
      await transaction(() async {
        await (update(
          flashcardTable,
        )..where((t) => t.id.equals(flashcard.id.value))).write(flashcard);
        await _enqueue(
          'flashcard',
          flashcard.id.value,
          'update',
          _flashcardToJson(
            flashcard.copyWith(version: Value((existing?.version ?? 0) + 1)),
          ),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FlashcardDao',
          'Failed to update flashcard: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> softDeleteFlashcard(String id) async {
    try {
      final existing = await getFlashcardById(id);
      await transaction(() async {
        await (update(flashcardTable)..where((t) => t.id.equals(id))).write(
          FlashcardTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            version: Value((existing?.version ?? 0) + 1),
          ),
        );
        await _enqueue('flashcard', id, 'delete', '');
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FlashcardDao',
          'Failed to delete flashcard: Storage full',
          e,
        );
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

  String _flashcardToJson(FlashcardTableCompanion flashcard) {
    return jsonEncode({
      'id': flashcard.id.value,
      'noteId': flashcard.noteId.value,
      'userId': flashcard.userId.value,
      'front': flashcard.front.value,
      'back': flashcard.back.value,
      'hint': flashcard.hint.value,
      'state': flashcard.state.present ? flashcard.state.value : 'new',
      'easeFactor': flashcard.easeFactor.present
          ? flashcard.easeFactor.value
          : 2.5,
      'intervalDays': flashcard.intervalDays.present
          ? flashcard.intervalDays.value
          : 0,
      'repetitionCount': flashcard.repetitionCount.present
          ? flashcard.repetitionCount.value
          : 0,
      'lapseCount': flashcard.lapseCount.present
          ? flashcard.lapseCount.value
          : 0,
      'dueDate': flashcard.dueDate.value?.toIso8601String(),
      'version': flashcard.version.present ? flashcard.version.value : 1,
    });
  }
}
