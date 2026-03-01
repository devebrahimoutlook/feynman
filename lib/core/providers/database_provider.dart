import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/database/daos/note_dao.dart';
import 'package:feynman/core/database/daos/folder_dao.dart';
import 'package:feynman/core/database/daos/flashcard_dao.dart';
import 'package:feynman/core/database/daos/quiz_dao.dart';
import 'package:feynman/core/database/daos/feynman_session_dao.dart';
import 'package:feynman/core/database/daos/achievement_dao.dart';
import 'package:feynman/core/database/daos/daily_goal_dao.dart';
import 'package:feynman/core/database/daos/streak_dao.dart';
import 'package:feynman/core/database/daos/sync_queue_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final db = AppDatabase();
  return db;
});

final noteDaoProvider = Provider<NoteDao>((ref) {
  return ref.watch(databaseProvider).noteDao;
});

final folderDaoProvider = Provider<FolderDao>((ref) {
  return ref.watch(databaseProvider).folderDao;
});

final flashcardDaoProvider = Provider<FlashcardDao>((ref) {
  return ref.watch(databaseProvider).flashcardDao;
});

final quizDaoProvider = Provider<QuizDao>((ref) {
  return ref.watch(databaseProvider).quizDao;
});

final feynmanSessionDaoProvider = Provider<FeynmanSessionDao>((ref) {
  return ref.watch(databaseProvider).feynmanSessionDao;
});

final achievementDaoProvider = Provider<AchievementDao>((ref) {
  return ref.watch(databaseProvider).achievementDao;
});

final dailyGoalDaoProvider = Provider<DailyGoalDao>((ref) {
  return ref.watch(databaseProvider).dailyGoalDao;
});

final streakDaoProvider = Provider<StreakDao>((ref) {
  return ref.watch(databaseProvider).streakDao;
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return ref.watch(databaseProvider).syncQueueDao;
});
