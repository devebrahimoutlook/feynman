import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'note_dao.g.dart';

class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<NoteTableData>> watchNotesByUser(String userId) {
    return (select(noteTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..where((t) => t.isArchived.equals(false)))
        .watch();
  }

  Stream<List<NoteTableData>> watchPinnedNotes(String userId) {
    return (select(noteTable)
          ..where((t) => t.userId.equals(userId) & t.isPinned.equals(true))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  Stream<List<NoteTableData>> watchNotesByFolder(String folderId) {
    return (select(noteTable)..where(
          (t) => t.folderId.equals(folderId) & t.isDeleted.equals(false),
        ))
        .watch();
  }

  Future<NoteTableData?> getNoteById(String id) {
    return (select(noteTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<NoteTableData>> searchNotes(String userId, String query) async {
    final results = await customSelect(
      '''SELECT note_table.* FROM note_table
         JOIN note_fts ON note_table.id = note_fts.id
         WHERE note_fts MATCH ? AND note_table.user_id = ?
         AND note_table.is_deleted = 0''',
      variables: [Variable.withString(query), Variable.withString(userId)],
      readsFrom: {noteTable},
    ).get();
    return results
        .map(
          (row) => NoteTableData(
            id: row.read<String>('id'),
            userId: row.read<String>('user_id'),
            folderId: row.readNullable<String>('folder_id'),
            title: row.read<String>('title'),
            sourceType: row.read<String>('source_type'),
            sourceUrl: row.readNullable<String>('source_url'),
            summary: row.readNullable<String>('summary'),
            content: row.readNullable<String>('content'),
            definitions: row.readNullable<String>('definitions'),
            examples: row.readNullable<String>('examples'),
            tags: row.readNullable<String>('tags'),
            isPinned: row.read<bool>('is_pinned'),
            isArchived: row.read<bool>('is_archived'),
            processingStatus: row.read<String>('processing_status'),
            isDeleted: row.read<bool>('is_deleted'),
            deletedAt: row.readNullable<DateTime>('deleted_at'),
            createdAt: row.read<DateTime>('created_at'),
            updatedAt: row.read<DateTime>('updated_at'),
            version: row.read<int>('version'),
          ),
        )
        .toList();
  }

  Future<void> insertNote(NoteTableCompanion note) async {
    try {
      await transaction(() async {
        await into(noteTable).insert(note);
        await _enqueue('note', note.id.value, 'create', _noteToJson(note));
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('NoteDao', 'Failed to insert note: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> updateNote(NoteTableCompanion note) async {
    try {
      final existing = await getNoteById(note.id.value);
      await transaction(() async {
        await (update(
          noteTable,
        )..where((t) => t.id.equals(note.id.value))).write(note);
        await _enqueue(
          'note',
          note.id.value,
          'update',
          _noteToJson(
            note.copyWith(version: Value((existing?.version ?? 0) + 1)),
          ),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('NoteDao', 'Failed to update note: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> softDeleteNote(String id) async {
    try {
      final existing = await getNoteById(id);
      await transaction(() async {
        await (update(noteTable)..where((t) => t.id.equals(id))).write(
          NoteTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            version: Value((existing?.version ?? 0) + 1),
          ),
        );
        await _enqueue('note', id, 'delete', '');
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('NoteDao', 'Failed to delete note: Storage full', e);
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

  String _noteToJson(NoteTableCompanion note) {
    return jsonEncode({
      'id': note.id.value,
      'userId': note.userId.value,
      'folderId': note.folderId.value,
      'title': note.title.value,
      'sourceType': note.sourceType.value,
      'sourceUrl': note.sourceUrl.value,
      'summary': note.summary.value,
      'content': note.content.value,
      'definitions': note.definitions.value,
      'examples': note.examples.value,
      'tags': note.tags.value,
      'isPinned': note.isPinned.present ? note.isPinned.value : false,
      'isArchived': note.isArchived.present ? note.isArchived.value : false,
      'processingStatus': note.processingStatus.present
          ? note.processingStatus.value
          : 'pending',
      'version': note.version.present ? note.version.value : 1,
    });
  }
}
