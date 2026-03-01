import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/feynman_session_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'feynman_session_dao.g.dart';

@DriftAccessor(tables: [FeynmanSessionTable, SyncQueueItemTable])
class FeynmanSessionDao extends DatabaseAccessor<AppDatabase>
    with _$FeynmanSessionDaoMixin {
  FeynmanSessionDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<FeynmanSessionTableData>> watchSessionsByNote(String noteId) {
    return (select(feynmanSessionTable)
          ..where((t) => t.noteId.equals(noteId) & t.isDeleted.equals(false)))
        .watch();
  }

  Stream<List<FeynmanSessionTableData>> watchSessionsByUser(String userId) {
    return (select(feynmanSessionTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .watch();
  }

  Future<FeynmanSessionTableData?> getSessionById(String id) {
    return (select(
      feynmanSessionTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSession(FeynmanSessionTableCompanion session) async {
    try {
      await transaction(() async {
        await into(feynmanSessionTable).insert(session);
        await _enqueue(
          'session',
          session.id.value,
          'create',
          _sessionToJson(session),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FeynmanSessionDao',
          'Failed to insert session: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> updateSession(FeynmanSessionTableCompanion session) async {
    try {
      final existing = await getSessionById(session.id.value);
      await transaction(() async {
        await (update(
          feynmanSessionTable,
        )..where((t) => t.id.equals(session.id.value))).write(session);
        await _enqueue(
          'session',
          session.id.value,
          'update',
          _sessionToJson(
            session.copyWith(version: Value((existing?.version ?? 0) + 1)),
          ),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FeynmanSessionDao',
          'Failed to update session: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> softDeleteSession(String id) async {
    try {
      final existing = await getSessionById(id);
      await transaction(() async {
        await (update(
          feynmanSessionTable,
        )..where((t) => t.id.equals(id))).write(
          FeynmanSessionTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            version: Value((existing?.version ?? 0) + 1),
          ),
        );
        await _enqueue('session', id, 'delete', '');
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'FeynmanSessionDao',
          'Failed to delete session: Storage full',
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

  String _sessionToJson(FeynmanSessionTableCompanion session) {
    return jsonEncode({
      'id': session.id.value,
      'noteId': session.noteId.value,
      'userId': session.userId.value,
      'topic': session.topic.value,
      'inputType': session.inputType.value,
      'explanation': session.explanation.value,
      'audioUrl': session.audioUrl.value,
      'clarityScore': session.clarityScore.present
          ? session.clarityScore.value
          : null,
      'accuracyScore': session.accuracyScore.present
          ? session.accuracyScore.value
          : null,
      'structureScore': session.structureScore.present
          ? session.structureScore.value
          : null,
      'examplesScore': session.examplesScore.present
          ? session.examplesScore.value
          : null,
      'feedback': session.feedback.value,
      'attemptNumber': session.attemptNumber.present
          ? session.attemptNumber.value
          : 1,
      'version': session.version.present ? session.version.value : 1,
    });
  }
}
