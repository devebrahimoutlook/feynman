# Tasks: Authentication & User Management

**Feature**: 002-auth-user-management
**Input**: Design documents from `/specs/002-auth-user-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Test-driven development (TDD) is mandated by Constitution Principle III. Tests are tasked to be written *before* implementation for each User Story.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup for auth components

- [x] T001 Add `google_sign_in`, `flutter_secure_storage`, `image_cropper` to `pubspec.yaml`
- [x] T002 Configure deep linking intent-filter for `com.feynman.app` in `android/app/src/main/AndroidManifest.xml`
- [x] T002a Apply `user_profile` RLS policies (SELECT/UPDATE/INSERT by `auth.uid()`, no direct DELETE) in Supabase Dashboard → Database → Policies, as specified in `specs/002-auth-user-management/data-model.md`
- [x] T002b Configure `avatars` storage bucket in Supabase Dashboard: create bucket, set public read, add Storage RLS policy (`auth.uid() = path_tokens[1]`) for upload and delete
- [x] T003 Create directory structure for `lib/features/auth/` (presentation, domain, data) and subdirectories
- [x] T004 [P] Document required Supabase Dashboard configuration (providers, redirect URLs, storage) in a README or wiki

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Extend `user_profile` table definition in Drift schema (`lib/core/database/tables.dart` or similar) with `authProvider` and `emailVerified`
- [x] T006 [P] Create `AuthState` freezed union (authenticated, unauthenticated, loading, error) in `lib/features/auth/domain/entities/auth_state.dart`
- [x] T007 [P] Create `UserSession` domain entity in `lib/features/auth/domain/entities/user_session.dart`
- [x] T008 [P] Abstract `AuthRepository` contract in `lib/features/auth/domain/repositories/auth_repository.dart`
- [x] T009 Implement `AuthNotifier` (AsyncNotifier) and `authStateProvider` in `lib/core/providers/auth_provider.dart` reading from Supabase `onAuthStateChange`
- [x] T010 Modify GoRouter configuration in `lib/core/router/app_router.dart` to include auth redirect guard based on `authStateProvider`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Email Registration & Login (Priority: P1) 🎯 MVP

**Goal**: Users can register with email/password, verify their email, and log in.

**Independent Test**: User can launch app, see login screen, navigate to register, create account, and (after verifying) log in to reach the protected Home route.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T011 [P] [US1] Unit test `sign_in_with_email` and `sign_up_with_email` usecases in `test/features/auth/domain/usecases/`
- [x] T012 [P] [US1] Unit test `AuthRepositoryImpl` email methods in `test/features/auth/data/repositories/auth_repository_impl_test.dart`
- [x] T013 [P] [US1] Widget test `LoginScreen` and `RegisterScreen` in `test/features/auth/presentation/screens/`
- [x] T014 [P] [US1] Unit test `login_controller` and `register_controller` in `test/features/auth/presentation/controllers/`

### Implementation for User Story 1

- [x] T015 [P] [US1] Implement `sign_in_with_email.dart` and `sign_up_with_email.dart` usecases in `lib/features/auth/domain/usecases/`
- [x] T016 [P] [US1] Create `AuthRemoteDatasource` wrapping Supabase email auth calls in `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- [x] T017 [US1] Implement `AuthRepositoryImpl` bridging usecases to datasource in `lib/features/auth/data/repositories/auth_repository_impl.dart`
- [x] T017a [US1] Handle EC-001 in `AuthRepositoryImpl`: detect "User already registered" error code from Supabase and surface a user-friendly "Account exists — please log in" message instead of a raw exception, covering the network-drop-during-registration edge case
- [x] T018 [P] [US1] Create `AuthFormField` reusable widget in `lib/features/auth/presentation/widgets/auth_form_field.dart`
- [x] T019 [P] [US1] Create `PasswordStrengthIndicator` widget in `lib/features/auth/presentation/widgets/password_strength_indicator.dart`
- [x] T020 [P] [US1] Implement `LoginController` and `RegisterController` in `lib/features/auth/presentation/controllers/`
- [x] T021 [US1] Build `LoginScreen` UI with email/password fields in `lib/features/auth/presentation/screens/login_screen.dart`
- [x] T022 [US1] Build `RegisterScreen` UI with strong password validation in `lib/features/auth/presentation/screens/register_screen.dart`
- [x] T023 [US1] Build `VerifyEmailScreen` UI (shown after registration) in `lib/features/auth/presentation/screens/verify_email_screen.dart`
- [x] T024 [US1] Add auth routes (`/login`, `/register`, `/verify-email`) to `lib/core/router/app_router.dart`

**Checkpoint**: At this point, Email Registration & Login is fully functional and testable independently.

---

## Phase 4: User Story 2 - Google OAuth Login (Priority: P1)

**Goal**: Users can sign in natively with Google (Android) or via web redirect.

**Independent Test**: Tapping "Continue with Google" securely authenticates the user and routes them to Home.

### Tests for User Story 2 ⚠️

- [x] T025 [P] [US2] Unit test `sign_in_with_google` usecase in `test/features/auth/domain/usecases/sign_in_with_google_test.dart`
- [x] T026 [P] [US2] Update `AuthRepositoryImpl` tests for Google sign-in

### Implementation for User Story 2

- [x] T027 [P] [US2] Implement `sign_in_with_google.dart` usecase in `lib/features/auth/domain/usecases/`
- [x] T028 [US2] Add Google Sign-in logic (native GoogleSignIn package + Supabase ID token exchange) to `AuthRemoteDatasource`
- [x] T029 [US2] Implement Google sign-in method in `AuthRepositoryImpl`
- [x] T030 [P] [US2] Create `SocialLoginButton` widget in `lib/features/auth/presentation/widgets/social_login_button.dart`
- [x] T031 [US2] Update `LoginController` to handle Google sign-in state
- [x] T032 [US2] Add `SocialLoginButton` to `LoginScreen` and `RegisterScreen` UIs

**Checkpoint**: Users can now authenticate via Email or Google.

---

## Phase 5: User Story 3 - Session Persistence & Token Storage (Priority: P1)

**Goal**: Auth tokens are stored securely; sessions auto-restore on app launch.

**Independent Test**: Killing the app while logged in and reopening it bypasses the login screen directly to Home.

### Tests for User Story 3 ⚠️

- [x] T033 [P] [US3] Unit test secure storage implementation in `test/core/storage/`
- [x] T034 [P] [US3] Test `AuthNotifier` correctly initializes state from persisted session in `test/core/providers/auth_provider_test.dart`

### Implementation for User Story 3

- [x] T035 [P] [US3] Create a `SecureLocalStorage` implementation wrapping `flutter_secure_storage` matching Supabase's `LocalStorage` interface
- [x] T036 [US3] Inject `SecureLocalStorage` into `Supabase.initialize()` call in `lib/main.dart` (or core equivalent)
- [x] T037 [P] [US3] Implement `get_current_user.dart` usecase in `lib/features/auth/domain/usecases/`
- [x] T038 [US3] Ensure `AuthNotifier` sets initial state based on `Supabase.instance.client.auth.currentSession`
- [x] T038a [US3] Handle token refresh failure in `AuthNotifier`: catch `AuthException` on silent refresh, emit `AuthState.error(message: ...)`, and trigger GoRouter redirect to `/login` with message in `lib/core/providers/auth_provider.dart`

**Checkpoint**: Sessions are now secure and persistent.

---

## Phase 6: User Story 4 - User Profile Management (Priority: P2)

**Goal**: Users can view/edit display name, upload a cropped avatar, and sync profile offline.

**Independent Test**: User can upload an avatar and change name without network; updates sync later.

### Tests for User Story 4 ⚠️

- [x] T039 [P] [US4] Unit test profile usecases (`update_profile`, `upload_avatar`) in `test/features/auth/domain/usecases/`
- [x] T040 [P] [US4] Unit test `ProfileRepositoryImpl` caching logic in `test/features/auth/data/repositories/`
- [x] T041 [P] [US4] Widget test `ProfileScreen` in `test/features/auth/presentation/screens/`

### Implementation for User Story 4

- [x] T042 [P] [US4] Create `UserProfile` domain entity (extending 001) in `lib/features/auth/domain/entities/user_profile.dart`
- [x] T043 [P] [US4] Abstract `ProfileRepository` contract in `lib/features/auth/domain/repositories/profile_repository.dart`
- [x] T044a [P] [US4] Implement `update_profile.dart` usecase in `lib/features/auth/domain/usecases/update_profile.dart`
- [x] T044b [P] [US4] Implement `upload_avatar.dart` usecase in `lib/features/auth/domain/usecases/upload_avatar.dart`
- [x] T045 [P] [US4] Create `ProfileLocalDatasource` (Drift DAO) in `lib/features/auth/data/datasources/profile_local_datasource.dart`
- [x] T046 [P] [US4] Create `ProfileRemoteDatasource` (Supabase DB + Storage calls) in `lib/features/auth/data/datasources/profile_remote_datasource.dart`
- [x] T047 [US4] Implement `ProfileRepositoryImpl` with offline-first sync logic in `lib/features/auth/data/repositories/profile_repository_impl.dart`
- [x] T048 [P] [US4] Create `AvatarPicker` widget with `image_cropper` integration in `lib/features/auth/presentation/widgets/avatar_picker.dart`
- [x] T049 [P] [US4] Implement `ProfileController` in `lib/features/auth/presentation/controllers/profile_controller.dart`
- [x] T050 [US4] Build `ProfileScreen` UI in `lib/features/auth/presentation/screens/profile_screen.dart`
- [x] T051 [US4] Add `/profile` route to `app_router.dart`

**Checkpoint**: User profiles are functional and offline-capable.

---

## Phase 7: User Story 5 - Password Reset (Priority: P2)

**Goal**: Users can request a password reset email from the login screen.

**Independent Test**: Submitting an email shows the generic confirmation message without revealing account existence.

### Tests for User Story 5 ⚠️

- [x] T052 [P] [US5] Unit test `reset_password` usecase in `test/features/auth/domain/usecases/`
- [x] T053 [P] [US5] Widget test `ForgotPasswordScreen`

### Implementation for User Story 5

- [x] T054 [P] [US5] Implement `reset_password.dart` usecase in `lib/features/auth/domain/usecases/`
- [x] T055 [US5] Add reset logic to `AuthRemoteDatasource` and `AuthRepositoryImpl`
- [x] T056 [P] [US5] Implement `ForgotPasswordController` in `lib/features/auth/presentation/controllers/`
- [x] T057 [P] [US5] Build `ForgotPasswordScreen` UI in `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- [x] T058 [US5] Add `/forgot-password` route to `app_router.dart` and link it from `LoginScreen`

**Checkpoint**: Users can recover forgotten passwords.

---

## Phase 8: User Story 6 - Logout & Account Deletion (Priority: P3)

**Goal**: Users can log out cleanly, or irreversibly delete their account via Edge Function.

**Independent Test**: Account deletion wipes all server data and returns to login.

### Tests for User Story 6 ⚠️

- [x] T059 [P] [US6] Unit test `sign_out` and `delete_account` usecases in `test/features/auth/domain/usecases/`
- [x] T060 [P] [US6] Write Deno test for edge function in `supabase/functions/delete-account/index_test.ts`

### Implementation for User Story 6

- [x] T061 [P] [US6] Implement `sign_out.dart` usecase
- [x] T062 [US6] Add sign out to `AuthRepositoryImpl`
- [x] T063 [P] [US6] Write `delete-account` Edge Function in `supabase/functions/delete-account/index.ts`
- [x] T064 [P] [US6] Implement `delete_account.dart` usecase (calling Supabase Functions)
- [x] T065 [US6] Add edge function invocation to `ProfileRemoteDatasource` and `ProfileRepositoryImpl`
- [x] T066 [US6] Update `ProfileScreen` in `lib/features/auth/presentation/screens/profile_screen.dart` to include a Settings section with "Log out" and "Delete Account" buttons; "Delete Account" requires typed confirmation phrase ("DELETE") and warns of irreversibility per spec EC-005

**Checkpoint**: Full lifecycle management complete.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and system quality.

- [x] T067 [P] Write End-to-End integration test `integration_test/auth_flow_test.dart` (Register → verify → login → logout)
- [x] T068 [P] Run `dart format --set-exit-if-changed .` to ensure formatting compliance
- [x] T069 [P] Run `dart analyze --fatal-infos` to ensure clean lint state
- [x] T070 [P] Review all Error Boundary integrations in auth screens to ensure no raw exceptions leak to UI
- [x] A1 (Remediation): Add RegExp validation for uppercase, lowercase, and digits to `RegisterScreen` password field (FR-003).
- [x] A2 (Remediation): Inject `AppLogger` into `AuthRepositoryImpl` and `ProfileRepositoryImpl` and emit structured logs for all domain boundaries (Constitution VIII).
- [x] A3 (Remediation): Add `clearAllData()` to Drift `AppDatabase` and hook to `AuthNotifier.unauthenticated` state for complete local data wipe on logout/deletion (FR-012/FR-013).
- [x] A4 (Remediation): Resolve any linter issues (`dart analyze`) introduced by remediation edits.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: Can start immediately.
- **Foundational (Phase 2)**: Depends on Setup. BLOCKS all user stories.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion. User Stories can proceed sequentially or in parallel.
- **Polish (Phase 9)**: Done last.

### User Story Dependencies
- **US1 (P1)**: Foundation → US1.
- **US2 (P1)**: Foundation → US2. Can be done in parallel with US1, though UI integration shares login screen.
- **US3 (P1)**: Foundation → US3.
- **US4 (P2)**: Depends on Foundation. Benefits from US1/US2 completion to retrieve an actual user profile.
- **US5 (P2)**: Independent functionality, UI links to US1's Login Screen.
- **US6 (P3)**: Depends on US1/US2 to have an active session to log out from, and US4 for the settings UI where the buttons live.

### Parallel Opportunities
- Foundational domain/entity tasks (T006, T007, T008) are highly parallelizable [P].
- Within each story, Unit Tests, Usecase definitions, and pure UI components (widgets) can be built in parallel by separate developers before assembling the controllers and repositories.
- The `delete-account` Edge Function (T060, T063) can be built completely independently by a backend developer.

---

## Parallel Example: User Story 4 (Profile Management)

```bash
# Developer A focuses on the Data/Domain layer:
- T039 Unit test profile usecases
- T042 Create UserProfile domain entity
- T043 Abstract ProfileRepository contract
- T044 Implement update_profile/upload_avatar usecases
- T045 Create ProfileLocalDatasource (Drift DAO)

# Developer B focuses on UI/Presentation:
- T041 Widget test ProfileScreen
- T048 Create AvatarPicker widget
- T049 Implement ProfileController
- T050 Build ProfileScreen UI
```

---

## Implementation Strategy

### MVP First (Authentication Core)
1. Complete **Setup** & **Foundational** (T001-T010).
2. Complete **US1** (Email Auth) & **US3** (Session Storage) + **US6** (Logout only).
3. **STOP and VALIDATE**: App handles complete email lifecycle securely.

### Incremental Delivery (Fast Follows)
1. Add **US2** (Google OAuth) for improved onboarding conversion.
2. Add **US5** (Password reset) to unblock lost users.
3. Finish with **US4** (Profile Edit) and full **US6** (Account Deletion) for compliance and personalization.
