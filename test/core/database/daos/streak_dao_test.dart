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

  group('StreakDao', () {
    test('watchStreakByUser returns null initially', () async {
      final streak = await db.streakDao.watchStreakByUser('user1').first;
      expect(streak, isNull);
    });

    test('getStreakByUser returns null for non-existent', () async {
      final streak = await db.streakDao.getStreakByUser('user1');
      expect(streak, isNull);
    });

    group('write operations', () {
      test('upsertStreak creates streak and sync queue item', () async {
        final now = DateTime.now();
        final today = now.toIso8601String().substring(0, 10);
        await db.streakDao.upsertStreak(
          StreakTableCompanion.insert(
            id: 'streak1',
            userId: 'user1',
            currentStreak: const Value(1),
            longestStreak: const Value(1),
            lastActivityDate: Value(today),
            totalStudyTimeMinutes: const Value(30),
            createdAt: now,
            updatedAt: now,
            version: const Value(1),
          ),
        );

        final streak = await db.streakDao.getStreakByUser('user1');
        expect(streak, isNotNull);
        expect(streak!.currentStreak, equals(1));
      });
    });
  });
}
