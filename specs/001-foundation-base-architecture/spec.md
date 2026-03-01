# Feature Specification: Foundation & Base Architecture

**Feature Branch**: `001-foundation-base-architecture`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "Foundation & Base Architecture — project scaffold, Clean-Architecture layers, DI wiring, routing, theme, error-boundary scaffold, centralized logger, local DB bootstrap, Supabase client init"

## User Scenarios & Testing

### User Story 1 – App Launch & Navigation Shell (Priority: P1)

A user installs the Feynman app and opens it for the first time. The app launches to a shell screen with bottom navigation containing the primary destinations (Home, Library, Progress, Settings). Tapping each tab navigates to its placeholder screen without delay. The app displays the project's brand theme—typography, colours, and spacing—consistently across every screen.

**Why this priority**: Without a running app shell, no subsequent feature can be demonstrated or tested. This is the absolute minimum viable delivery.

**Independent Test**: Launch the app on Android and in a web browser. Verify all navigation tabs render, transitions are smooth, and the theme is applied uniformly.

**Acceptance Scenarios**:

1. **Given** the app is freshly installed, **When** the user opens it, **Then** the navigation shell renders within 2 seconds with all tabs visible.
2. **Given** the user is on the Home tab, **When** they tap the Library tab, **Then** the Library placeholder screen appears immediately with no visible jank.
3. **Given** any screen in the app, **When** the user observes typography and colour, **Then** all elements conform to the design-token palette (primary, secondary, surface, error colours; heading and body type scales).

---

### User Story 2 – Offline-Ready Local Database (Priority: P1)

A user opens the app without any network connectivity. The app launches normally and displays its shell screens without error. Internally, the local SQLite database has been initialized with the schema required for future features (notes, folders, flashcards, quizzes, sessions, gamification, sync queue). No user-facing data is visible yet, but the storage layer is operational.

**Why this priority**: Every data-driven feature (notes, flashcards, sync) depends on the local database being bootstrapped. This is a blocking prerequisite.

**Independent Test**: Enable airplane mode, launch the app, and verify it opens without crashes. Query the database file to confirm tables exist with the expected schema.

**Acceptance Scenarios**:

1. **Given** the device has no network connectivity, **When** the user opens the app, **Then** the app launches to the navigation shell without errors or loading spinners.
2. **Given** the database has not been created, **When** the app starts for the first time, **Then** the local SQLite database is created with the full schema and all required tables.
3. **Given** the app has previously been opened, **When** the user opens it again, **Then** the existing database is reused without re-creating or dropping tables.

---

### User Story 3 – Supabase Backend Connectivity (Priority: P2)

A user opens the app while connected to the internet. Behind the scenes, the app initializes its connection to Supabase (Auth client, database client, Realtime client, Storage client). Although no user-facing feature exercises the backend yet, the connection readiness is verified internally. If the backend is unreachable, the app degrades gracefully to offline mode without presenting errors.

**Why this priority**: Authentication, sync, and content ingestion all depend on Supabase connectivity. Initializing the client early avoids re-work in every downstream feature.

**Independent Test**: Launch the app with valid Supabase credentials configured. Verify in logs that all Supabase sub-clients initialise successfully. Then launch with an invalid URL and verify the app still renders without crashing.

**Acceptance Scenarios**:

1. **Given** valid Supabase project credentials, **When** the app starts, **Then** Supabase Auth, Database, Realtime, and Storage clients are initialised and log a readiness confirmation.
2. **Given** the Supabase backend is unreachable, **When** the app starts, **Then** the app falls back to offline mode and logs the connectivity failure without displaying an error to the user.
3. **Given** Supabase credentials are injected via environment configuration, **When** the project is built, **Then** no secrets appear in the source code repository.

---

### User Story 4 – Structured Error Handling & Logging (Priority: P2)

A developer triggers an unhandled exception during feature development. Instead of the app crashing to a blank screen, the error boundary catches the exception, displays a user-friendly fallback screen with a "Retry" option, and logs the exception with structured metadata (timestamp, screen, stack trace) to the centralized logger.

**Why this priority**: Error handling and logging underpin every future feature's reliability and debuggability. Retrofitting these later leads to inconsistent coverage.

**Independent Test**: Intentionally throw an exception inside a test screen widget. Verify the error-boundary screen appears, the retry button re-renders the widget, and the log output contains the expected structured fields.

**Acceptance Scenarios**:

1. **Given** a widget throws an unhandled exception, **When** the error propagates, **Then** the error boundary intercepts it and displays a branded fallback screen with a "Retry" action.
2. **Given** an error is caught by the boundary, **When** it is logged, **Then** the log entry contains timestamp, error type, message, stack trace, and the route where the error occurred.
3. **Given** the user taps "Retry" on the fallback screen, **When** the widget re-renders successfully, **Then** the fallback screen is dismissed and the original content is displayed.

---

### User Story 5 – Dependency Injection Ready for Feature Teams (Priority: P3)

A developer adds a new feature module to the project. They create a Riverpod provider for their feature's use-case and register it following the established composition-root pattern. The provider integrates seamlessly with existing providers (logger, database, Supabase client) without modifying shared infrastructure code.

**Why this priority**: A clean DI setup prevents ad-hoc service-locator patterns and ensures architectural consistency across all future features.

**Independent Test**: Create a sample provider that depends on the logger and database providers. Verify it resolves correctly at runtime without manual wiring or global singletons.

**Acceptance Scenarios**:

1. **Given** a developer creates a new Riverpod provider, **When** they declare dependencies on core providers (logger, database, Supabase client), **Then** the dependencies resolve at runtime without explicit manual registration.
2. **Given** the project architecture, **When** a developer imports a Data-layer class from the Presentation layer, **Then** static analysis flags the violation.
3. **Given** the project's provider structure, **When** a new feature module is added under `lib/features/`, **Then** it can declare its own providers without modifying files in `lib/core/`.

---

### Edge Cases

- What happens when the local database file is corrupted on launch? The app MUST detect the corruption, log the error, delete the corrupted file, and re-create a fresh database. The user sees normal app behaviour but with an empty data state.
- What happens when the app is launched on an unsupported browser (e.g., Internet Explorer)? The app MUST display a static "Unsupported Browser" message rather than rendering a broken UI.
- What happens when the Supabase configuration is missing or malformed at build time? The build MUST fail with a descriptive error message indicating which configuration values are missing.
- How does the system handle a database schema migration from a future update? The migration framework MUST support versioned migrations that run automatically on app start without data loss.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST provide a navigation shell with at least four top-level destinations (Home, Library, Progress, Settings) accessible via bottom navigation.
- **FR-002**: The system MUST apply a consistent design-token system (colour palette, typography scale, spacing scale, border radii) to all screens and widgets.
- **FR-003**: The system MUST support both a light theme and a dark theme, with the active theme determined by the device system setting.
- **FR-004**: The system MUST initialise a local SQLite database on first launch containing tables for: notes, folders, flashcards, quizzes, feynman_sessions, user_profile, achievements, daily_goals, streaks, sync_queue.
- **FR-005**: The database layer MUST support versioned schema migrations that execute automatically on app launch.
- **FR-006**: The system MUST initialise Supabase client SDKs (Auth, Database, Realtime, Storage) on app start using credentials injected via environment configuration.
- **FR-007**: The system MUST degrade gracefully to offline mode when the Supabase backend is unreachable, without displaying error dialogs to the user.
- **FR-008**: The system MUST provide a centralized logging service that emits structured log entries containing timestamp, severity level, source tag, message, and optional metadata.
- **FR-009**: The system MUST wrap every top-level route in an error boundary that catches unhandled exceptions and displays a branded fallback screen with a "Retry" action.
- **FR-010**: The system MUST organise the codebase into feature-based modules under `lib/features/`, each containing `presentation/`, `domain/`, and `data/` sub-directories.
- **FR-011**: The system MUST use Riverpod as the sole dependency-injection and state-management framework, with providers declared at the composition root.
- **FR-012**: The system MUST enforce layer separation such that Presentation-layer code cannot import Data-layer symbols directly.
- **FR-013**: The system MUST provide a router configuration using declarative routing that supports deep linking, nested navigation, and route guards for future authentication gating.
- **FR-014**: The system MUST boot successfully on Android (SDK 24+) and modern web browsers (Chrome, Firefox, Safari, Edge — latest two major versions).

### Key Entities

- **AppConfiguration**: Holds Supabase URL, anon key, and environment-specific feature flags. Injected at build time; never persisted in the database.
- **AppTheme**: Encapsulates the full design-token set (colours, typography, spacing). Exposed as a Riverpod provider for runtime access.
- **LogEntry**: Represents a single structured log record (timestamp, severity, tag, message, metadata map).
- **DatabaseSchema**: The aggregate definition of all tables and their columns, versioned for migration support.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The app launches to the navigation shell within 2 seconds on a mid-range Android device (e.g., Pixel 4a) and within 1 second in a web browser on a standard laptop.
- **SC-002**: All four navigation tabs are reachable with a single tap, and transitions between tabs complete within 300 milliseconds with no dropped frames.
- **SC-003**: The local database is successfully created on first launch in 100% of test runs across Android and web platforms.
- **SC-004**: The app launches and remains usable without crashes when the device has no network connectivity.
- **SC-005**: Unhandled exceptions within any screen are caught by the error boundary and never propagate to a platform crash in 100% of test scenarios.
- **SC-006**: Zero Supabase credentials or API keys are present in the source code repository (verified by automated secret scanning).
- **SC-007**: Layer-separation violations (Presentation importing Data) are detected and reported by static analysis tooling with zero false negatives.
- **SC-008**: A new feature module can be scaffolded and its providers integrated without modifying any file in `lib/core/` (verified by scaffolding a test module).
