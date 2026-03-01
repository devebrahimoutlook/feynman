import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/folder_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'folder_dao.g.dart';

@DriftAccessor(tables: [FolderTable, SyncQueueItemTable])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<FolderTableData>> watchFoldersByUser(String userId) {
    return (select(folderTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .watch();
  }

  Future<FolderTableData?> getFolderById(String id) {
    return (select(
      folderTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertFolder(FolderTableCompanion folder) async {
    try {
      await transaction(() async {
        await into(folderTable).insert(folder);
        await _enqueue(
          'folder',
          folder.id.value,
          'create',
          _folderToJson(folder),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('FolderDao', 'Failed to insert folder: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> updateFolder(FolderTableCompanion folder) async {
    try {
      final existing = await getFolderById(folder.id.value);
      await transaction(() async {
        await (update(
          folderTable,
        )..where((t) => t.id.equals(folder.id.value))).write(folder);
        await _enqueue(
          'folder',
          folder.id.value,
          'update',
          _folderToJson(
            folder.copyWith(version: Value((existing?.version ?? 0) + 1)),
          ),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('FolderDao', 'Failed to update folder: Storage full', e);
      }
      rethrow;
    }
  }

  Future<void> softDeleteFolder(String id) async {
    try {
      final existing = await getFolderById(id);
      await transaction(() async {
        await (update(folderTable)..where((t) => t.id.equals(id))).write(
          FolderTableCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
            version: Value((existing?.version ?? 0) + 1),
          ),
        );
        await _enqueue('folder', id, 'delete', '');
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('FolderDao', 'Failed to delete folder: Storage full', e);
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

  String _folderToJson(FolderTableCompanion folder) {
    return jsonEncode({
      'id': folder.id.value,
      'userId': folder.userId.value,
      'name': folder.name.value,
      'color': folder.color.present ? folder.color.value : '#4CAF50',
      'icon': folder.icon.present ? folder.icon.value : 'folder',
      'sortOrder': folder.sortOrder.present ? folder.sortOrder.value : 0,
      'version': folder.version.present ? folder.version.value : 1,
    });
  }
}
