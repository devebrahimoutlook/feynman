import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/daily_goal_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'daily_goal_dao.g.dart';

@DriftAccessor(tables: [DailyGoalTable, SyncQueueItemTable])
class DailyGoalDao extends DatabaseAccessor<AppDatabase>
    with _$DailyGoalDaoMixin {
  DailyGoalDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<DailyGoalTableData?> watchGoalForDate(String userId, String date) {
    return (select(dailyGoalTable)
          ..where((t) => t.userId.equals(userId) & t.date.equals(date)))
        .watchSingleOrNull();
  }

  Stream<List<DailyGoalTableData>> watchRecentGoals(String userId, int days) {
    return (select(dailyGoalTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(days))
        .watch();
  }

  Future<DailyGoalTableData?> getGoalForDate(String userId, String date) {
    return (select(dailyGoalTable)
          ..where((t) => t.userId.equals(userId) & t.date.equals(date)))
        .getSingleOrNull();
  }

  Future<void> upsertGoal(DailyGoalTableCompanion goal) async {
    try {
      await transaction(() async {
        await into(dailyGoalTable).insertOnConflictUpdate(goal);
        await _enqueue(
          'goal',
          goal.id.value,
          goal.id.present ? 'update' : 'create',
          _goalToJson(goal),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error('DailyGoalDao', 'Failed to upsert goal: Storage full', e);
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

  String _goalToJson(DailyGoalTableCompanion goal) {
    return jsonEncode({
      'id': goal.id.value,
      'userId': goal.userId.value,
      'notesTarget': goal.notesTarget.value,
      'flashcardsTarget': goal.flashcardsTarget.value,
      'studyMinutesTarget': goal.studyMinutesTarget.value,
      'date': goal.date.value,
      'notesCompleted': goal.notesCompleted.value,
      'flashcardsCompleted': goal.flashcardsCompleted.value,
      'studyMinutesCompleted': goal.studyMinutesCompleted.value,
      'version': goal.version.value,
    });
  }
}
