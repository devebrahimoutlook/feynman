# Feature Specification: Authentication & User Management

## Overview

This feature provides secure user registration, login, session management, and
profile administration for the Feynman learning application. Users must be able
to create accounts, authenticate using multiple methods, manage their profiles,
and have their sessions persist securely across app restarts. Authentication
gates access to personal learning data, ensuring each user's notes, flashcards,
progress, and gamification history remain private and correctly attributed.

## Dependencies

- **001-Foundation & Base Architecture**: Navigation shell, Riverpod DI,
  Drift local database, Supabase client initialization, error boundaries,
  and structured logging must be operational before authentication can be
  integrated.

## Assumptions

- The Supabase Auth service is the identity provider for all authentication
  methods (email/password and Google OAuth).
- The application supports two platforms: Android and Web.
- "Guest mode" or anonymous access is not supported — users must authenticate
  to access learning features.
- Password reset is performed via email link, handled server-side by
  Supabase Auth.
- The onboarding flow (welcome screens, initial preferences) is a separate
  feature specification and is not included here. This spec covers only the
  authentication and profile management aspects.
- Email verification is required before the account is considered active.
- Session tokens are refreshed automatically and do not require user
  interaction.

---

## User Stories

### US1: Email Registration & Login (Priority: P1)

**As a** new user,
**I want to** register with my email and password,
**So that** I can create a personal account and begin learning.

**Acceptance Criteria:**

- The registration screen collects email and password.
- Password must meet minimum strength requirements: at least 8 characters,
  containing at least one uppercase letter, one lowercase letter, and one
  digit.
- On successful registration, a verification email is sent to the provided
  address.
- The user sees a "check your email" confirmation screen after submitting
  registration.
- After verifying their email, the user can log in with their credentials.
- On successful login, the user is navigated to the Home screen.
- Invalid email format or weak password is rejected with a specific,
  human-readable error message before submission.
- A user who already has an account is shown an appropriate message when
  attempting to register with the same email.

### US2: Google OAuth Login (Priority: P1)

**As a** user,
**I want to** sign in with my Google account,
**So that** I can access Feynman without creating a separate password.

**Acceptance Criteria:**

- A "Continue with Google" button is visible on the login/registration screen.
- Tapping the button initiates the Google OAuth flow using the platform's
  native mechanism (Android: Google Sign-In SDK; Web: OAuth redirect).
- On first-time Google sign-in, an account is automatically created and
  linked to the Google identity.
- On subsequent Google sign-ins, the user is logged into their existing
  account.
- If the Google account's email matches an existing email/password account,
  the accounts are linked rather than duplicated.
- On successful authentication, the user is navigated to the Home screen.
- If the user cancels the Google sign-in flow, they are returned to the
  login screen without error.

### US3: Session Persistence & Secure Token Storage (Priority: P1)

**As a** returning user,
**I want to** remain logged in when I reopen the app,
**So that** I can resume learning immediately without re-entering credentials.

**Acceptance Criteria:**

- After a successful login, the user's session persists across app restarts.
- Authentication tokens are stored using secure platform storage, not in
  plain text or shared preferences.
- Tokens are refreshed automatically before expiration without user
  interaction.
- If the token cannot be refreshed (e.g., revoked server-side), the user is
  redirected to the login screen with an informative message.
- Logging out clears all stored tokens and returns the user to the login
  screen.

### US4: User Profile Management (Priority: P2)

**As an** authenticated user,
**I want to** view and edit my profile information,
**So that** I can personalize my account and keep my details current.

**Acceptance Criteria:**

- The user can view their profile from the Settings screen (implemented as `ProfileScreen`), displaying:
  display name, email address, avatar, and account creation date.
- The user can update their display name.
- The user can upload or change their profile avatar image.
- Avatar images are cropped to a square aspect ratio before upload.
- Email address is displayed but cannot be changed from within the app
  (changes require a separate email-change flow managed by the identity
  provider).
- Changes are saved and reflected immediately in the UI.
- Profile data is synced to the server when connectivity is available and
  remains accessible offline.

### US5: Password Reset (Priority: P2)

**As a** user who has forgotten their password,
**I want to** reset my password via email,
**So that** I can regain access to my account.

**Acceptance Criteria:**

- A "Forgot password?" link is available on the login screen.
- Tapping the link opens a screen where the user enters their registered
  email address.
- On submission, a password-reset email is sent to the address.
- A confirmation message is shown: "If an account exists with this email,
  you'll receive a reset link shortly."
- The reset link in the email allows the user to set a new password.
- After resetting, the user can log in with the new password.
- The message shown does not reveal whether the email is registered (to
  prevent account enumeration).

### US6: Logout & Account Deletion (Priority: P3)

**As an** authenticated user,
**I want to** log out or permanently delete my account,
**So that** I can control my access and data.

**Acceptance Criteria:**

- A "Log out" option is accessible from the Settings screen (implemented as `ProfileScreen`).
- Logging out clears all local authentication tokens and navigates to the
  login screen.
- Local learning data remains on the device after logout (the user can log
  back in to access it).
- A "Delete account" option is accessible from the Settings screen (implemented as `ProfileScreen`) under
  an "Account" section.
- Account deletion requires the user to confirm with a typed confirmation
  phrase (e.g., "DELETE").
- Deleting an account removes all server-side data associated with the user.
- After deletion, the user is logged out and local data is cleared.
- The deletion process is irreversible and the user is warned accordingly.

---

## Functional Requirements

### FR-001: Registration Screen

The system MUST provide a registration screen with email and password input
fields, a "Register" action button, input validation with real-time feedback,
and a link to navigate to the login screen for existing users.

### FR-002: Login Screen

The system MUST provide a login screen with email and password fields, a
"Log in" action button, a "Continue with Google" button, a "Forgot password?"
link, and a link to navigate to the registration screen for new users.

### FR-003: Password Strength Validation

The system MUST validate passwords against minimum requirements (8+
characters, at least one uppercase letter, one lowercase letter, one digit)
and display strength feedback before the user submits the form.

### FR-004: Email Verification

The system MUST send a verification email upon registration and prevent login
until the email has been verified. The verification confirmation screen MUST
include an option to resend the verification email.

### FR-005: Google OAuth Integration

The system MUST support Google OAuth authentication, automatically creating
accounts for first-time users and linking to existing accounts when the email
matches. The flow MUST use the platform-native mechanism (Android native
sign-in, Web redirect).

### FR-006: Secure Token Storage

The system MUST store authentication tokens in secure platform storage.
Tokens MUST NOT be stored in plain text, shared preferences, or local
storage accessible to other applications.

### FR-007: Automatic Token Refresh

The system MUST refresh authentication tokens automatically before they
expire. If a refresh fails, the user MUST be redirected to the login screen
with an explanatory message.

### FR-008: Authenticated Route Protection

The system MUST prevent unauthenticated users from accessing any screen
except the login, registration, password reset, and email verification
screens. Attempts to navigate to protected routes MUST redirect to the
login screen.

### FR-009: Local Profile Persistence

The user's profile data (display name, email, avatar URL, level, XP) MUST
be stored locally in the Drift database and available when offline. Profile
changes MUST sync to the server when connectivity is restored.

### FR-010: Profile Editing

The system MUST allow users to update their display name and avatar image.
Avatar uploads MUST be cropped to a square aspect ratio and stored via the
backend storage service.

### FR-011: Password Reset Flow

The system MUST provide a password-reset flow that sends a reset email. The
response message MUST NOT reveal whether the email is associated with an
existing account.

### FR-012: Logout

The system MUST clear all stored authentication tokens on logout, navigate
the user to the login screen, and preserve local learning data for
potential re-login.

### FR-013: Account Deletion

The system MUST provide account deletion functionality requiring explicit
user confirmation. Deletion MUST remove all server-side user data and clear
all local data. The action MUST be irreversible.

### FR-014: Auth State Observation

The system MUST expose the current authentication state (authenticated,
unauthenticated, loading) as a reactive stream. UI components MUST respond
to auth state changes immediately (e.g., redirecting on logout, updating
nav guards).

---

## Key Entities

### AuthState

Represents the current authentication status of the user.

- **status**: The authentication state (authenticated, unauthenticated,
  loading, error)
- **user**: Reference to the authenticated user's profile (when
  authenticated)
- **error_message**: Human-readable error description (when in error state)

### UserSession

Represents an active login session.

- **user_id**: Reference to the user's profile
- **auth_provider**: The method used to authenticate (email, google)
- **created_at**: When the session was established
- **last_active_at**: Last activity timestamp
- **is_active**: Whether the session is currently valid

### UserProfile (extends entity from 001-Foundation)

- **id**: Unique user identifier (from auth provider)
- **email**: Registered email address
- **display_name**: User-chosen display name
- **avatar_url**: URL to the user's profile image
- **level**: Current gamification level
- **total_xp**: Accumulated experience points
- **auth_provider**: How the user registered (email, google)
- **email_verified**: Whether the email has been verified
- **created_at**: Account creation timestamp
- **updated_at**: Last modification timestamp

---

## Success Criteria

### SC-001: Registration Completion Rate

At least 80% of users who begin the registration flow complete it
successfully (including email verification) within 24 hours.

### SC-002: Login Success Rate

At least 95% of login attempts by users with valid credentials succeed on
the first attempt.

### SC-003: Session Persistence

Returning users are presented with their authenticated Home screen within
2 seconds of launching the app, without needing to re-enter credentials.

### SC-004: Password Reset Turnaround

Users who initiate a password reset receive the reset email within 2
minutes and can successfully log in with a new password.

### SC-005: Offline Profile Access

Users can view their full profile information when the device is offline.
Profile updates made offline sync within 30 seconds of connectivity being
restored.

### SC-006: Account Security

Zero instances of authentication tokens being exposed in application logs,
error reports, or client-accessible storage outside of secure platform
mechanisms.

### SC-007: Google OAuth Adoption

At least 40% of new registrations use Google OAuth as their authentication
method.

### SC-008: Account Deletion Compliance

Account deletion requests are fully processed (all server-side data removed)
within 24 hours.

---

## Edge Cases

### EC-001: Network Loss During Registration

If the network drops after the user submits registration but before the server
responds, the system retries the request when connectivity is restored. If the
account was created server-side but the confirmation was not received, a
subsequent login attempt with the same credentials succeeds.

### EC-002: Google Account Already Linked

If a user attempts Google sign-in with an email that already has an
email/password account, the system links the Google identity to the existing
account rather than creating a duplicate. The user is notified of the linking.

### EC-003: Expired Verification Email

If the email verification link expires before the user clicks it, the
verification screen provides a "Resend verification email" option. The original
registration remains valid.

### EC-004: Concurrent Multi-Device Login

If the same user logs in on multiple devices, all devices maintain active
sessions. Profile changes on one device sync to other active sessions when
connectivity allows.

### EC-005: Account Deletion with Pending Sync

If the user requests account deletion while local data has not yet synced to
the server, the system warns the user that unsynced data will be permanently
lost and requires confirmation before proceeding.

### EC-006: Token Revocation

If the server revokes the user's refresh token (e.g., password change from
another device, admin action), the app detects the invalid token on the next
API call and redirects the user to the login screen with a message explaining
that they need to sign in again.

---

## Out of Scope

- **Two-factor authentication (2FA)**: Not included in this feature. May be
  addressed in a future security hardening specification.
- **Social logins beyond Google**: Only Google OAuth is in scope. Apple
  Sign-In and other providers may be added later.
- **Onboarding flow**: Welcome screens, initial preference setting, and
  guided tour are covered by a separate specification.
- **Admin user management**: Backend administrative tools for managing user
  accounts are not part of this feature.
- **Username-based login**: Users authenticate with email, not username.
