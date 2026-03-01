# Research: Local Database & Offline Storage (003)

**Branch**: `003-local-db-offline-storage`  
**Date**: 2026-03-01  
**Status**: Complete — all unknowns resolved

---

## 1. DAO Architecture Pattern

**Decision**: Implement one Drift `DatabaseAccessor` class per entity (or closely related entity group), injected into feature-level data sources via Riverpod.

**Rationale**:
- Drift's `@DriftAccessor` annotation provides code-generated, type-safe query methods scoped to a subset of tables. This matches Clean Architecture (Constitution I): each DAO is a domain contract implementation, not a raw database handle.
- One DAO per entity keeps file sizes manageable and tests isolated.
- Group `QuizDao` with `QuizQuestionDao` because they share a parent-child relationship and are always used together.
- DAOs are injected as Riverpod `Provider<SomeDao>` instances depending on `databaseProvider`, keeping the composition root clean.

**Alternatives considered**:
- Single monolithic DAO: Rejected — would grow to hundreds of methods and become untestable.
- Raw SQL in repositories: Rejected — violates Constitution I (data layer must not expose raw SQL to domain).

**DAO list**:
| DAO | Tables | Scope |
|-----|--------|-------|
| `NoteDao` | `NoteTable` | CRUD, FTS, folder filter, pin/archive |
| `FolderDao` | `FolderTable` | CRUD, sort order, soft-delete |
| `FlashcardDao` | `FlashcardTable` | CRUD, state filter, due-date query |
| `QuizDao` | `QuizTable`, `QuizQuestionTable` | Quiz CRUD + question list |
| `FeynmanSessionDao` | `FeynmanSessionTable` | Session CRUD, session list by note |
| `AchievementDao` | `AchievementTable` | Insert, list all for user |
| `DailyGoalDao` | `DailyGoalTable` | Upsert-by-date, progress update |
| `StreakDao` | `StreakTable` | Get/upsert single user streak |
| `SyncQueueDao` | `SyncQueueItemTable` | Enqueue, list pending, mark done/failed |

---

## 2. Reactive Streams vs One-Shot Queries

**Decision**: All "list" and "get by ID" queries return Drift `Stream<T>` via `.watch()`. One-shot `get()` is used only where reactivity is not needed (e.g., migration seed check).

**Rationale**:
- Constitution V mandates unidirectional data flow. Riverpod `StreamProvider` wraps Drift streams, giving widgets automatic rebuild on data change — no manual invalidation needed.
- Drift's `watchSingle()` watches a single row; `watch()` watches a result set. Both integrate naturally with `ref.watch(noteListProvider)`.
- Avoids the anti-pattern of caching queries in widget `setState`.

**Pattern**:
```dart
// In DAO
Stream<List<NoteItem>> watchNotesByUser(String userId) =>
    (select(noteTable)..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .watch();

// In Riverpod
final noteListProvider = StreamProvider.autoDispose.family<List<NoteItem>, String>(
  (ref, userId) => ref.read(noteDaoProvider).watchNotesByUser(userId),
);
```

---

## 3. Full-Text Search (FTS5)

**Decision**: Use Drift's virtual FTS5 table alongside the `NoteTable`. A shadow FTS table (`note_fts`) indexes `title` and `content`. Inserts/updates/deletes trigger FTS maintenance via Drift `triggers` or application-level calls after every note write.

**Rationale**:
- SQLite FTS5 is available on all Android (≥24) and web (WASM SQLite) targets the app supports.
- FTS5 provides tokenized full-text search with ranking, prefix matching, and snippet generation — sufficient for note search without an external search service.
- The `note_fts` virtual table is declared as a Drift `VirtualTableDeclaration` and does not appear in the sync queue (it's a derived index, not primary data).
- Alternative (LIKE-based search): Rejected — O(n) full table scan, no relevance ranking, poor performance at scale (10k+ notes).

**Schema addition**:
```sql
CREATE VIRTUAL TABLE note_fts USING fts5(
  id UNINDEXED,
  title,
  content,
  content='note_table',
  content_rowid='rowid'
);
```

---

## 4. Soft-Delete Pattern

**Decision**: All syncable entities use a `isDeleted BOOLEAN DEFAULT false` and `deletedAt DATETIME NULL` column. All standard DAO queries filter `isDeleted = false`. Hard deletes are never issued on syncable entities; the sync engine (spec 004) uses the soft-delete record to propagate the deletion remotely.

**Rationale**:
- Without soft-delete, a locally deleted record cannot be communicated to the remote server through the sync queue (no payload to sync).
- The `SyncQueueItem` for a delete operation stores the entity ID; the receiver uses the soft-delete flag to confirm deletion and then hard-deletes the remote record.
- After a successful remote sync of a delete, the local record can be purged (hard-deleted locally) to free space.

**Entities with soft-delete**: Note, Folder, Flashcard, Quiz, FeynmanSession  
**Entities without soft-delete** (append-only / replace-only): Achievement (never deleted), DailyGoal (replace by date), Streak (single-row per user upsert), SyncQueueItem (managed separately)

Note: The existing `FolderTable` already has `isDeleted` and `deletedAt`. `NoteTable` has `isArchived` but not `isDeleted` — a migration will add `isDeleted` and `deletedAt` to the Note table. Similarly, `FlashcardTable`, `QuizTable`, and `FeynmanSessionTable` will gain `isDeleted` + `deletedAt` columns in schema version 3.

---

## 5. Schema Migration Strategy

**Decision**: Use Drift's `MigrationStrategy` with explicit version-gated `onUpgrade` branches. Each spec increments `schemaVersion`. Destructive migrations are never used in production. A `DatabaseSchemaVerifier` integration test validates the migrated schema after each version bump.

**Rationale**:
- Drift docs recommend explicit additive migrations (add columns/tables only, never drop in production). Columns can be made nullable or given defaults.
- `addColumn()` and `createTable()` are the primary migration tools.
- Running the Drift `schema_verifier` tool in CI catches schema drift between code and generated SQL files.

**Migration plan for this spec (v2 → v3)**:
| Change | DDL operation |
|--------|---------------|
| Add `isDeleted` + `deletedAt` to `NoteTable` | `addColumn()` (nullable) |
| Add `isDeleted` + `deletedAt` to `FlashcardTable` | `addColumn()` (nullable) |
| Add `isDeleted` + `deletedAt` to `QuizTable` | `addColumn()` (nullable) |
| Add `isDeleted` + `deletedAt` to `FeynmanSessionTable` | `addColumn()` (nullable) |
| Create `note_fts` virtual table | `customStatement()` |

Note: `FolderTable` already has these columns from the database design (v1).

---

## 6. Sync Queue Design

**Decision**: `SyncQueueItemTable` is the write-ahead log for all offline changes. Every DAO mutation method calls an internal `_enqueue(entityType, entityId, operation, payload)` helper that inserts into `SyncQueueItemTable` within the same database transaction as the data write.

**Rationale**:
- Wrapping the data write and the queue insert in one transaction guarantees atomicity: if either of them fails, both roll back. This prevents "ghost" sync entries with no corresponding data, or data writes with missing sync entries.
- The `SyncQueueDao` exposes `watchPendingItems()` for the sync engine (spec 004) to observe.

**Operation types**: `create`, `update`, `delete`  
**Payload**: JSON-serialized entity snapshot (Drift row → `toJson()`)  
**Status lifecycle**: `pending` → `processing` → `completed` | `failed`

---

## 7. Indexing Strategy

**Decision**: Add explicit indices on frequently queried foreign keys and filter columns.

| Table | Indexed Columns |
|-------|----------------|
| `NoteTable` | `userId`, `folderId`, `isDeleted`, `isArchived` |
| `FlashcardTable` | `userId`, `noteId`, `state`, `dueDate` |
| `QuizTable` | `userId`, `noteId` |
| `FeynmanSessionTable` | `userId`, `noteId` |
| `DailyGoalTable` | `userId`, `date` |
| `SyncQueueItemTable` | `status`, `createdAt` |

**Rationale**: Without indices, list queries on large datasets (10k+ notes) degrade to O(n) scans. With indices, filtered queries are O(log n).

---

## 8. Seed Data Mechanism

**Decision**: A `DatabaseSeeder` class checks if the user's note count is zero on first launch and inserts a predefined sample dataset (1 folder, 2 notes, 5 flashcards matching each note). In production, the seeder is skipped. In development/demo mode, it is triggered from `AppDatabase.migration.onUpgrade` after `onCreate`.

**Rationale**:
- Provides immediate value to new users in demo mode.
- Idempotent: the count check prevents duplicate seeding.
- Does not affect the sync queue (seed data is flagged as pre-synced / remote-origin).

---

## 9. Testing Strategy

**Decision**: Use Drift's `NativeDatabase.memory()` (in-memory SQLite) for unit tests. Each DAO test creates a fresh in-memory database, inserts fixtures, runs assertions, and disposes.

**Rationale**:
- In-memory databases are zero-cost to create and destroy, making per-test isolation fast.
- Drift's `closeAfterTest` extension handles teardown automatically.
- Migration tests use `SchemaVerifier` to compare generated SQL against the stored schema snapshot.

**Test file layout**:
```
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

## 10. Provider Wiring

**Decision**: Each DAO is exposed as a Riverpod `Provider` depending on `databaseProvider`. Feature-level data sources / repositories receive the DAO via constructor injection resolved by Riverpod.

```dart
final noteDaoProvider = Provider<NoteDao>(
  (ref) => NoteDao(ref.read(databaseProvider)),
);
```

**Rationale**: Aligns with Constitution I (dependency injection at composition root) and Constitution V (unidirectional data flow via providers). No singleton DAOs or static access.
