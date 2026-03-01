# Quickstart: Foundation & Base Architecture

**Feature**: 001-foundation-base-architecture
**Date**: 2026-02-27

## Prerequisites

- Flutter SDK ≥ 3.22 (Dart ≥ 3.2)
- Android Studio or VS Code with Flutter extensions
- Chrome (for web development)
- A Supabase project with URL and anon key

## 1. Clone & Checkout

```bash
git clone <repo-url>
cd feynman
git checkout 001-foundation-base-architecture
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Run Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- Drift database classes (`*.g.dart`)
- Riverpod providers (`*.g.dart`)
- Freezed models (`*.freezed.dart`, `*.g.dart`)

## 4. Configure Environment

Create a `.env.example` (for reference only — actual values via `--dart-define`):

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

## 5. Run on Android

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## 6. Run on Web

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## 7. Run Tests

```bash
# All tests
flutter test

# Specific test suite
flutter test test/core/database/app_database_test.dart
flutter test test/core/error/error_boundary_test.dart

# Lint + format check
dart analyze --fatal-infos
dart format --set-exit-if-changed .
```

## 8. Run Integration Tests

```bash
flutter test integration_test/app_launch_test.dart
```

## 9. Verify Offline Mode

1. Enable airplane mode on the device or emulator.
2. Launch the app.
3. Confirm all four tabs (Home, Library, Progress, Settings) are accessible.
4. Confirm no error dialogs or loading spinners appear.

## Project Structure Overview

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp.router
├── core/                  # Shared infrastructure
│   ├── config/            # Environment configuration
│   ├── database/          # Drift DB + tables + DAOs
│   ├── error/             # Error boundaries + exceptions
│   ├── logging/           # Structured logger
│   ├── providers/         # Core Riverpod providers
│   ├── router/            # GoRouter configuration
│   ├── theme/             # Design tokens + ThemeData
│   └── widgets/           # Shared widgets (nav shell)
└── features/              # Feature modules
    ├── home/
    ├── library/
    ├── progress/
    └── settings/
```

## Common Tasks

| Task | Command |
|------|---------|
| Add a new feature module | Create `lib/features/<name>/{presentation,domain,data}/` |
| Regenerate Drift schema | `dart run build_runner build --delete-conflicting-outputs` |
| Export schema snapshot | `dart run drift_dev schema dump lib/core/database/app_database.dart db_schemas/` |
| Check layer violations | `dart analyze --fatal-infos` |
