import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/streak_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'streak_dao.g.dart';

@DriftAccessor(tables: [StreakTable, SyncQueueItemTable])
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  StreakDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<StreakTableData?> watchStreakByUser(String userId) {
    return (select(
      streakTable,
    )..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  Future<StreakTableData?> getStreakByUser(String userId) {
    return (select(
      streakTable,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  Future<void> upsertStreak(StreakTableCompanion streak) async {
    try {
      await transaction(() async {
        await into(streakTable).insertOnConflictUpdate(streak);
        await _enqueue(
          'streak',
          streak.id.value,
          streak.id.present ? 'update' : 'create',
          _streakToJson(streak),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('StreakDao', 'Failed to upsert streak: Storage full', e);
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

  String _streakToJson(StreakTableCompanion streak) {
    return jsonEncode({
      'id': streak.id.value,
      'userId': streak.userId.value,
      'currentStreak': streak.currentStreak.value,
      'longestStreak': streak.longestStreak.value,
      'lastActivityDate': streak.lastActivityDate.value,
      'totalStudyTimeMinutes': streak.totalStudyTimeMinutes.value,
      'version': streak.version.value,
    });
  }
}
