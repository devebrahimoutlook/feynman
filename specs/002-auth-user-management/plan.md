# Implementation Plan: Authentication & User Management

**Branch**: `002-auth-user-management` | **Date**: 2026-02-28 | **Spec**: [spec.md](file:///d:/opus%20projects/specs/002-auth-user-management/spec.md)
**Input**: Feature specification from `/specs/002-auth-user-management/spec.md`

## Summary

Add complete authentication and user management to the Feynman app: email/password
registration with email verification, Google OAuth sign-in, secure token storage,
session persistence, auth-gated routing, user profile management, password reset,
logout, and account deletion. Builds on the 001-Foundation architecture (Riverpod,
GoRouter, Drift, Supabase client) without modifying its existing contracts.

## Technical Context

**Language/Version**: Dart ≥ 3.2 with sound null-safety
**Primary Dependencies**: supabase_flutter (Auth + Storage), google_sign_in (Android native OAuth), flutter_secure_storage, image_cropper, riverpod_generator, go_router, freezed
**Storage**: Drift/SQLite (local profile), Supabase PostgreSQL + Auth + Storage (remote)
**Testing**: flutter_test (unit + widget), integration_test, deno test (Edge Functions)
**Target Platform**: Android SDK 24+, Web (Chrome/Firefox/Safari/Edge latest 2)
**Project Type**: Mobile + Web cross-platform application
**Edge Functions**: `delete-account` (Deno/TypeScript)

## Constitution Check

| Principle | Gate | Status |
|-----------|------|--------|
| I. Clean Architecture | Auth feature split into `presentation/domain/data` layers; domain has zero framework imports | ✅ Pass |
| II. Offline-First | Profile persisted in Drift; login state cached locally; auth actions queue when offline | ✅ Pass |
| III. Test-Driven Development | Tests for auth state, route guards, profile repository, Edge Function | ✅ Pass |
| IV. Background Isolation | Avatar upload + cropping offloaded; no blocking on UI thread | ✅ Pass |
| V. Immutable State | `AuthState` as freezed union; `AuthNotifier` as AsyncNotifier | ✅ Pass |
| VI. Security by Default | `flutter_secure_storage` for tokens; RLS on user_profile; service key server-only; `--dart-define` for config | ✅ Pass |
| VII. Feature-Based Modules | `lib/features/auth/` with `presentation/domain/data` sub-dirs | ✅ Pass |
| VIII. Observability | Auth events logged at domain boundary; error boundaries on auth screens | ✅ Pass |

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-user-management/
├── spec.md
├── research.md
├── data-model.md
├── plan.md              # This file
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/features/auth/
├── presentation/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── verify_email_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/
│   │   ├── auth_form_field.dart        # Reusable styled text field
│   │   ├── password_strength_indicator.dart
│   │   ├── social_login_button.dart    # "Continue with Google" button
│   │   └── avatar_picker.dart          # Avatar display + upload widget
│   └── controllers/
│       ├── login_controller.dart       # Form logic for login
│       ├── register_controller.dart    # Form logic + validation
│       ├── forgot_password_controller.dart
│       └── profile_controller.dart     # Profile edit actions
├── domain/
│   ├── entities/
│   │   ├── auth_state.dart             # Freezed union: authenticated|unauthenticated|loading|error
│   │   ├── user_session.dart           # Domain session model
│   │   └── user_profile.dart           # Domain profile entity (extends 001)
│   ├── repositories/
│   │   ├── auth_repository.dart        # Abstract contract
│   │   └── profile_repository.dart     # Abstract contract
│   └── usecases/
│       ├── sign_in_with_email.dart
│       ├── sign_in_with_google.dart
│       ├── sign_up_with_email.dart
│       ├── sign_out.dart
│       ├── reset_password.dart
│       ├── get_current_user.dart
│       ├── update_profile.dart
│       ├── upload_avatar.dart
│       └── delete_account.dart
└── data/
    ├── repositories/
    │   ├── auth_repository_impl.dart   # Supabase Auth SDK calls
    │   └── profile_repository_impl.dart # Drift + Supabase Storage
    ├── datasources/
    │   ├── auth_remote_datasource.dart # Supabase Auth wrapper
    │   ├── profile_local_datasource.dart  # Drift user_profile DAO
    │   └── profile_remote_datasource.dart # Supabase profile + storage
    └── mappers/
        ├── user_profile_mapper.dart    # Supabase User ↔ domain entity
        └── auth_state_mapper.dart      # AuthChangeEvent ↔ AuthState

lib/core/
├── providers/
│   └── auth_provider.dart              # AuthNotifier + authStateProvider
├── router/
│   └── app_router.dart                 # MODIFIED: Add redirect guard + auth routes

supabase/functions/
└── delete-account/
    ├── index.ts                        # Edge Function entry point
    └── index_test.ts                   # Deno test

test/
├── features/auth/
│   ├── domain/
│   │   └── usecases/
│   │       ├── sign_in_with_email_test.dart
│   │       ├── sign_up_with_email_test.dart
│   │       └── sign_out_test.dart
│   ├── data/
│   │   └── repositories/
│   │       ├── auth_repository_impl_test.dart
│   │       └── profile_repository_impl_test.dart
│   └── presentation/
│       ├── screens/
│       │   ├── login_screen_test.dart
│       │   └── register_screen_test.dart
│       └── controllers/
│           └── login_controller_test.dart
├── core/
│   ├── providers/
│   │   └── auth_provider_test.dart
│   └── router/
│       └── app_router_auth_test.dart

integration_test/
└── auth_flow_test.dart                 # End-to-end: register → verify → login → logout
```

## Complexity Tracking

> No Constitution Check violations. No complexity justifications required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| *None*    | —          | —                                    |

## Verification Plan

### Automated Tests

All tests run from the repository root.

1. **Domain Use-Case Tests** — verify use-cases delegate correctly to
   repository contracts and return expected domain entities:
   ```bash
   flutter test test/features/auth/domain/
   ```

2. **Repository Implementation Tests** — verify Supabase SDK calls and
   Drift persistence using mocks/fakes:
   ```bash
   flutter test test/features/auth/data/
   ```

3. **Auth Provider Test** — verify `AuthNotifier` transitions through
   loading → authenticated/unauthenticated states correctly:
   ```bash
   flutter test test/core/providers/auth_provider_test.dart
   ```

4. **Route Guard Test** — verify unauthenticated users are redirected
   to `/login` and authenticated users bypass the guard:
   ```bash
   flutter test test/core/router/app_router_auth_test.dart
   ```

5. **Widget Tests** — verify login/register screens render correctly,
   show validation errors, and call controllers:
   ```bash
   flutter test test/features/auth/presentation/
   ```

6. **Edge Function Test** — verify `delete-account` validates JWT,
   cascades deletes, and returns proper responses:
   ```bash
   cd supabase/functions/delete-account && deno test
   ```

7. **Integration Test** — end-to-end flow testing:
   ```bash
   flutter test integration_test/auth_flow_test.dart
   ```

8. **Lint + Format Gate**:
   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   ```

### Manual Verification

1. **Android**: Install APK on emulator. Register with email, verify email
   via Supabase dashboard (or check inbox), log in, verify Home screen loads.
   Log out, verify redirect to login.

2. **Google OAuth on Android**: Tap "Continue with Google", complete sign-in,
   verify account is created in Supabase Dashboard → Authentication → Users.

3. **Web**: Run `flutter run -d chrome`. Complete email registration and
   Google OAuth flows. Verify deep link redirect works after email verification.

4. **Session Persistence**: Log in, force-close app, reopen. Verify no
   login screen — goes directly to Home.

5. **Offline Profile**: Log in, enable airplane mode, navigate to Settings →
   Profile. Verify display name and avatar are visible.

6. **Account Deletion**: From Settings → Account → Delete Account, type
   "DELETE", confirm. Verify redirect to login and check Supabase Dashboard
   to confirm user is removed.
