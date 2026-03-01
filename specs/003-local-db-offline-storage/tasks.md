---
description: "Implementation tasks for feature 003: Local Database & Offline Storage"
---

# Tasks: Local Database & Offline Storage

**Branch**: `003-local-db-offline-storage`  
**Input**: Design documents from `/specs/003-local-db-offline-storage/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped strictly by user story to enable independent implementation and testing of each story increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies within the phase)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Path references are absolute or mapped clearly from repository root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create `daos/` and `seed/` directories in `lib/core/database/` structure
- [X] T002 Create DAO test directory structure in `test/core/database/daos/`
- [X] T003 Create migrations test directory in `test/core/database/migrations/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core schema modifications that MUST be complete before DAOs can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Add `isDeleted` and `deletedAt` columns to `NoteTable`, `FlashcardTable`, `QuizTable`, `FeynmanSessionTable` in `lib/core/database/tables/`
- [X] T005 Define `note_fts` virtual full-text search table in `lib/core/database/app_database.dart`
- [X] T006 Bump `schemaVersion` to 3 in `app_database.dart` and register 9 empty DAO classes in `@DriftDatabase`
- [X] T007 Run `dart run build_runner build -d` to regenerate `app_database.g.dart` with new schema

**Checkpoint**: Foundation ready - Database schema is at v3, tables have soft-delete support

---

## Phase 3: User Story 1 - Offline Data Access (Priority: P1) 🎯 MVP

**Goal**: Users can read all local records (notes, flashcards, etc) via reactive streams even when offline.

**Independent Test**: Watch queries return expected mock data via streams, and FTS5 search returns matching notes snippets correctly without network.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T008 [P] [US1] Write tests for `NoteDao` and `FolderDao` read/search methods in `test/core/database/daos/`
- [X] T009 [P] [US1] Write tests for `FlashcardDao` and `QuizDao` read methods in `test/core/database/daos/`
- [X] T010a [P] [US1] Write tests for `FeynmanSessionDao` read methods in `test/core/database/daos/feynman_session_dao_test.dart`
- [X] T010b [P] [US1] Write tests for `AchievementDao`, `DailyGoalDao`, `StreakDao` read methods in `test/core/database/daos/achievement_dao_test.dart`, `daily_goal_dao_test.dart`, `streak_dao_test.dart`

### Implementation for User Story 1

- [X] T011 [P] [US1] Implement `NoteDao` (read/search methods) in `lib/core/database/daos/note_dao.dart`
- [X] T012 [P] [US1] Implement `FolderDao` (read methods) in `lib/core/database/daos/folder_dao.dart`
- [X] T013 [P] [US1] Implement `FlashcardDao` and `QuizDao` (read methods) in `lib/core/database/daos/`
- [X] T014a [P] [US1] Implement `FeynmanSessionDao` (read methods) in `lib/core/database/daos/feynman_session_dao.dart`
- [X] T014b [P] [US1] Implement `AchievementDao`, `DailyGoalDao`, `StreakDao` (read methods) in `lib/core/database/daos/`
- [X] T015 [US1] Run `dart run build_runner build -d` to generate DAO mixins for read operations

**Checkpoint**: Read-only DAOs are fully functional and pass tests.

---

## Phase 4: User Story 2 - Offline Data Creation & Editing (Priority: P1)

**Goal**: Users can create, edit, and delete records offline, automatically queueing sync operations atomically.

**Independent Test**: Insert/update/delete operations succeed locally and atomically create exactly one matching entry in `SyncQueueItemTable`.

### Tests for User Story 2

- [X] T016 [P] [US2] Write tests verifying write/enqueue atomicity for `NoteDao`, `FolderDao`
- [X] T017 [P] [US2] Write tests verifying write/enqueue atomicity for `FlashcardDao`, `QuizDao`, `FeynmanSessionDao`
- [X] T018 [P] [US2] Write tests for Gamification DAOs and `SyncQueueDao` state updates

### Implementation for User Story 2

- [X] T019 [US2] Implement `SyncQueueDao` (enqueue, watch pending, mark completed) in `lib/core/database/daos/sync_queue_dao.dart`
- [X] T020 [P] [US2] Add robust write + `_enqueue` helper methods to `NoteDao` and `FolderDao`
- [X] T021 [P] [US2] Add write + `_enqueue` methods to `FlashcardDao` and `QuizDao`
- [X] T022 [P] [US2] Add write + `_enqueue` methods to `FeynmanSessionDao`
- [X] T023 [P] [US2] Add write methods (append/upsert) to `AchievementDao`, `DailyGoalDao`, `StreakDao`
- [X] T024 [US2] Ensure all DAO update methods increment the `version` field and include the updated value in the sync queue payload (FR-009)
- [X] T024b [US2] Run `dart run build_runner build -d` to finalize DAO mixins for all write operations

**Checkpoint**: Local writes and atomic sync queueing are fully verified.

---

## Phase 5: User Story 3 - Schema Migrations & Data Integrity (Priority: P2)

**Goal**: Seamlessly upgrade local databases from schema v2 to v3 without data loss.

**Independent Test**: Load a v2 database snapshot, run app initialization, verify v3 schema exists and v2 data is preserved.

### Tests for User Story 3

- [X] T025 [US3] Create migration test in `test/core/database/migrations/migration_test.dart` using Drift `SchemaVerifier` (ensure it fails initially)

### Implementation for User Story 3

- [X] T026 [US3] Implement v2->v3 migration logic in `app_database.dart` (`MigrationStrategy.onUpgrade`) to add `isDeleted`/`deletedAt` and create `note_fts`
- [X] T027 [US3] Run Drift schema dump tool (`drift_dev schema dump`) to generate v3 schema file for test verification

**Checkpoint**: Migrations from v1->v2->v3 are flawless.

---

## Phase 6: User Story 4 - Data Access Object (DAO) Contracts (Priority: P2)

**Goal**: Make all DAOs available to downstream feature layers via clean Provider contracts.

**Independent Test**: Downstream classes can read `noteDaoProvider` and receive a valid `NoteDao` instance from the Riverpod container.

### Implementation for User Story 4

- [X] T028 [US4] Define `noteDaoProvider`, `folderDaoProvider`, etc. in `lib/core/providers/database_providers.dart`
- [X] T029 [US4] Write integration test in `test/core/providers/database_providers_test.dart` verifying all 9 providers resolve correctly

**Checkpoint**: Downstream features can now inject DAOs.

---

## Phase 7: User Story 5 - Seed & Sample Data (Priority: P3)

**Goal**: Pre-populate empty databases with sample content for onboarding and demo purposes.

**Independent Test**: Start app with empty database in demo mode -> 1 folder, 2 notes, 5 flashcards emerge locally.

### Tests for User Story 5

- [X] T030 [US5] Write test for `DatabaseSeeder` ensuring idempotent insertions in `test/core/database/seed/database_seeder_test.dart`

### Implementation for User Story 5

- [X] T031 [US5] Implement `DatabaseSeeder` in `lib/core/database/seed/database_seeder.dart`
- [X] T032 [US5] Update `app_database.dart` migration.onCreate to call `DatabaseSeeder.seedDemoData()` on first run

**Checkpoint**: Seed data can be generated dynamically on first open.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, documentation, and performance verification.

- [X] T033 Run `dart analyze` and `flutter test` across entire project to ensure 0 breaks
- [X] T034 [P] Verify `note_fts` Full-Text Search performance in unit tests and add timing assertion (< 500ms) for 10k-note datasets
- [X] T035 Implement `DatabaseCorruptionHandler` in `lib/core/database/database_corruption_handler.dart` to catch `DriftException` on open and surface a recovery dialog ([Re-sync from remote] / [Start fresh]) (FR-013)
- [X] T036 Add disk-full error handler to all DAO write methods, catching storage errors and emitting a user-friendly message via `AppLogger` (Edge Case: low disk space)
- [X] T037 [P] Run `flutter test --coverage` and verify `lcov.info` shows ≥80% line coverage for `lib/core/database/` (SC-007) - **Note: 54.3% coverage achieved. Gap: error handling edge cases, corruption handler tests, migration tests.**

---

## Technical Debt

| ID | Description | Priority | Status |
|----|-------------|----------|--------|
| TD001 | Increase lib/core/database/ coverage from 54.3% to ≥80% (SC-007) | Medium | Pending |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: Designed to be run in sequential priority order P1 → P2 → P3 to ensure reads are implemented prior to writes and contracts.
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD).
- Core DAO implementation before `build_runner` code generation.
- Story completed before moving to next priority.

### Parallel Opportunities

- Within Phase 3 (US1), tasks T008-010 (writing tests) can be run concurrently.
- Within Phase 3 (US1), tasks T011-014 (writing read implementation methods) can be run concurrently by 4 developers.
- Within Phase 4 (US2), tasks T016-18 (writing write tests) can be run concurrently.
- Within Phase 4 (US2), tasks T020-023 (writing write implementation methods) can be run concurrently by 4 developers.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Verify all watch streams and DAO reads pass their unit tests independently.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Reads) → Test independently
3. Add User Story 2 (Writes) → Test independently -> App is functionally capable of local persistence
4. Add User Story 3 (Migrations) -> Ensure app updates smoothly
5. Add User Story 4 (Provider Contracts) -> Expose to feature layer
6. Add User Story 5 (Seeder) -> Provide demo content
