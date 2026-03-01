# Feature Specification: Local Database & Offline Storage

**Feature Branch**: `003-local-db-offline-storage`  
**Created**: 2026-03-01  
**Status**: Draft  
**Input**: User description: "Local Database & Offline Storage"

## User Scenarios & Testing *(mandatory)*

### User Story 1 – Offline Data Access (Priority: P1)

A user opens the app while commuting underground with no internet connection. All their notes, flashcards, quizzes, and learning sessions are immediately available for reading and browsing. The app does not display connection-error messages; it simply works from the local database.

**Why this priority**: Offline reading is the most fundamental value proposition. Without reliable local data access, users cannot study on-the-go — the core use case of a learning app. Constitution Principle II makes this non-negotiable.

**Independent Test**: With the device in airplane mode, browse all entity types (notes, folders, flashcards, quizzes, sessions, achievements, streaks, goals) from local storage. All data appears instantly without loading spinners or error states.

**Acceptance Scenarios**:

1. **Given** the app has previously synced data while online, **When** the user opens the app in airplane mode, **Then** all notes, folders, flashcards, quizzes, and sessions are displayed within 200ms.
2. **Given** the app has never synced (first-time user offline), **When** the user opens the app, **Then** appropriate empty-state messages are shown for each entity type — no crashes or error screens.
3. **Given** the user has hundreds of notes and thousands of flashcards stored locally, **When** they browse or search, **Then** results load within 500ms with smooth 60fps scrolling.

---

### User Story 2 – Offline Data Creation & Editing (Priority: P1)

A user creates a new note, edits a flashcard, or records a quiz result while offline. The changes are persisted immediately to the local database. Once the device regains connectivity, these changes are queued for synchronization automatically — the user doesn't need to take any action.

**Why this priority**: Write capability offline is equally critical to read. Users must be able to study (record quiz scores, review flashcards, create notes) without connectivity. This also provides the foundation for the sync engine (spec 004).

**Independent Test**: While offline, create a note, edit its title, add it to a folder, create flashcards against it, and record a quiz attempt. Kill and restart the app — all changes persist. Go online — changes appear in the sync queue ready for upload.

**Acceptance Scenarios**:

1. **Given** the user is offline, **When** they create a new note, **Then** the note is persisted locally and appears in listsimmediately.
2. **Given** the user is offline, **When** they edit an existing flashcard's front/back text, **Then** the updated flashcard persists and a sync queue entry is created for later upload.
3. **Given** the user is offline and creates several items, **When** the app is force-closed and reopened, **Then** all offline changes are retained with no data loss.
4. **Given** the user has pending offline changes, **When** network connectivity is restored, **Then** the sync queue contains all pending operations in chronological order, ready for the sync engine (spec 004) to process.

---

### User Story 3 – Schema Migrations & Data Integrity (Priority: P2)

When a new version of the app is installed, the local database schema migrates automatically without data loss. Users never see a migration prompt or experience corruption. The migration runs silently on first launch of the updated version.

**Why this priority**: Without reliable migrations, app updates risk wiping user data. This is foundational for long-term maintenance and all future features that extend the schema.

**Independent Test**: Pre-populate a database at schema version N, then run the app at version N+1. Verify all existing data survives intact and new columns/tables are created correctly.

**Acceptance Scenarios**:

1. **Given** an existing app installation with user data at schema version N, **When** the app updates to version N+1 with new tables or columns, **Then** all existing data is preserved and the new schema elements are created.
2. **Given** a migration is in progress, **When** the app is interrupted (force-close, battery death), **Then** the migration resumes or rolls back cleanly on next launch without corruption.
3. **Given** a fresh installation with no prior data, **When** the app launches for the first time, **Then** the complete current schema is created in one pass.

---

### User Story 4 – Data Access Object (DAO) Contracts (Priority: P2)

All features in the app access local data through well-defined DAO contracts. Each entity type has a DAO that provides standard CRUD operations, query filters, and reactive data streams. Feature developers never write raw SQL; they consume clean, type-safe DAO interfaces.

**Why this priority**: DAOs enforce Clean Architecture (Principle I) and provide the interface that every downstream feature (notes, flashcards, quizzes, etc.) depends on. Without DAOs, features would couple directly to the database implementation.

**Independent Test**: Call each DAO method (insert, update, delete, query, watch) in isolation and verify correct behaviour through unit tests.

**Acceptance Scenarios**:

1. **Given** a DAO for Notes, **When** a new note is inserted, **Then** the DAO returns the created entity and it can be retrieved by ID.
2. **Given** a DAO that supports reactive watching, **When** a record is inserted or updated, **Then** all active watchers receive the updated result set automatically.
3. **Given** a DAO used to query records with filters, **When** the caller requests notes by folder or flashcards by state, **Then** only matching records are returned.
4. **Given** a DAO for any entity, **When** a record is deleted, **Then** the entity is soft-deleted (retains the row with a deletion marker) for sync purposes and no longer appears in regular queries.

---

### User Story 5 – Seed & Sample Data (Priority: P3)

On first launch (or in development/demo mode), the app can optionally populate the database with sample data so that new users see a non-empty experience and developers can test features without manual data entry.

**Why this priority**: While not critical for production, seed data dramatically accelerates development and improves the first-run experience if onboarding uses sample content.

**Independent Test**: Trigger seed data insertion in a test environment. Verify that sample notes, folders, and flashcards exist and are valid.

**Acceptance Scenarios**:

1. **Given** a freshly installed app in demo mode, **When** the app launches, **Then** sample data (at least one folder, two notes, and five flashcards) is created.
2. **Given** an app that has already been seeded, **When** the seed process is triggered again, **Then** it does not duplicate data.

---

### Edge Cases

- What happens when the local database file becomes corrupted? → The app detects corruption on open and presents a recovery option (re-sync from remote or start fresh), never silently losing data.
- How does the system handle extremely large datasets (10,000+ notes, 50,000+ flashcards)? → Queries use pagination and indexed columns. Bulk operations run in transactions to prevent partial writes.
- What happens when disk space is critically low? → Write operations catch disk-full errors and present a user-friendly message suggesting clearing space, rather than crashing.
- What happens when two conflicting versions of the same record exist locally (e.g., interrupted migration)? → The `version` column on each entity ensures the latest write is identifiable; conflict resolution is deferred to spec 004.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST serve all reads from the local database, never requiring network access for data retrieval.
- **FR-002**: System MUST persist all write operations (create, update, delete) to the local database immediately, even when offline.
- **FR-003**: System MUST enqueue every write operation into the `SyncQueueItem` table with the entity type, entity ID, operation type, serialized payload, and timestamp.
- **FR-004**: System MUST provide a typed DAO for each entity: Notes, Folders, Flashcards, Quizzes, QuizQuestions, FeynmanSessions, Achievements, DailyGoals, and Streaks. *(Note: UserProfile DAO is owned by spec 002 — Auth & User Management. This spec covers the remaining 9 entities.)*
- **FR-005**: Each DAO MUST support: insert, update, soft-delete, get-by-ID, list-all-for-user, and watch (reactive stream).
- **FR-006**: Each DAO MUST support filtered queries relevant to the entity (e.g., notes by folder, flashcards by state/due-date, sessions by note).
- **FR-007**: System MUST support schema migrations that run automatically on app launch, preserving all existing data.
- **FR-008**: System MUST use database transactions for all multi-step write operations to guarantee atomicity.
- **FR-009**: System MUST maintain a `version` integer on all syncable entities, incrementing it on each local write for optimistic concurrency control.
- **FR-010**: Soft-deleted records MUST be retained in the database with a `isDeleted` flag and `deletedAt` timestamp, and excluded from standard DAO queries.
- **FR-011**: System MUST support full-text search on note titles and content.
- **FR-012**: System MUST provide a seed-data mechanism for development and demo environments.
- **FR-013**: System MUST handle database corruption gracefully, presenting recovery options rather than crashing.

### Key Entities

- **Note**: A piece of learning content with title, body, AI-generated summary, definitions, examples, tags, source metadata, processing status, and folder assignment. Supports pinning and archiving.
- **Folder**: An organizational container for notes with a name, user-assigned color, icon, and sort order. Supports soft-delete.
- **Flashcard**: A front/back study card linked to a note, with spaced-repetition metadata (ease factor, interval, state, due date, repetition count, lapse count).
- **Quiz**: An assessment linked to a note, with a title, best score, and attempt count. *(Time taken and difficulty are per-question attributes handled in QuizQuestion, not at the Quiz level.)*
- **QuizQuestion**: An individual question within a quiz, with question text, answer options, correct answer, and the user's response.
- **FeynmanSession**: A Feynman Technique session linked to a note, with modality (text/voice), transcript, AI scores across four dimensions, and overall mastery score.
- **Achievement**: A badge/milestone earned by the user, identified by a `badgeType` code and an `earnedAt` timestamp. *(Rich metadata such as display name, description, icon, and XP value are defined in a static catalogue in the domain layer, not stored per-row in the database.)*
- **DailyGoal**: A daily study record with three parallel targets and progress counters — notes (target + completed), flashcards (target + completed), and study minutes (target + completed) — keyed by user and ISO 8601 date string.
- **Streak**: A consecutive-day engagement record with start date, current length, and longest historical length.
- **SyncQueueItem**: A pending synchronization operation with entity type, entity ID, operation type (create/update/delete), serialized payload, status, retry count, and timestamps.
- **UserProfile**: The authenticated user's profile with display name, email, avatar URL, auth provider, and email verification status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All entity types (notes, folders, flashcards, quizzes, sessions, achievements, goals, streaks) are readable within 200ms when offline — no loading spinners or network dependency.
- **SC-002**: Users can create, edit, and delete any entity while offline, and all changes survive app restarts with zero data loss.
- **SC-003**: Every offline write automatically creates a corresponding sync queue entry without user intervention.
- **SC-004**: Schema migrations complete in under 5 seconds for databases with up to 10,000 records, preserving 100% of existing data.
- **SC-005**: Each DAO provides reactive streams so that UI updates automatically when underlying data changes — no manual refresh needed.
- **SC-006**: The database supports up to 30 days of offline-only operation without data loss or degradation (per Constitution: Max Offline Gap).
- **SC-007**: Unit test coverage for all DAOs and migration logic reaches at least 80%.
- **SC-008**: Full-text search returns relevant results within 500ms for databases with up to 10,000 notes.

## Assumptions

- The Drift (SQLite) database bootstrap and `AppDatabase` class already exist from spec 001 (Foundation) and are ready for extension with DAOs and migrations.
- All 11 table definitions (UserProfile, Folder, Note, Flashcard, Quiz, QuizQuestion, FeynmanSession, Achievement, DailyGoal, Streak, SyncQueueItem) are already implemented in the codebase.
- This spec covers the local persistence layer only. Remote synchronization logic (upload, download, conflict resolution) belongs to spec 004.
- Seed data is for development convenience and demo mode; production onboarding is covered in spec 016.
- Full-text search uses SQLite's FTS capabilities via Drift, not an external search service.
