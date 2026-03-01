# Quickstart: Local Database & Offline Storage (003)

**Branch**: `003-local-db-offline-storage`  
**Date**: 2026-03-01  
**Prerequisite**: Feature 001 (Foundation) and 002 (Auth) fully merged.

---

## What This Feature Adds

Feature 003 adds **Data Access Objects (DAOs)** for all 11 Drift tables, a **schema migration to v3**, **FTS5 full-text search** on notes, and **soft-delete** support on syncable entities. Every DAO writes to the `SyncQueueItemTable` atomically alongside its primary write, creating a ready-to-consume queue for the sync engine (spec 004).

---

## Directory Structure

```text
lib/core/database/
├── app_database.dart          # Extended to schemaVersion 3
├── tables/                    # 11 existing table definitions (+ new columns)
│   ├── note_table.dart        # + isDeleted, deletedAt (v3)
│   ├── flashcard_table.dart   # + isDeleted, deletedAt (v3)
│   ├── quiz_table.dart        # + isDeleted, deletedAt (v3)
│   └── feynman_session_table.dart  # + isDeleted, deletedAt (v3)
├── daos/                      # NEW
│   ├── note_dao.dart
│   ├── folder_dao.dart
│   ├── flashcard_dao.dart
│   ├── quiz_dao.dart
│   ├── feynman_session_dao.dart
│   ├── achievement_dao.dart
│   ├── daily_goal_dao.dart
│   ├── streak_dao.dart
│   └── sync_queue_dao.dart
└── seed/                      # NEW
    └── database_seeder.dart

lib/core/providers/
└── database_providers.dart    # NEW — DAO Riverpod providers

test/core/database/
├── daos/
│   ├── note_dao_test.dart
│   ├── folder_dao_test.dart
│   ├── flashcard_dao_test.dart
│   ├── quiz_dao_test.dart
│   ├── feynman_session_dao_test.dart
│   ├── achievement_dao_test.dart
│   ├── daily_goal_dao_test.dart
│   ├── streak_dao_test.dart
│   └── sync_queue_dao_test.dart
└── migrations/
    └── migration_test.dart
```

---

## Running Tests

```bash
# Run all database DAO tests
flutter test test/core/database/

# Run only migration tests
flutter test test/core/database/migrations/

# Run with coverage report
flutter test test/core/database/ --coverage
```

---

## How a DAO Works

Each DAO has this structure:

```dart
// In: lib/core/database/daos/note_dao.dart
part of '../app_database.dart';

@DriftAccessor(tables: [NoteTable, SyncQueueItemTable])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  // Insert note + enqueue in one transaction
  Future<void> insertNote(NoteTableCompanion note) async {
    await transaction(() async {
      await into(noteTable).insert(note);
      await _enqueue('note', note.id.value, 'create', note.toJson());
    });
  }

  // Reactive stream — UI rebuilds automatically
  Stream<List<NoteItem>> watchNotesByUser(String userId) =>
      (select(noteTable)
        ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
          .watch();
}
```

---

## Riverpod Provider Pattern

```dart
// In: lib/core/providers/database_providers.dart
final noteDaoProvider = Provider.autoDispose<NoteDao>(
  (ref) => NoteDao(ref.read(databaseProvider)),
);
```

Feature-level data sources receive the DAO:

```dart
class NoteLocalDatasource {
  final NoteDao _dao;
  NoteLocalDatasource(this._dao);

  Stream<List<Note>> watchNotes(String userId) =>
      _dao.watchNotesByUser(userId).map((items) => items.map(NoteMapper.fromDb).toList());
}
```

---

## Schema Version 3 Migration

When upgrading from v2 → v3, the migration adds `isDeleted` and `deletedAt` to four tables and creates the FTS5 virtual table:

```dart
// In: app_database.dart MigrationStrategy.onUpgrade
if (from < 3) {
  await m.addColumn(noteTable, noteTable.isDeleted);
  await m.addColumn(noteTable, noteTable.deletedAt);
  await m.addColumn(flashcardTable, flashcardTable.isDeleted);
  await m.addColumn(flashcardTable, flashcardTable.deletedAt);
  await m.addColumn(quizTable, quizTable.isDeleted);
  await m.addColumn(quizTable, quizTable.deletedAt);
  await m.addColumn(feynmanSessionTable, feynmanSessionTable.isDeleted);
  await m.addColumn(feynmanSessionTable, feynmanSessionTable.deletedAt);
  await m.issueCustomQuery('''
    CREATE VIRTUAL TABLE IF NOT EXISTS note_fts
    USING fts5(id UNINDEXED, title, content,
               content='note_table', content_rowid='rowid');
  ''');
}
```
