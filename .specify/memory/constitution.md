<!--
Sync Impact Report
──────────────────
Version change : 0.0.0 → 1.0.0 (MAJOR – initial ratification)
Modified principles : N/A (first population)
Added sections :
  - Core Principles (8 principles)
  - Technology Stack & Constraints
  - Development Workflow & Quality Gates
  - Governance
Removed sections : None
Templates requiring updates:
  - plan-template.md   ✅ compatible (Constitution Check section exists)
  - spec-template.md   ✅ compatible (no constitution-specific refs)
  - tasks-template.md  ✅ compatible (no constitution-specific refs)
Follow-up TODOs : None
-->

# Feynman Constitution

## Core Principles

### I. Clean Architecture (NON-NEGOTIABLE)

Every feature MUST follow strict layer separation with
unidirectional dependency flow: **Presentation → Domain → Data**.

- **Presentation layer** (UI, widgets, controllers) MUST depend only
  on the Domain layer and MUST NOT import Data-layer symbols.
- **Domain layer** (entities, use-cases, repository contracts) MUST
  contain zero framework imports (no Flutter, no Supabase SDK).
- **Data layer** (repositories, data-sources, DTOs, mappers) MUST
  implement Domain contracts and own all I/O, serialization, and
  platform-channel logic.
- Dependency Injection MUST flow inward via abstract contracts;
  concrete bindings are resolved at the composition root (Riverpod
  providers).
- SOLID principles MUST govern every class: single responsibility,
  open-closed extension, Liskov substitution for contracts,
  interface segregation for repositories, and dependency inversion
  between layers.

**Rationale:** Enforcing hard boundaries prevents UI logic from
leaking into business rules, makes each layer independently testable,
and ensures the domain model remains portable across platforms.

### II. Offline-First Data Strategy (NON-NEGOTIABLE)

The local database MUST be the single source of truth for all user
data. Network operations MUST NOT block user interactions.

- All reads MUST be served from the local store (Drift / SQLite).
- Writes MUST persist locally first, then enqueue for remote sync.
- The sync engine MUST use a durable, ordered queue with
  version-vector conflict detection.
- Conflict resolution MUST follow an explicit strategy: automatic
  last-write-wins for low-criticality fields, user-prompted merge
  for high-criticality data (see SPEC §9 Conflict Resolution).
- The app MUST remain fully functional (read + write) when the
  device has no network connectivity.

**Rationale:** Learning happens everywhere—commutes, flights, areas
with poor signal. Users MUST NEVER encounter a spinner that blocks
study progress.

### III. Test-Driven Development

All production code MUST be covered by automated tests written
before or alongside implementation.

- **Unit tests** MUST cover every use-case, repository
  implementation, and non-trivial utility.
- **Widget tests** MUST verify critical UI flows (onboarding,
  Feynman session, flashcard review, quiz).
- **Integration tests** MUST validate end-to-end paths through
  sync, authentication, and content processing.
- The Red-Green-Refactor cycle MUST be followed: write a failing
  test, make it pass with minimal code, then refactor.
- Edge Functions (Deno) MUST have standalone test suites
  executable via `deno test`.
- Minimum coverage threshold: **80 %** line coverage for Domain
  and Data layers; **60 %** for Presentation layer.

**Rationale:** The Feynman app handles complex stateful flows
(spaced repetition scheduling, sync queues, gamification XP). Tests
are the primary defense against regressions that silently corrupt
user learning data.

### IV. Background Isolation

Heavy computation MUST execute off the main (UI) thread. The UI
MUST remain responsive at 60 fps at all times.

- Content processing (transcription, AI analysis, PDF parsing)
  MUST run inside Dart Isolates or be delegated to Supabase Edge
  Functions.
- Sync operations, image decoding, and large JSON serialization
  MUST use `Isolate.run` or `compute()`.
- Background sync MUST leverage platform-specific
  background-execution APIs (WorkManager on Android,
  Background Fetch on web via Service Workers).
- Long-running isolate tasks MUST communicate progress via
  `SendPort`/`ReceivePort` for UI feedback (progress bars,
  processing screens).

**Rationale:** SPEC §5 describes multi-stage content processing
(upload → transcription → generation). Blocking the UI during
these stages would create unacceptable UX degradation.

### V. Immutable State & Unidirectional Data Flow

Application state MUST be managed through Riverpod providers with
immutable state objects. State mutations MUST flow in one direction.

- UI widgets MUST read state via `ref.watch` / `ref.read` and
  dispatch actions through use-cases or notifiers—never mutate
  state directly.
- State classes MUST be immutable (`@freezed` or `copyWith`
  pattern). Direct field mutation is PROHIBITED.
- All provider states MUST handle the async triad:
  `loading`, `data`, `error`.
- Realtime subscriptions (Supabase Realtime) MUST feed into
  providers, not into widget `setState` calls.

**Rationale:** Unidirectional flow eliminates an entire class of
bugs arising from stale or inconsistent UI state, which is critical
when juggling offline queues, realtime streams, and gamification
side-effects simultaneously.

### VI. Security by Default

Authentication and data access MUST be secure at every boundary.
Security controls MUST NOT be optional or deferred.

- Supabase Row-Level Security (RLS) MUST be enabled on every
  table. No table may exist without RLS policies.
- Authentication MUST support email/password and OAuth (Google)
  via Supabase Auth. Tokens MUST be stored using secure platform
  storage (flutter_secure_storage).
- All Edge Functions MUST validate the caller's JWT before
  processing requests.
- User-generated content uploads MUST be scanned for MIME-type
  validity. File-size limits defined in SPEC §9 MUST be enforced
  both client-side and server-side.
- API keys and secrets MUST NEVER appear in version control.
  Environment-specific values MUST be injected via
  `--dart-define` or `.env` files excluded from the repository.

**Rationale:** The app stores personal learning data and user
recordings. A breach of trust through a data leak would be
existential for the product. Defense in depth is mandatory.

### VII. Feature-Based Modular Structure

The codebase MUST be organized by feature, not by technical
layer, to enable independent development and navigation.

- Each feature (e.g., `notes`, `feynman_session`, `flashcards`,
  `quiz`, `gamification`, `sync`) MUST reside in its own
  directory under `lib/features/`.
- Each feature directory MUST contain its own `presentation/`,
  `domain/`, and `data/` sub-directories mirroring Principle I.
- Shared code (theme, routing, common widgets, DI setup) MUST
  live in `lib/core/`.
- Cross-feature dependencies MUST flow through Domain-layer
  contracts, never via direct Data-layer imports.
- New features MUST NOT introduce circular dependencies between
  feature modules.

**Rationale:** SPEC §5 enumerates seven distinct capability areas.
Feature-based modules keep cognitive load manageable and allow
parallel development across the team without merge conflicts.

### VIII. Observability & Reliability

The application MUST provide structured diagnostic information and
graceful degradation under failure conditions.

- Structured logging MUST be emitted at domain boundaries (sync
  events, auth state changes, content processing stages) using a
  centralized logger.
- Error boundaries MUST wrap every top-level route and async
  operation. Unhandled exceptions MUST display user-friendly
  fallback UI, never a raw crash.
- Crash reporting MUST be integrated (e.g., Sentry or Firebase
  Crashlytics) and MUST capture breadcrumbs for reproduction.
- Push notification delivery MUST be tracked end-to-end to
  identify delivery failures.
- Edge Function invocations MUST log execution duration, status
  codes, and error payloads for operational monitoring.

**Rationale:** A learning app that crashes mid-session or silently
loses sync data erodes user trust. Observable systems allow rapid
diagnosis and proactive remediation.

## Technology Stack & Constraints

| Concern              | Choice                                         |
|----------------------|-------------------------------------------------|
| **Framework**        | Flutter (Dart) – Android + Web                  |
| **Backend**          | Supabase (PostgreSQL, Auth, Storage, Realtime)   |
| **Edge Functions**   | Supabase Edge Functions (Deno / TypeScript)       |
| **Local DB**         | Drift (SQLite) for offline-first persistence      |
| **State Management** | Riverpod (code-generated providers preferred)     |
| **Auth**             | Supabase Auth – email/password, Google OAuth      |
| **Push**             | Firebase Cloud Messaging (Android), Web Push API  |
| **Image Loading**    | cached_network_image + shimmer placeholders       |
| **Serialization**    | freezed + json_serializable                       |
| **Networking**       | Supabase client SDK; dio for non-Supabase calls   |
| **CI/CD**            | GitHub Actions (lint → test → build → deploy)     |
| **Min Android SDK**  | 24 (Android 7.0)                                  |
| **Min Dart SDK**     | ≥ 3.2 with sound null-safety                     |
| **Target FPS**       | 60 fps sustained on mid-range devices             |
| **Max Offline Gap**  | 30 days of local-only operation without data loss  |

## Development Workflow & Quality Gates

### Branching Strategy

- `main` – stable, deployable at all times.
- `develop` – integration branch for feature merges.
- `feature/<id>-<name>` – one branch per speckit feature.
- `hotfix/<id>-<desc>` – urgent production fixes cherry-picked
  into `main`.

### Quality Gates (must pass before merge)

1. **Lint gate** – `dart analyze` and `flutter analyze` report
   zero issues.
2. **Format gate** – `dart format --set-exit-if-changed .`
   passes.
3. **Test gate** – all unit, widget, and integration tests pass.
4. **Coverage gate** – Domain + Data ≥ 80 %, Presentation ≥ 60 %.
5. **Constitution check** – reviewer MUST verify that the PR
   adheres to all eight Core Principles above.
6. **Edge Function gate** – `deno lint` and `deno test` pass for
   any modified function.

### Commit Conventions

Follow Conventional Commits: `<type>(<scope>): <description>`.
Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
Scope SHOULD match the feature module name (e.g.,
`feat(flashcards): add hint toggle`).

### Code Review Expectations

- Every PR MUST be reviewed against the Constitution's Core
  Principles checklist.
- Architecture violations (e.g., Presentation importing Data)
  MUST be flagged as blocking.
- Complexity additions MUST be justified in the PR description
  following the plan template's Complexity Tracking table.

## Governance

- This Constitution is the highest-authority engineering document
  for the Feynman project. It supersedes all other conventions,
  guides, and ad-hoc decisions.
- **Amendments** require: (1) a written proposal describing the
  change and rationale, (2) review by at least one other
  contributor, (3) a migration plan if existing code must change,
  and (4) an updated version number following SemVer.
- **Version policy**: MAJOR for principle removals or redefinitions,
  MINOR for new principles or material expansions, PATCH for
  wording clarifications.
- **Compliance review**: Every pull request checklist MUST include
  a "Constitution Compliance" checkbox. Merges that violate
  Non-Negotiable principles MUST be reverted.

**Version**: 1.0.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-02-27
