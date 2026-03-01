import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';
import 'package:feynman/core/database/tables/folder_table.dart';
import 'package:feynman/core/database/tables/note_table.dart';
import 'package:feynman/core/database/tables/flashcard_table.dart';
import 'package:feynman/core/database/tables/quiz_table.dart';
import 'package:feynman/core/database/tables/quiz_question_table.dart';
import 'package:feynman/core/database/tables/feynman_session_table.dart';
import 'package:feynman/core/database/tables/achievement_table.dart';
import 'package:feynman/core/database/tables/daily_goal_table.dart';
import 'package:feynman/core/database/tables/streak_table.dart';
import 'package:feynman/core/database/tables/sync_queue_item_table.dart';

import 'package:feynman/core/database/daos/note_dao.dart';
import 'package:feynman/core/database/daos/folder_dao.dart';
import 'package:feynman/core/database/daos/flashcard_dao.dart';
import 'package:feynman/core/database/daos/quiz_dao.dart';
import 'package:feynman/core/database/daos/feynman_session_dao.dart';
import 'package:feynman/core/database/daos/achievement_dao.dart';
import 'package:feynman/core/database/daos/daily_goal_dao.dart';
import 'package:feynman/core/database/daos/streak_dao.dart';
import 'package:feynman/core/database/daos/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UserProfileTable,
    FolderTable,
    NoteTable,
    FlashcardTable,
    QuizTable,
    QuizQuestionTable,
    FeynmanSessionTable,
    AchievementTable,
    DailyGoalTable,
    StreakTable,
    SyncQueueItemTable,
  ],
  daos: [
    NoteDao,
    FolderDao,
    FlashcardDao,
    QuizDao,
    FeynmanSessionDao,
    AchievementDao,
    DailyGoalDao,
    StreakDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'feynman_db');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(userProfileTable, userProfileTable.authProvider);
        await m.addColumn(userProfileTable, userProfileTable.emailVerified);
      }
      if (from < 3) {
        await m.addColumn(noteTable, noteTable.isDeleted);
        await m.addColumn(noteTable, noteTable.deletedAt);
        await m.addColumn(flashcardTable, flashcardTable.isDeleted);
        await m.addColumn(flashcardTable, flashcardTable.deletedAt);
        await m.addColumn(quizTable, quizTable.isDeleted);
        await m.addColumn(quizTable, quizTable.deletedAt);
        await m.addColumn(feynmanSessionTable, feynmanSessionTable.isDeleted);
        await m.addColumn(feynmanSessionTable, feynmanSessionTable.deletedAt);
        // ignore: deprecated_member_use
        await m.issueCustomQuery('''
          CREATE VIRTUAL TABLE IF NOT EXISTS note_fts
          USING fts5(id UNINDEXED, title, content,
                     content='note_table', content_rowid='rowid');
        ''');
      }
    },
  );

  /// Clears all local data from all tables (used on logout/account deletion).
  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}
