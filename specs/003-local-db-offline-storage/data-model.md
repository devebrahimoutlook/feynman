# Data Model: Local Database & Offline Storage (003)

**Branch**: `003-local-db-offline-storage`  
**Date**: 2026-03-01

All tables are implemented using Drift (SQLite). This document captures the complete schema, relationships, indices, and DAO method contracts.

---

## Entity Relationship Overview

```
UserProfileTable (1)
  ├──< FolderTable (many)
  ├──< NoteTable (many)
  │      ├──< FlashcardTable (many)
  │      ├──< QuizTable (many)
  │      │      └──< QuizQuestionTable (many)
  │      └──< FeynmanSessionTable (many)
  ├──< AchievementTable (many)
  ├──< DailyGoalTable (many)
  └──── StreakTable (1:1)

SyncQueueItemTable (independent, references entity IDs logically)
note_fts (virtual, mirrors NoteTable — no sync)
```

---

## Table Schemas

### UserProfileTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `email` | TEXT | NOT NULL |
| `displayName` | TEXT | nullable |
| `avatarUrl` | TEXT | nullable |
| `authProvider` | TEXT | nullable (added v2) |
| `emailVerified` | BOOL | default false (added v2) |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

---

### FolderTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `userId` | TEXT | FK → UserProfileTable |
| `name` | TEXT | NOT NULL |
| `color` | TEXT | default '#4A9EFF' |
| `icon` | TEXT | nullable |
| `sortOrder` | INT | default 0 |
| `isDeleted` | BOOL | default false |
| `deletedAt` | DATETIME | nullable |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Indices (new)**: `(userId, isDeleted)`

---

### NoteTable *(existing – v1, extended v3)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `userId` | TEXT | FK → UserProfileTable |
| `folderId` | TEXT | FK → FolderTable, nullable |
| `title` | TEXT | NOT NULL |
| `sourceType` | TEXT | NOT NULL |
| `sourceUrl` | TEXT | nullable |
| `summary` | TEXT | nullable |
| `content` | TEXT | nullable |
| `definitions` | TEXT | nullable (JSON) |
| `examples` | TEXT | nullable (JSON) |
| `tags` | TEXT | nullable (JSON array) |
| `isPinned` | BOOL | default false |
| `isArchived` | BOOL | default false |
| `processingStatus` | TEXT | default 'pending' |
| `isDeleted` ⭐ | BOOL | default false **(v3 addition)** |
| `deletedAt` ⭐ | DATETIME | nullable **(v3 addition)** |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Indices (new)**: `(userId, isDeleted)`, `(folderId)`, `(isPinned)`, `(isArchived)`

---

### note_fts *(new – v3, virtual FTS5)*

| Column | Notes |
|--------|-------|
| `id` | UNINDEXED — links to NoteTable.id |
| `title` | Indexed for FTS |
| `content` | Indexed for FTS |

Content table: `note_table`. Updated via trigger or application-level call after every note insert/update/delete.

> **Implementation note (F2)**: Two distinct steps are required:
> 1. **T005 (Phase 2)** — Declare the Drift virtual table *class* (e.g., `NoteFtsTable extends VirtualTable`) in `app_database.dart` so Drift's code generator registers it.
> 2. **T026 (Phase 5)** — Issue the actual `CREATE VIRTUAL TABLE note_fts USING fts5(…)` SQL via `MigrationStrategy.onUpgrade`'s `customStatement()` call for the v2→v3 step. These are separate concerns: class registration ≠ DDL execution.

---

### FlashcardTable *(existing – v1, extended v3)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `noteId` | TEXT | FK → NoteTable |
| `userId` | TEXT | FK → UserProfileTable |
| `front` | TEXT | NOT NULL |
| `back` | TEXT | NOT NULL |
| `hint` | TEXT | nullable |
| `state` | TEXT | default 'new' (new/learning/review/lapsed) |
| `easeFactor` | REAL | default 2.5 |
| `intervalDays` | INT | default 0 |
| `repetitionCount` | INT | default 0 |
| `lapseCount` | INT | default 0 |
| `dueDate` | DATETIME | nullable |
| `isDeleted` ⭐ | BOOL | default false **(v3 addition)** |
| `deletedAt` ⭐ | DATETIME | nullable **(v3 addition)** |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Indices (new)**: `(userId, state, dueDate)`, `(noteId, isDeleted)`

---

### QuizTable *(existing – v1, extended v3)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `noteId` | TEXT | FK → NoteTable |
| `userId` | TEXT | FK → UserProfileTable |
| `title` | TEXT | NOT NULL |
| `bestScore` | REAL | nullable |
| `attemptCount` | INT | default 0 |
| `isDeleted` ⭐ | BOOL | default false **(v3 addition)** |
| `deletedAt` ⭐ | DATETIME | nullable **(v3 addition)** |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Indices (new)**: `(userId, isDeleted)`, `(noteId)`

---

### QuizQuestionTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `quizId` | TEXT | FK → QuizTable |
| `questionText` | TEXT | NOT NULL |
| `questionType` | TEXT | NOT NULL (mcq/true_false/fill_blank) |
| `options` | TEXT | nullable (JSON array) |
| `correctAnswer` | TEXT | NOT NULL |
| `explanation` | TEXT | nullable |
| `difficulty` | TEXT | default 'medium' |
| `createdAt` | DATETIME | NOT NULL |

*No soft-delete: questions are cascade-deleted when parent quiz is deleted.*

---

### FeynmanSessionTable *(existing – v1, extended v3)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `noteId` | TEXT | FK → NoteTable |
| `userId` | TEXT | FK → UserProfileTable |
| `topic` | TEXT | NOT NULL |
| `inputType` | TEXT | NOT NULL (text/voice) |
| `explanation` | TEXT | nullable |
| `audioUrl` | TEXT | nullable |
| `clarityScore` | REAL | nullable |
| `accuracyScore` | REAL | nullable |
| `structureScore` | REAL | nullable |
| `examplesScore` | REAL | nullable |
| `feedback` | TEXT | nullable |
| `attemptNumber` | INT | default 1 |
| `isDeleted` ⭐ | BOOL | default false **(v3 addition)** |
| `deletedAt` ⭐ | DATETIME | nullable **(v3 addition)** |
| `createdAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Indices (new)**: `(userId, noteId, isDeleted)`

---

### AchievementTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `userId` | TEXT | FK → UserProfileTable |
| `badgeType` | TEXT | NOT NULL |
| `earnedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

*Append-only — no soft-delete.*

---

### DailyGoalTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `userId` | TEXT | FK → UserProfileTable |
| `notesTarget` | INT | default 1 |
| `flashcardsTarget` | INT | default 10 |
| `studyMinutesTarget` | INT | default 15 |
| `date` | TEXT | NOT NULL (ISO 8601 date string) |
| `notesCompleted` | INT | default 0 |
| `flashcardsCompleted` | INT | default 0 |
| `studyMinutesCompleted` | INT | default 0 |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

**Unique constraint**: `(userId, date)`  
**Indices (new)**: `(userId, date)`

---

### StreakTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | TEXT | PK |
| `userId` | TEXT | UNIQUE FK → UserProfileTable |
| `currentStreak` | INT | default 0 |
| `longestStreak` | INT | default 0 |
| `lastActivityDate` | TEXT | nullable (ISO 8601 date) |
| `totalStudyTimeMinutes` | INT | default 0 |
| `createdAt` | DATETIME | NOT NULL |
| `updatedAt` | DATETIME | NOT NULL |
| `version` | INT | default 1 |

*Single row per user (upsert pattern). No soft-delete.*

---

### SyncQueueItemTable *(existing – v1)*

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT | PK autoincrement |
| `entityType` | TEXT | NOT NULL (note/folder/flashcard/quiz/session/achievement/goal/streak) |
| `entityId` | TEXT | NOT NULL |
| `operation` | TEXT | NOT NULL (create/update/delete) |
| `payload` | TEXT | NOT NULL (JSON snapshot) |
| `status` | TEXT | default 'pending' (pending/processing/completed/failed) |
| `retryCount` | INT | default 0 |
| `createdAt` | DATETIME | NOT NULL |
| `processedAt` | DATETIME | nullable |

**Indices (new)**: `(status, createdAt)`, `(entityType, entityId)`

---

## Schema Version History

| Version | Spec | Changes |
|---------|------|---------|
| v1 | 001 – Foundation | Initial schema: all 11 tables created |
| v2 | 002 – Auth | Added `authProvider`, `emailVerified` to `UserProfileTable` |
| v3 | 003 – Local DB | Added `isDeleted` + `deletedAt` to Note, Flashcard, Quiz, FeynmanSession; Created `note_fts` virtual table; Added all missing indices |

---

## DAO Method Contracts

### NoteDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertNote(NoteTableCompanion)` | `Future<void>` | Insert + enqueue create |
| `updateNote(NoteTableCompanion)` | `Future<void>` | Update + enqueue update |
| `softDeleteNote(String id)` | `Future<void>` | Set isDeleted=true + enqueue delete |
| `getNoteById(String id)` | `Future<NoteItem?>` | One-shot fetch |
| `watchNotesByUser(String userId)` | `Stream<List<NoteItem>>` | Reactive list (excludes deleted/archived) |
| `watchPinnedNotes(String userId)` | `Stream<List<NoteItem>>` | Reactive pinned list |
| `watchNotesByFolder(String folderId)` | `Stream<List<NoteItem>>` | Reactive folder list |
| `searchNotes(String userId, String query)` | `Future<List<NoteItem>>` | FTS5 search |

### FolderDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertFolder(FolderTableCompanion)` | `Future<void>` | Insert + enqueue create |
| `updateFolder(FolderTableCompanion)` | `Future<void>` | Update + enqueue update |
| `softDeleteFolder(String id)` | `Future<void>` | Soft delete + enqueue delete |
| `watchFoldersByUser(String userId)` | `Stream<List<FolderItem>>` | Reactive (excludes deleted) |

### FlashcardDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertFlashcard(FlashcardTableCompanion)` | `Future<void>` | Insert + enqueue |
| `updateFlashcard(FlashcardTableCompanion)` | `Future<void>` | Update + enqueue |
| `softDeleteFlashcard(String id)` | `Future<void>` | Soft delete + enqueue |
| `watchFlashcardsByNote(String noteId)` | `Stream<List<FlashcardItem>>` | Reactive list |
| `watchDueFlashcards(String userId, DateTime before)` | `Stream<List<FlashcardItem>>` | Due-date filtered |
| `watchFlashcardsByState(String userId, String state)` | `Stream<List<FlashcardItem>>` | State filtered |

### QuizDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertQuizWithQuestions(QuizTableCompanion, List<QuizQuestionTableCompanion>)` | `Future<void>` | Transactional insert |
| `updateQuiz(QuizTableCompanion)` | `Future<void>` | Update quiz + enqueue |
| `softDeleteQuiz(String id)` | `Future<void>` | Soft delete quiz + cascade delete questions |
| `watchQuizzesByNote(String noteId)` | `Stream<List<QuizItem>>` | Reactive |
| `getQuestionsForQuiz(String quizId)` | `Future<List<QuizQuestionItem>>` | One-shot |

### FeynmanSessionDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertSession(FeynmanSessionTableCompanion)` | `Future<void>` | Insert + enqueue |
| `updateSession(FeynmanSessionTableCompanion)` | `Future<void>` | Update + enqueue |
| `softDeleteSession(String id)` | `Future<void>` | Soft delete + enqueue |
| `watchSessionsByNote(String noteId)` | `Stream<List<FeynmanSessionItem>>` | Reactive list |
| `watchSessionsByUser(String userId)` | `Stream<List<FeynmanSessionItem>>` | All user sessions |

### AchievementDao

| Method | Return | Description |
|--------|--------|-------------|
| `insertAchievement(AchievementTableCompanion)` | `Future<void>` | Insert + enqueue |
| `watchAchievementsByUser(String userId)` | `Stream<List<AchievementItem>>` | All badges |

### DailyGoalDao

| Method | Return | Description |
|--------|--------|-------------|
| `upsertGoal(DailyGoalTableCompanion)` | `Future<void>` | Insert-or-replace + enqueue |
| `watchGoalForDate(String userId, String date)` | `Stream<DailyGoalItem?>` | Today's goal |
| `watchRecentGoals(String userId, int days)` | `Stream<List<DailyGoalItem>>` | Last N days |

### StreakDao

| Method | Return | Description |
|--------|--------|-------------|
| `upsertStreak(StreakTableCompanion)` | `Future<void>` | Upsert + enqueue |
| `watchStreakByUser(String userId)` | `Stream<StreakItem?>` | Single reactive row |

### SyncQueueDao

| Method | Return | Description |
|--------|--------|-------------|
| `enqueue(String entityType, String entityId, String operation, String payload)` | `Future<void>` | Insert pending item |
| `watchPendingItems()` | `Stream<List<SyncQueueItemItem>>` | For sync engine (spec 004) |
| `markProcessing(int id)` | `Future<void>` | Set status=processing |
| `markCompleted(int id)` | `Future<void>` | Set status=completed, processedAt=now |
| `markFailed(int id)` | `Future<void>` | Increment retryCount, status=failed |
| `getPendingCount()` | `Future<int>` | Badge indicator for sync status UI |
