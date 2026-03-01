import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/tables/achievement_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';
import 'package:feynman/core/logging/app_logger.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [AchievementTable, SyncQueueItemTable])
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  static final _logger = AppLogger();

  static bool _isDiskFullError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('disk') ||
        errorStr.contains('storage') ||
        errorStr.contains('no space') ||
        errorStr.contains('quota') ||
        errorStr.contains('full');
  }

  Stream<List<AchievementTableData>> watchAchievementsByUser(String userId) {
    return (select(
      achievementTable,
    )..where((t) => t.userId.equals(userId))).watch();
  }

  Future<AchievementTableData?> getAchievementById(String id) {
    return (select(
      achievementTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertAchievement(AchievementTableCompanion achievement) async {
    try {
      await transaction(() async {
        await into(achievementTable).insert(achievement);
        await _enqueue(
          'achievement',
          achievement.id.value,
          'create',
          _achievementToJson(achievement),
        );
      });
    } catch (e) {
      if (_isDiskFullError(e)) {
        _logger.error(
          'AchievementDao',
          'Failed to insert achievement: Storage full',
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

  String _achievementToJson(AchievementTableCompanion achievement) {
    return jsonEncode({
      'id': achievement.id.value,
      'userId': achievement.userId.value,
      'badgeType': achievement.badgeType.value,
      'earnedAt': achievement.earnedAt.value.toIso8601String(),
      'version': achievement.version.value,
    });
  }
}
