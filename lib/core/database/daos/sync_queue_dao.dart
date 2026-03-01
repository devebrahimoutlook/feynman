import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueItemTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<SyncQueueItemTableData>> watchPendingItems() {
    return (select(syncQueueItemTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<int> getPendingCount() async {
    final count = syncQueueItemTable.id.count();
    final query = selectOnly(syncQueueItemTable)
      ..addColumns([count])
      ..where(syncQueueItemTable.status.equals('pending'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<SyncQueueItemTableData?> getItemById(int id) {
    return (select(
      syncQueueItemTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> enqueue(
    String entityType,
    String entityId,
    String operation,
    String payload,
  ) async {
    try {
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
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'SyncQueueDao',
          'Failed to enqueue item: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> markProcessing(int id) async {
    try {
      await (update(syncQueueItemTable)..where((t) => t.id.equals(id))).write(
        const SyncQueueItemTableCompanion(status: Value('processing')),
      );
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'SyncQueueDao',
          'Failed to mark processing: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> markCompleted(int id) async {
    try {
      await (update(syncQueueItemTable)..where((t) => t.id.equals(id))).write(
        SyncQueueItemTableCompanion(
          status: const Value('completed'),
          processedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'SyncQueueDao',
          'Failed to mark completed: Storage full',
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> markFailed(int id) async {
    try {
      final item = await getItemById(id);
      if (item != null) {
        await (update(syncQueueItemTable)..where((t) => t.id.equals(id))).write(
          SyncQueueItemTableCompanion(
            status: const Value('failed'),
            retryCount: Value(item.retryCount + 1),
          ),
        );
      }
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('SyncQueueDao', 'Failed to mark failed: Storage full', e);
      }
      rethrow;
    }
  }
}
