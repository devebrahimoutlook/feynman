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

  group('DailyGoalDao', () {
    test('watchGoalForDate returns null initially', () async {
      final goal = await db.dailyGoalDao
          .watchGoalForDate('user1', '2026-03-01')
          .first;
      expect(goal, isNull);
    });

    test('watchRecentGoals returns empty stream initially', () async {
      final goals = await db.dailyGoalDao.watchRecentGoals('user1', 7).first;
      expect(goals, isEmpty);
    });

    test('getGoalForDate returns null for non-existent', () async {
      final goal = await db.dailyGoalDao.getGoalForDate('user1', '2026-03-01');
      expect(goal, isNull);
    });

    group('write operations', () {
      test('upsertGoal creates goal and sync queue item', () async {
        final now = DateTime.now();
        await db.dailyGoalDao.upsertGoal(
          DailyGoalTableCompanion.insert(
            id: 'goal1',
            userId: 'user1',
            date: '2026-03-01',
            notesTarget: const Value(5),
            flashcardsTarget: const Value(20),
            studyMinutesTarget: const Value(30),
            notesCompleted: const Value(0),
            flashcardsCompleted: const Value(0),
            studyMinutesCompleted: const Value(0),
            createdAt: now,
            updatedAt: now,
            version: const Value(1),
          ),
        );

        final goal = await db.dailyGoalDao.getGoalForDate(
          'user1',
          '2026-03-01',
        );
        expect(goal, isNotNull);
        expect(goal!.notesTarget, equals(5));
      });
    });
  });
}
