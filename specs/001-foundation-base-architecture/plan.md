# Implementation Plan: Foundation & Base Architecture

**Branch**: `001-foundation-base-architecture` | **Date**: 2026-02-27 | **Spec**: [spec.md](file:///d:/opus%20projects/specs/001-foundation-base-architecture/spec.md)
**Input**: Feature specification from `/specs/001-foundation-base-architecture/spec.md`

## Summary

Scaffold the Feynman Flutter project with Clean Architecture layers, Riverpod
DI, GoRouter navigation, Material 3 theming, Drift local database with full
schema, Supabase client initialization with offline fallback, error boundaries,
and structured logging. This foundation enables all 17 downstream features to
build atop a consistent, constitution-compliant architecture.

## Technical Context

**Language/Version**: Dart ≥ 3.2 with sound null-safety
**Primary Dependencies**: Flutter SDK, Riverpod (riverpod_generator), GoRouter,
Drift (drift_flutter), Supabase Flutter SDK, freezed, json_serializable,
connectivity_plus, logger, google_fonts, cached_network_image
**Storage**: Drift/SQLite (local), Supabase PostgreSQL (remote — init only)
**Testing**: flutter_test (unit + widget), integration_test (integration)
**Target Platform**: Android SDK 24+, Web (Chrome/Firefox/Safari/Edge latest 2)
**Project Type**: Mobile + Web cross-platform application
**Performance Goals**: 60 fps sustained, <2s cold start on Pixel 4a, <1s on web
**Constraints**: Offline-capable, <100 MB APK, zero secrets in VCS

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Clean Architecture | Feature-first structure with `presentation/domain/data` per module | ✅ Pass |
| II. Offline-First | Drift DB bootstrapped; reads from local; Supabase optional | ✅ Pass |
| III. Test-Driven Development | Test structure scaffolded; lint/format gates defined | ✅ Pass |
| IV. Background Isolation | DB init via isolate-safe Drift; no heavy work on UI thread | ✅ Pass |
| V. Immutable State | Riverpod providers; freezed for state classes | ✅ Pass |
| VI. Security by Default | Credentials via `--dart-define`; no secrets in VCS | ✅ Pass |
| VII. Feature-Based Modules | `lib/features/` + `lib/core/` structure | ✅ Pass |
| VIII. Observability | Centralized logger + error boundaries on every route | ✅ Pass |

## Project Structure

### Documentation (this feature)

```text
specs/001-foundation-base-architecture/
├── spec.md              # Feature specification
├── research.md          # Phase 0: Technology decisions
├── data-model.md        # Phase 1: Full database schema
├── plan.md              # This file
├── quickstart.md        # Phase 1: Developer setup guide
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── main.dart                         # Entry point, Supabase init, runApp
├── app.dart                          # MaterialApp.router + ProviderScope
├── core/
│   ├── config/
│   │   └── app_config.dart           # Environment config (Supabase URL, keys)
│   ├── database/
│   │   ├── app_database.dart         # Drift database class + table refs
│   │   ├── app_database.g.dart       # Generated
│   │   ├── tables/                   # Drift table definitions
│   │   │   ├── user_profile_table.dart
│   │   │   ├── folder_table.dart
│   │   │   ├── note_table.dart
│   │   │   ├── flashcard_table.dart
│   │   │   ├── quiz_table.dart
│   │   │   ├── quiz_question_table.dart
│   │   │   ├── feynman_session_table.dart
│   │   │   ├── achievement_table.dart
│   │   │   ├── daily_goal_table.dart
│   │   │   ├── streak_table.dart
│   │   │   └── sync_queue_item_table.dart
│   │   └── daos/                     # Data Access Objects (future use)
│   ├── error/
│   │   ├── error_boundary.dart       # Route-level error catching widget
│   │   ├── app_exception.dart        # Base exception hierarchy
│   │   └── fallback_error_screen.dart# Branded fallback UI
│   ├── logging/
│   │   └── app_logger.dart           # Centralized structured logger
│   ├── providers/
│   │   ├── database_provider.dart    # Riverpod provider for AppDatabase
│   │   ├── supabase_provider.dart    # Riverpod provider for Supabase client
│   │   └── logger_provider.dart      # Riverpod provider for AppLogger
│   ├── router/
│   │   ├── app_router.dart           # GoRouter config + ShellRoute
│   │   └── route_names.dart          # Named route constants
│   ├── theme/
│   │   ├── app_theme.dart            # Light + Dark ThemeData
│   │   ├── app_colors.dart           # ColorScheme seeds + custom colors
│   │   ├── app_typography.dart       # TextTheme using Google Fonts
│   │   └── app_spacing.dart          # Spacing & radii constants
│   └── widgets/
│       └── scaffold_with_nav_bar.dart# Bottom nav shell widget
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart      # Placeholder
│   ├── library/
│   │   └── presentation/
│   │       └── library_screen.dart   # Placeholder
│   ├── progress/
│   │   └── presentation/
│   │       └── progress_screen.dart  # Placeholder
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart  # Placeholder

test/
├── core/
│   ├── database/
│   │   └── app_database_test.dart    # Schema creation & migration tests
│   ├── error/
│   │   └── error_boundary_test.dart  # Widget test for fallback rendering
│   ├── logging/
│   │   └── app_logger_test.dart      # Structured output validation
│   ├── router/
│   │   └── app_router_test.dart      # Route resolution tests
│   └── theme/
│       └── app_theme_test.dart       # Theme token consistency tests
├── features/
│   └── (empty — placeholder tests added per feature spec)
└── test_helpers/
    └── test_app.dart                 # ProviderScope + MaterialApp wrapper

integration_test/
└── app_launch_test.dart              # Cold-start + navigation smoke test
```

**Structure Decision**: Feature-first under `lib/features/` with shared
infrastructure in `lib/core/`. Matches Constitution Principle VII. Four
placeholder feature screens (Home, Library, Progress, Settings) provide
the navigation shell while keeping each feature module ready for expansion.

## Complexity Tracking

> No Constitution Check violations. No complexity justifications required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| *None*    | —          | —                                    |

## Verification Plan

### Automated Tests

All tests are run from the repository root.

1. **Unit & Widget Tests** — verify database creation, error boundary UI,
   logger output, router resolution, and theme consistency:
   ```bash
   flutter test
   ```

2. **Drift Schema Test** — confirms all 11 tables are created and schema
   version is correct:
   ```bash
   flutter test test/core/database/app_database_test.dart
   ```

3. **Error Boundary Widget Test** — confirms fallback screen renders when
   a child widget throws, and retry re-renders successfully:
   ```bash
   flutter test test/core/error/error_boundary_test.dart
   ```

4. **Integration Smoke Test** — launches the app, verifies all four tabs
   are reachable, and confirms cold-start time:
   ```bash
   flutter test integration_test/app_launch_test.dart
   ```

5. **Lint + Format Gate**:
   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   ```

### Manual Verification

1. **Android APK**: Build with `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
   Install on a Pixel 4a (or emulator). Verify: app launches in <2s, all 4
   tabs are tappable, dark/light mode follows system setting.

2. **Web**: Run `flutter run -d chrome`. Verify: app renders, navigation
   works, no console errors.

3. **Offline**: Enable airplane mode on device/emulator, launch app. Verify:
   app opens normally with no error dialogs or spinners.

4. **Secret Scanning**: Run `git log --all --diff-filter=A -- '*.dart' | grep -i 'supabase_url\|supabase_anon_key\|apikey'` and confirm zero matches
   outside of `--dart-define` documentation.
