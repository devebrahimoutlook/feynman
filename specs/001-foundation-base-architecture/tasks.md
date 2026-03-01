# Tasks: Foundation & Base Architecture

**Input**: Design documents from `/specs/001-foundation-base-architecture/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Included â€” Constitution Principle III (Test-Driven Development) mandates automated tests for all production code.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/` for source, `test/` for unit/widget tests, `integration_test/` for integration tests
- Feature modules: `lib/features/<name>/{presentation,domain,data}/`
- Shared infrastructure: `lib/core/<concern>/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Flutter project initialization, dependency configuration, and build tooling

- [x] T001 Create Flutter project scaffold with `flutter create --org com.feynman --project-name feynman --platforms android,web ./`
- [x] T002 Configure `pubspec.yaml` with all dependencies: flutter_riverpod, riverpod_annotation, riverpod_generator, go_router, drift, drift_flutter, sqlite3_flutter_libs, supabase_flutter, freezed_annotation, json_annotation, connectivity_plus, logger, google_fonts, cached_network_image, flutter_secure_storage, path_provider, uuid
- [x] T003 [P] Configure `pubspec.yaml` dev_dependencies: build_runner, drift_dev, riverpod_lint, freezed, json_serializable, custom_lint, flutter_test, integration_test
- [x] T004 [P] Configure `analysis_options.yaml` with strict Dart rules (strict-casts, strict-raw-types, strict-inference), riverpod_lint, and import restriction rules
- [x] T005 [P] Configure `.gitignore` to exclude `.dart_tool/`, `build/`, `*.g.dart`, `.env`, and platform-specific build artifacts
- [x] T006 Create directory structure per implementation plan: `lib/core/{config,database,error,logging,providers,router,theme,widgets}/`, `lib/features/{home,library,progress,settings}/presentation/`, `test/core/{database,error,logging,router,theme}/`, `test/test_helpers/`, `integration_test/`
- [x] T007 Run `flutter pub get` and verify all dependencies resolve without conflicts

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**âš ï¸ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 [P] Create `lib/core/config/app_config.dart` â€” environment configuration class reading `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define` using `String.fromEnvironment`, with runtime validation that values are non-empty
- [x] T009 [P] Create `lib/core/logging/app_logger.dart` â€” centralized structured logger wrapping the `logger` package, exposing severity methods (verbose, debug, info, warning, error, fatal), each accepting a tag string, message, and optional metadata map; use PrettyPrinter in debug mode and JsonPrinter placeholder for production
- [x] T010 [P] Create `lib/core/error/app_exception.dart` â€” base exception hierarchy: `AppException` (abstract), `NetworkException`, `DatabaseException`, `AuthException`, `ProcessingException`, each with message, optional cause, and optional stack trace
- [x] T011 Run `dart run build_runner build --delete-conflicting-outputs` to generate Riverpod provider code and verify zero build errors

**Checkpoint**: Foundation ready â€” user story implementation can now begin in parallel

---

## Phase 3: User Story 1 â€” App Launch & Navigation Shell (Priority: P1) ðŸŽ¯ MVP

**Goal**: The app launches to a navigation shell with bottom navigation containing four tabs (Home, Library, Progress, Settings), displaying the project's brand theme consistently.

**Independent Test**: Launch the app on Android and web. Verify all tabs render, transitions are smooth, and theme is applied uniformly.

### Tests for User Story 1 âš ï¸

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T012 [P] [US1] Create widget test in `test/core/theme/app_theme_test.dart` â€” verify light and dark ThemeData are generated with correct primary colour seed, typography uses Inter font family, spacing constants (4,8,12,16,24,32,48,64) are defined, and border radii (sm=8, md=12, lg=16, xl=24) exist
- [x] T013 [P] [US1] Create widget test in `test/core/router/app_router_test.dart` â€” verify GoRouter config resolves routes for `/home`, `/library`, `/progress`, `/settings`; verify unknown routes are handled; verify `ShellRoute` wraps all four branches
- [x] T014 [P] [US1] Create integration test in `integration_test/app_launch_test.dart` â€” verify app launches, four bottom-nav tabs are visible, tapping each tab navigates to its screen, and cold-start completes within expected time

### Implementation for User Story 1

- [x] T015 [P] [US1] Create `lib/core/theme/app_colors.dart` â€” define `ColorScheme.fromSeed()` with primary seed colour for light and dark modes, plus custom semantic colours (success, warning, info)
- [x] T016 [P] [US1] Create `lib/core/theme/app_typography.dart` â€” define `TextTheme` using `GoogleFonts.interTextTheme()` with display, headline, title, body, and label scales
- [x] T017 [P] [US1] Create `lib/core/theme/app_spacing.dart` â€” define spacing constants (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, xxxxl=64) and border radii (sm=8, md=12, lg=16, xl=24) as static const doubles
- [x] T018 [US1] Create `lib/core/theme/app_theme.dart` â€” compose `ThemeData` for light and dark modes using AppColors, AppTypography, and AppSpacing; expose `lightTheme` and `darkTheme` getters; include Material 3 component overrides (AppBar, Card, BottomNavigationBar, ElevatedButton, InputDecoration)
- [x] T019 [US1] Create `lib/core/router/route_names.dart` â€” define named route constants: `home`, `library`, `progress`, `settings` as static const strings with path values `/home`, `/library`, `/progress`, `/settings`
- [x] T020 [US1] Create placeholder screens: `lib/features/home/presentation/home_screen.dart`, `lib/features/library/presentation/library_screen.dart`, `lib/features/progress/presentation/progress_screen.dart`, `lib/features/settings/presentation/settings_screen.dart` â€” each a `ConsumerWidget` displaying the screen name centred in an empty `Scaffold`
- [x] T021 [US1] Create `lib/core/widgets/scaffold_with_nav_bar.dart` â€” shell widget with `BottomNavigationBar` containing four items (Home=Icons.home, Library=Icons.library_books, Progress=Icons.bar_chart, Settings=Icons.settings), wired to `StatefulNavigationShell` for index switching
- [x] T022 [US1] Create `lib/core/router/app_router.dart` â€” GoRouter configuration using `StatefulShellRoute.indexedStack` with four `StatefulShellBranch` entries routed to the four placeholder screens, wrapped in `ScaffoldWithNavBar`; initial location `/home`; expose as Riverpod provider
- [x] T023 [US1] Create `lib/app.dart` â€” `MaterialApp.router` consuming the GoRouter provider, applying `AppTheme.lightTheme` and `AppTheme.darkTheme` with `themeMode: ThemeMode.system`, setting app title to 'Feynman'
- [x] T024 [US1] Create `lib/main.dart` â€” entry point calling `WidgetsFlutterBinding.ensureInitialized()`, then `runApp(ProviderScope(child: FeynmanApp()))`
- [x] T025 [US1] Create `test/test_helpers/test_app.dart` â€” reusable test wrapper that provides `ProviderScope` + `MaterialApp` with theme + GoRouter for widget tests
- [x] T026 [US1] Run all US1 tests (`flutter test test/core/theme/ test/core/router/`) and verify they pass

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently â€” the app launches with themed navigation shell

---

## Phase 4: User Story 2 â€” Offline-Ready Local Database (Priority: P1)

**Goal**: The local SQLite database is initialized on first launch with the full schema for all 11 entities. The app launches without errors when offline.

**Independent Test**: Enable airplane mode, launch the app, verify no crashes. Query the database file to confirm all tables exist.

### Tests for User Story 2 âš ï¸

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T027 [P] [US2] Create unit test in `test/core/database/app_database_test.dart` â€” verify database creation produces all 11 tables (user_profile, folder, note, flashcard, quiz, quiz_question, feynman_session, achievement, daily_goal, streak, sync_queue_item); verify schema version equals 1; verify database reopens without re-creating tables

### Implementation for User Story 2

- [x] T028 [P] [US2] Create `lib/core/database/tables/user_profile_table.dart` â€” Drift table definition with columns: id (text PK), email (text NOT NULL), display_name (text nullable), avatar_url (text nullable), level (integer default 1), total_xp (integer default 0), created_at (dateTime), updated_at (dateTime), version (integer default 1)
- [x] T029 [P] [US2] Create `lib/core/database/tables/folder_table.dart` â€” Drift table: id (text PK), user_id (text FK), name (text), color (text default '#4A9EFF'), icon (text nullable), sort_order (integer default 0), is_deleted (boolean default false), deleted_at (dateTime nullable), created_at, updated_at, version
- [x] T030 [P] [US2] Create `lib/core/database/tables/note_table.dart` â€” Drift table: id (text PK), user_id (text FK), folder_id (text nullable FK), title (text), source_type (text), source_url (text nullable), summary (text nullable), content (text nullable), definitions (text nullable), examples (text nullable), tags (text nullable), is_pinned (boolean default false), is_archived (boolean default false), processing_status (text default 'pending'), created_at, updated_at, version
- [x] T031 [P] [US2] Create `lib/core/database/tables/flashcard_table.dart` â€” Drift table: id (text PK), note_id (text FK), user_id (text FK), front (text), back (text), hint (text nullable), state (text default 'new'), ease_factor (real default 2.5), interval_days (integer default 0), repetition_count (integer default 0), lapse_count (integer default 0), due_date (dateTime nullable), created_at, updated_at, version
- [x] T032 [P] [US2] Create `lib/core/database/tables/quiz_table.dart` â€” Drift table: id (text PK), note_id (text FK), user_id (text FK), title (text), best_score (real nullable), attempt_count (integer default 0), created_at, updated_at, version
- [x] T033 [P] [US2] Create `lib/core/database/tables/quiz_question_table.dart` â€” Drift table: id (text PK), quiz_id (text FK), question_text (text), question_type (text), options (text nullable), correct_answer (text), explanation (text nullable), difficulty (text default 'medium'), created_at
- [x] T034 [P] [US2] Create `lib/core/database/tables/feynman_session_table.dart` â€” Drift table: id (text PK), note_id (text FK), user_id (text FK), topic (text), input_type (text), explanation (text nullable), audio_url (text nullable), clarity_score (real nullable), accuracy_score (real nullable), structure_score (real nullable), examples_score (real nullable), feedback (text nullable), attempt_number (integer default 1), created_at, version
- [x] T035 [P] [US2] Create `lib/core/database/tables/achievement_table.dart` â€” Drift table: id (text PK), user_id (text FK), badge_type (text), earned_at (dateTime), version
- [x] T036 [P] [US2] Create `lib/core/database/tables/daily_goal_table.dart` â€” Drift table: id (text PK), user_id (text FK), notes_target (integer default 1), flashcards_target (integer default 10), study_minutes_target (integer default 15), date (text), notes_completed (integer default 0), flashcards_completed (integer default 0), study_minutes_completed (integer default 0), created_at, updated_at, version
- [x] T037 [P] [US2] Create `lib/core/database/tables/streak_table.dart` â€” Drift table: id (text PK), user_id (text FK unique), current_streak (integer default 0), longest_streak (integer default 0), last_activity_date (text nullable), total_study_time_minutes (integer default 0), created_at, updated_at, version
- [x] T038 [P] [US2] Create `lib/core/database/tables/sync_queue_item_table.dart` â€” Drift table: id (integer PK autoincrement), entity_type (text), entity_id (text), operation (text), payload (text), status (text default 'pending'), retry_count (integer default 0), created_at (dateTime), processed_at (dateTime nullable)
- [x] T039 [US2] Create `lib/core/database/app_database.dart` â€” Drift `@DriftDatabase` class referencing all 11 tables, schemaVersion = 1, with `MigrationStrategy` containing `onCreate` callback, LazyDatabase opener using `path_provider` for native and WasmDatabase for web
- [x] T040 [US2] Create `lib/core/providers/database_provider.dart` â€” Riverpod provider exposing `AppDatabase` as a singleton; include `keepAlive` to prevent disposal
- [x] T041 [US2] Run code generation `dart run build_runner build --delete-conflicting-outputs` and verify `app_database.g.dart` generates without errors
- [x] T042 [US2] Update `lib/main.dart` to initialize database provider before `runApp` (ensure DB is bootstrapped on launch)
- [x] T043 [US2] Run US2 tests (`flutter test test/core/database/`) and verify they pass

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently â€” themed shell with local database bootstrapped

---

## Phase 5: User Story 3 â€” Supabase Backend Connectivity (Priority: P2)

**Goal**: The app initializes Supabase client SDKs using environment-injected credentials. If Supabase is unreachable, the app degrades gracefully to offline mode.

**Independent Test**: Launch with valid credentials and verify log readiness messages. Launch with invalid URL and verify no crash.

### Tests for User Story 3 âš ï¸

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T044 [P] [US3] Create unit test in `test/core/providers/supabase_provider_test.dart` â€” verify SupabaseProvider returns a valid client when credentials are configured; verify graceful fallback (null or offline state) when initialization fails; verify no secrets in test code (use mock/fake values)

### Implementation for User Story 3

- [x] T045 [US3] Create `lib/core/providers/supabase_provider.dart` â€” Riverpod provider that calls `Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey)` inside a try-catch; on success expose `Supabase.instance.client`; on failure log the error via AppLogger and expose a null/offline sentinel; mark as `keepAlive`
- [x] T046 [US3] Create `lib/core/providers/connectivity_provider.dart` â€” Riverpod `StreamProvider` wrapping `Connectivity().onConnectivityChanged` from connectivity_plus; expose current connectivity state (connected/disconnected) for downstream providers
- [x] T047 [US3] Update `lib/main.dart` to call `await Supabase.initialize(...)` wrapped in try-catch before `runApp`; pass credentials from `AppConfig`; log initialization result via `AppLogger`
- [x] T048 [US3] Update `lib/core/config/app_config.dart` to add `isOfflineMode` computed getter that checks if Supabase client is null or connectivity is unavailable
- [x] T049 [US3] Run US3 tests (`flutter test test/core/providers/supabase_provider_test.dart`) and verify they pass

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 â€” Structured Error Handling & Logging (Priority: P2)

**Goal**: Unhandled exceptions are caught by error boundaries displaying a branded fallback screen. All errors are logged with structured metadata.

**Independent Test**: Throw an exception in a test screen. Verify fallback renders, retry works, and log output contains expected fields.

### Tests for User Story 4 âš ï¸

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T050 [P] [US4] Create widget test in `test/core/error/error_boundary_test.dart` â€” verify: (a) when child widget throws, the fallback error screen renders with "Something went wrong" message and a "Retry" button; (b) tapping Retry re-renders the child successfully; (c) the error callback is invoked with error details
- [x] T051 [P] [US4] Create unit test in `test/core/logging/app_logger_test.dart` â€” verify: (a) log output contains timestamp, severity, tag, and message fields; (b) info/warning/error methods produce correct severity levels; (c) metadata map is included when provided

### Implementation for User Story 4

- [x] T052 [US4] Create `lib/core/error/fallback_error_screen.dart` â€” branded error screen widget displaying app icon, "Something went wrong" title, error description (if available), and a "Retry" `ElevatedButton`; styled with `AppTheme` tokens
- [x] T053 [US4] Create `lib/core/error/error_boundary.dart` â€” stateful widget wrapping `child` in an error zone; catches `FlutterError` via `ErrorWidget.builder` override and platform exceptions; on error, renders `FallbackErrorScreen` with retry callback that resets state and re-renders child; logs error via `AppLogger` with timestamp, route, error type, message, and stack trace
- [x] T054 [US4] Create `lib/core/providers/logger_provider.dart` â€” Riverpod provider exposing `AppLogger` singleton
- [x] T055 [US4] Update `lib/core/router/app_router.dart` to wrap each `StatefulShellBranch` builder content in `ErrorBoundary` widget
- [x] T056 [US4] Update `lib/main.dart` to set `FlutterError.onError` and `PlatformDispatcher.instance.onError` callbacks that delegate to `AppLogger.error`
- [x] T057 [US4] Run US4 tests (`flutter test test/core/error/ test/core/logging/`) and verify they pass

**Checkpoint**: At this point, User Stories 1â€“4 should all work independently

---

## Phase 7: User Story 5 â€” Dependency Injection Ready for Feature Teams (Priority: P3)

**Goal**: New feature modules can declare Riverpod providers that depend on core providers (logger, database, Supabase) without modifying shared infrastructure code.

**Independent Test**: Create a sample provider depending on core providers. Verify it resolves at runtime.

### Tests for User Story 5 âš ï¸

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T058 [P] [US5] Create integration test in `test/core/providers/di_integration_test.dart` â€” verify: (a) a sample feature provider depending on database + logger providers resolves correctly within a ProviderScope; (b) providers are accessible without manual registration; (c) modifying Presentation imports to include Data-layer symbols triggers lint warning (if custom_lint configured)

### Implementation for User Story 5

- [x] T059 [US5] Verify and document the provider dependency graph: `databaseProvider` â†’ standalone; `supabaseProvider` â†’ depends on `appConfig`; `loggerProvider` â†’ standalone; `routerProvider` â†’ standalone; ensure no circular dependencies exist in `lib/core/providers/`
- [x] T060 [US5] Create `lib/core/providers/providers.dart` â€” barrel file exporting all core providers (database, supabase, logger, connectivity, router) for convenient single-import in feature modules
- [x] T061 [US5] Create a sample feature provider at `test/core/providers/sample_feature_provider.dart` â€” annotated Riverpod provider depending on `databaseProvider` and `loggerProvider` to validate composition-root pattern works end-to-end
- [x] T062 [US5] Run US5 tests (`flutter test test/core/providers/di_integration_test.dart`) and verify they pass

**Checkpoint**: All user stories should now be independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T063 [P] Run full test suite: `flutter test` â€” verify all unit and widget tests pass (target: zero failures)
- [x] T064 [P] Run integration tests: `flutter test integration_test/` â€” verify app launch smoke test passes
- [x] T065 [P] Run lint and format gates: `dart analyze --fatal-infos` and `dart format --set-exit-if-changed .` â€” verify zero issues
- [x] T066 Run code generation one final time: `dart run build_runner build --delete-conflicting-outputs` â€” verify all generated code is up to date
- [x] T067 [P] Verify secret scanning: search entire codebase for hardcoded Supabase URLs or keys â€” verify zero matches in committed `.dart` files
- [x] T068 [P] Create `.env.example` at project root documenting required `--dart-define` variables (SUPABASE_URL, SUPABASE_ANON_KEY) with placeholder values
- [x] T069 Verify offline launch: build and run app with no network â€” verify app opens to navigation shell without error dialogs or spinners
- [x] T070 Run `quickstart.md` validation: follow every step in quickstart.md on a clean checkout â€” verify all steps succeed without modification

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies â€” can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion â€” BLOCKS all user stories
- **US1 â€“ Navigation Shell (Phase 3)**: Depends on Foundational
- **US2 â€“ Local Database (Phase 4)**: Depends on Foundational
- **US3 â€“ Supabase Connectivity (Phase 5)**: Depends on Foundational + US1 (for main.dart structure)
- **US4 â€“ Error Handling (Phase 6)**: Depends on US1 (for router wrapping) + US2 (indirectly, for logger)
- **US5 â€“ DI Ready (Phase 7)**: Depends on US2 + US3 + US4 (needs all core providers to exist)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational â€” no dependencies on other stories
- **US2 (P1)**: Can start after Foundational â€” no dependencies on US1 (parallel)
- **US3 (P2)**: Needs `main.dart` from US1 â€” start after US1
- **US4 (P2)**: Needs router from US1 and logger from Foundational â€” start after US1
- **US5 (P3)**: Needs all core providers â€” start after US2 + US3 + US4

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Table definitions before database class (US2)
- Providers before consumers
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002 + T003 + T004 + T005: All setup config tasks are parallel
- T008 + T009 + T010: All foundational tasks are parallel
- T012 + T013 + T014: All US1 tests are parallel
- T015 + T016 + T017: All US1 theme tokens are parallel
- T028â€“T038: All 11 table definitions are parallel
- T044 + T050 + T051: Tests across US3/US4 are parallel (if US1 is done)
- US1 and US2 can run in parallel after Foundational

---

## Parallel Examples

### US1 â€“ Theme Tokens (parallel):

```bash
Task: "Create app_colors.dart"           â†’ lib/core/theme/app_colors.dart
Task: "Create app_typography.dart"       â†’ lib/core/theme/app_typography.dart
Task: "Create app_spacing.dart"          â†’ lib/core/theme/app_spacing.dart
```

### US2 â€“ Table Definitions (parallel):

```bash
Task: "Create user_profile_table.dart"   â†’ lib/core/database/tables/user_profile_table.dart
Task: "Create folder_table.dart"         â†’ lib/core/database/tables/folder_table.dart
Task: "Create note_table.dart"           â†’ lib/core/database/tables/note_table.dart
# ... all 11 table files in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 â€” Navigation Shell
4. **STOP and VALIDATE**: Test US1 independently â€” app launches with themed tabs
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational â†’ Foundation ready
2. Add US1 (Navigation Shell) â†’ Test â†’ Demo (MVP!)
3. Add US2 (Local Database) â†’ Test â†’ Schema bootstrapped
4. Add US3 (Supabase) â†’ Test â†’ Backend connectivity
5. Add US4 (Error Handling) â†’ Test â†’ Resilient app
6. Add US5 (DI Ready) â†’ Test â†’ Architecture validated
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Navigation Shell)
   - Developer B: US2 (Local Database)
3. After US1 completes:
   - Developer A: US3 (Supabase) then US4 (Error Handling)
4. After all except US5:
   - Developer A or B: US5 (DI Validation)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

---

## TDD Process Note *(audit finding G6)*

Constitution Principle III mandates a Red-Green-Refactor cycle. Because this feature was developed without a commit-per-task discipline, the test-first sequence cannot be verified retroactively from git history. Tests do exist and pass, but for **future features (002+)** TDD compliance MUST be enforced at commit level:

1. Commit the failing test (`test: add failing test for <X>`)
2. Commit the minimal implementation (`feat: implement <X>`)
3. Commit the refactor (`refactor: clean up <X>`)

---

## Technical Debt

| ID | Description | Priority | Status |
|----|-------------|----------|--------|
| TD001 | Implement a custom lint package enforcing Presentation→Domain import boundary (G1 — [analysis_options.yaml](../../analysis_options.yaml) has `custom_lint` enabled, but file-path-level enforcement requires a separate plugin) | Medium | Pending |


