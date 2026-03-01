# Research: Foundation & Base Architecture

**Feature**: 001-foundation-base-architecture
**Date**: 2026-02-27

## R-001: Flutter Project Structure for Clean Architecture

**Decision**: Feature-first directory layout under `lib/features/<name>/` with
shared code in `lib/core/`. Each feature contains `presentation/`, `domain/`,
and `data/` sub-directories.

**Rationale**: Feature-first keeps related code co-located, reduces cognitive
load, and allows independent development per feature. Layer sub-directories
inside features enforce the Clean Architecture constraint from
Constitution Principle I. Shared code (theme, router, DI, logger) lives in
`lib/core/` to avoid duplication.

**Alternatives Considered**:
- *Layer-first* (`lib/domain/`, `lib/data/`, `lib/presentation/`): Groups by
  technical concern but scatters feature logic across directories. Poor
  scalability for 18+ feature specs.
- *Package-per-feature* (separate Dart packages): Maximum isolation but adds
  pub dependency management overhead. Premature for initial scope.

---

## R-002: State Management & Dependency Injection

**Decision**: Riverpod (with code generation via `riverpod_generator`) for both
state management and DI. Providers are the composition root.

**Rationale**: Riverpod is compile-safe, supports async providers natively,
integrates with code generation for boilerplate reduction, and does not require
`BuildContext` for access — enabling use inside repositories and services.
Constitution Principle V mandates Riverpod. Code generation produces typed
providers and eliminates manual registration.

**Alternatives Considered**:
- *BLoC/Cubit*: Well-established but requires separate DI (get_it). Two
  frameworks instead of one. Does not align with constitution mandate.
- *Provider (legacy)*: Predecessor to Riverpod; lacks compile-time safety and
  cannot scope state independently of the widget tree.

---

## R-003: Local Database — Drift (SQLite)

**Decision**: Use Drift (`drift` + `drift_flutter`) for type-safe SQLite
persistence with code-generated DAOs and automated schema migrations.

**Rationale**: Drift provides compile-time verified queries, reactive streams
(`watch` queries that emit on table changes), built-in migration framework
with schema versioning, and isolate support for off-main-thread I/O.
Constitution Principle II mandates local-first storage; Drift is the
constitution-specified technology.

**Key Configuration**:
- `schemaVersion` integer incremented per migration.
- `MigrationStrategy.onUpgrade` for step-by-step migrations.
- Schema snapshots exported with `drift_dev schema dump` for validation.
- DAOs per entity group for encapsulation.
- `NativeDatabase` with `LazyDatabase` opener pattern for Flutter.
- Web: `WasmDatabase` for browser compatibility.

**Alternatives Considered**:
- *sqflite*: Lower-level, no code generation, manual query strings. Higher
  risk of runtime SQL errors.
- *Hive/Isar*: NoSQL stores; relational data model (notes → flashcards →
  quizzes) benefits from SQL joins and foreign keys.

---

## R-004: Supabase Client Initialization

**Decision**: Initialize Supabase via `Supabase.initialize()` in `main.dart`
with credentials injected through `--dart-define`. Wrap initialization in a
try-catch that logs failures and falls back to offline mode.

**Rationale**: `Supabase.initialize()` sets up Auth, Database (PostgREST),
Realtime, and Storage clients in one call. `--dart-define` keeps secrets out
of source code (Constitution Principle VI). A failed init MUST NOT crash the
app (Constitution Principle II — offline-first).

**Key Configuration**:
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` injected via `--dart-define`.
- Connectivity state tracked via `connectivity_plus` package.
- Supabase client wrapped in a Riverpod provider. Downstream providers
  depend on this provider; when Supabase is unavailable, they return
  offline-only implementations.

**Alternatives Considered**:
- *Hardcoded keys*: Violates Constitution Principle VI. Rejected.
- *.env file with flutter_dotenv*: Viable but `--dart-define` is more
  secure as values are tree-shaken at compile time and never in plain text
  on device.

---

## R-005: Routing — GoRouter

**Decision**: Use `go_router` for declarative, URL-based routing with
`ShellRoute` for bottom navigation and `GoRoute` for nested pages.

**Rationale**: GoRouter supports deep linking (required by FR-013), nested
navigation (tab-scoped stacks), and route guards (for future auth gating).
It is the recommended Flutter routing package and integrates well with
Riverpod for auth-state-driven redirects.

**Key Configuration**:
- `ShellRoute` wraps the `ScaffoldWithNavBar` providing the bottom navigation
  shell with four branches: Home, Library, Progress, Settings.
- Each branch maintains its own navigation stack via `StatefulShellRoute`.
- Route guards as `redirect` callbacks that check auth state from a Riverpod
  provider.

**Alternatives Considered**:
- *auto_route*: Also declarative but code-generated from annotations. More
  boilerplate; GoRouter is simpler for the current scope.
- *Navigator 2.0 raw*: Low-level, verbose, and complex for shell navigation
  patterns.

---

## R-006: Design System — Theme & Tokens

**Decision**: Centralized `AppTheme` class exposing Material 3 `ThemeData`
for both light and dark modes. Design tokens (colour palette, typography
scale, spacing, radii) defined as constants and consumed via
`Theme.of(context)` extensions.

**Rationale**: A single theme provider (Constitution Principle VII) ensures
visual consistency across all 18 feature specs. Material 3 `ColorScheme`
provides adaptive colour roles. Extension methods on `ThemeData` expose
custom tokens (spacing, radii) without requiring a parallel design system.

**Key Configuration**:
- Colour palette using `ColorScheme.fromSeed()` with primary seed colour.
- Typography via `GoogleFonts.interTextTheme()`.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64 logical pixels.
- Border radii: sm(8), md(12), lg(16), xl(24).
- Theme exposed as a `Riverpod` provider for runtime mode switching.

**Alternatives Considered**:
- *Custom paint-based system*: Maximum control but re-invents what Material 3
  already provides. Not justified at this stage.

---

## R-007: Error Handling & Logging

**Decision**: Route-level `ErrorBoundary` widget wrapping each top-level
destination. Centralized `AppLogger` using the `logger` package emitting
structured JSON entries.

**Rationale**: Constitution Principle VIII mandates error boundaries on
every route and structured logging at domain boundaries. The `logger`
package provides severity levels, customizable printers (JSON for production,
pretty-print for development), and negligible overhead.

**Key Configuration**:
- `ErrorBoundary` widget catches `FlutterError` and platform errors within
  its subtree. Renders branded fallback UI with retry button.
- `AppLogger` singleton exposed via Riverpod provider. Tags map to feature
  modules (e.g., `sync`, `auth`, `notes`).
- Log levels: verbose, debug, info, warning, error, fatal.
- Production: JSON printer → future integration with crash reporting.
- Development: PrettyPrinter with method counts and colours.

**Alternatives Considered**:
- *dart:developer log*: No structured output, no severity levels. Insufficient
  for Constitution requirements.
- *Talker*: Full-featured but opinionated UI overlay which is unnecessary;
  we only need the logging core.

---

## R-008: Layer Enforcement via Lint Rules

**Decision**: Use `custom_lint` + project-specific lint rules to enforce
import restrictions between layers. Presentation MUST NOT import from Data.
Domain MUST NOT import Flutter/Supabase SDK.

**Rationale**: Constitution Principle I designates layer separation as
NON-NEGOTIABLE. Static analysis catches violations at development time,
before code review.

**Key Configuration**:
- `analysis_options.yaml` with strict Dart rules (`strict-casts`,
  `strict-raw-types`, `strict-inference`).
- `avoid_relative_imports` set to always use package imports for cross-layer
  traceability.
- Custom lint rule or `import_lint` package to flag forbidden cross-layer
  imports.

**Alternatives Considered**:
- *Code review only*: Not automatable, relies on reviewer diligence. Rejected
  per constitution ("MUST" not "SHOULD").
