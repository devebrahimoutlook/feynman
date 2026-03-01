# Implementation Plan: Local Database & Offline Storage

**Branch**: `003-local-db-offline-storage` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/003-local-db-offline-storage/spec.md`

## Summary

Extend the existing Drift/SQLite database (built in spec 001) with 9 fully-typed Data Access Objects (DAOs), advance the schema to version 3 (adding soft-delete columns and FTS5 full-text search on notes), wire all DAOs into Riverpod providers, and introduce a seed data mechanism. Every DAO write atomically enqueues a `SyncQueueItem`, creating the offline-write log that spec 004 (Sync Engine) will consume. All DAOs provide reactive `Stream` outputs for Riverpod `StreamProvider` consumption.

## Technical Context

**Language/Version**: Dart ≥ 3.2 (sound null-safety)  
**Primary Dependencies**: Drift 2.x (SQLite), Riverpod 2.x, drift_flutter  
**Storage**: SQLite via Drift (local), schema version 3  
**Testing**: `flutter_test`, `drift` in-memory (`NativeDatabase.memory()`)  
**Target Platform**: Android (SDK 24+), Web (WASM SQLite)  
**Performance Goals**: List queries < 200ms for 10k records; FTS search < 500ms  
**Constraints**: Offline-capable (Constitution II); main-thread safe; 60 fps UI  
**Scale/Scope**: 11 tables, 9 DAOs, ~10 migration steps, ~90 DAO unit tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Clean Architecture** | ✅ PASS | DAOs are data-layer components; features access them via domain abstractions. No DAO imported directly in presentation layer. |
| **II. Offline-First** | ✅ PASS | All reads served from local DB; every write persists locally first + enqueues sync item atomically. |
| **III. TDD** | ✅ PASS | Unit tests written per DAO; migration test validates all schema versions. Coverage target: ≥80% for data layer. |
| **IV. Background Isolation** | ✅ PASS | Drift's query executor runs on a background isolate by default (drift_flutter). No main-thread blocking. |
| **V. Immutable State** | ✅ PASS | Drift-generated row classes are immutable; Riverpod StreamProvider propagates updates reactively. |
| **VI. Security by Default** | ✅ PASS | Local data scoped per-user via `userId` FK on all tables; no plaintext secrets in DB. |
| **VII. Feature-Based Structure** | ✅ PASS | DAOs in `lib/core/database/daos/`; providers in `lib/core/providers/`. Feature data sources receive DAOs through DI. |
| **VIII. Observability** | ✅ PASS | `SyncQueueDao.getPendingCount()` feeds sync status UI; all DAO errors propagate through Riverpod `AsyncError` state. |

**No violations. Complexity Tracking table not required.**

## Project Structure

### Documentation (this feature)

```text
specs/003-local-db-offline-storage/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code

```text
lib/core/database/
├── app_database.dart           # Bump to schemaVersion 3; add migration v2→v3; register DAOs
├── tables/
│   ├── note_table.dart         # + isDeleted BOOL, deletedAt DATETIME (v3)
│   ├── flashcard_table.dart    # + isDeleted BOOL, deletedAt DATETIME (v3)
│   ├── quiz_table.dart         # + isDeleted BOOL, deletedAt DATETIME (v3)
│   └── feynman_session_table.dart  # + isDeleted BOOL, deletedAt DATETIME (v3)
└── daos/                       # NEW
    ├── note_dao.dart
    ├── folder_dao.dart
    ├── flashcard_dao.dart
    ├── quiz_dao.dart
    ├── feynman_session_dao.dart
    ├── achievement_dao.dart
    ├── daily_goal_dao.dart
    ├── streak_dao.dart
    └── sync_queue_dao.dart

lib/core/database/seed/         # NEW
└── database_seeder.dart

lib/core/providers/
└── database_providers.dart     # NEW — DAO Riverpod providers

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
