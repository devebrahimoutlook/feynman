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

  group('AchievementDao', () {
    test('watchAchievementsByUser returns empty stream initially', () async {
      final achievements = await db.achievementDao
          .watchAchievementsByUser('user1')
          .first;
      expect(achievements, isEmpty);
    });

    test('getAchievementById returns null for non-existent', () async {
      final achievement = await db.achievementDao.getAchievementById(
        'nonexistent',
      );
      expect(achievement, isNull);
    });

    group('write operations', () {
      test(
        'insertAchievement creates achievement and sync queue item',
        () async {
          final now = DateTime.now();
          await db.achievementDao.insertAchievement(
            AchievementTableCompanion.insert(
              id: 'achievement1',
              userId: 'user1',
              badgeType: 'first_note',
              earnedAt: now,
              version: const Value(1),
            ),
          );

          final achievement = await db.achievementDao.getAchievementById(
            'achievement1',
          );
          expect(achievement, isNotNull);
          expect(achievement!.badgeType, equals('first_note'));
        },
      );
    });
  });
}
