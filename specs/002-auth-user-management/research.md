# Research: Authentication & User Management

**Feature**: 002-auth-user-management
**Date**: 2026-02-28

## R-001: Supabase Auth — Email/Password Flow

**Decision**: Use `supabase_flutter` SDK methods `signUp()`, `signInWithPassword()`,
and `resetPasswordForEmail()` for email-based authentication. Email verification
is handled server-side by Supabase Auth with a redirect back to the app via deep link.

**Rationale**: Supabase Auth manages password hashing (bcrypt), session tokens
(JWT), and verification email delivery. No custom backend logic needed. The SDK
handles token persistence internally, and we layer `flutter_secure_storage` on top
for constitution compliance (Principle VI).

**Alternatives Considered**:
- *Firebase Auth*: Mature but adds a separate Google dependency alongside
  Supabase. Constitution mandates Supabase Auth exclusively.
- *Custom auth server*: Full control but massive security liability. Rejected.

---

## R-002: Supabase Auth — Google OAuth Flow

**Decision**: Use `signInWithOAuth(OAuthProvider.google)` for web, and native
Google Sign-In + `signInWithIdToken()` for Android.

**Rationale**: Web OAuth uses a redirect flow managed by Supabase. Android
uses the native `google_sign_in` package for a better UX (one-tap sign-in), then
exchanges the ID token with Supabase via `signInWithIdToken()`. This provides
the smoothest experience per platform while keeping Supabase as the identity
source of truth.

**Key Configuration**:
- Google Cloud Console: Create OAuth 2.0 client IDs (Web + Android).
- Supabase Dashboard: Enable Google provider, add client ID + secret.
- Android: Add `google-services.json` with the SHA-1 fingerprint.
- Web: Add Supabase callback URL to authorized redirect URIs.
- Deep link scheme: `com.feynman.app://login-callback/` for OAuth redirects.

**Alternatives Considered**:
- *`signInWithOAuth` for all platforms*: Works but opens an external browser
  on Android, which is a jarring UX. Native is smoother.
- *Apple Sign-In*: Spec explicitly marks this as out of scope for now.

---

## R-003: Secure Token Storage

**Decision**: Use `flutter_secure_storage` for persisting auth tokens. On
Android, tokens are encrypted via Android Keystore. On web, tokens are stored
in encrypted `localStorage` (web has limited secure storage; mitigate with
HTTP-only cookies where possible via Supabase session management).

**Rationale**: Constitution Principle VI requires secure storage — no plain
text, no SharedPreferences. `flutter_secure_storage` is the standard approach
for Flutter apps and integrates with platform keychains/keystores.

**Key Configuration**:
- Android: `EncryptedSharedPreferences` backed by Android Keystore.
- Web: `window.localStorage` with encryption (limited by browser APIs).
- Supabase SDK automates token refresh; we additionally persist the session
  for secure restoration after cold start.

**Alternatives Considered**:
- *SharedPreferences*: Stores in plain XML/JSON. Violates Principle VI.
- *Hive (encrypted box)*: Viable but adds dependency; `flutter_secure_storage`
  is purpose-built for credentials.

---

## R-004: Auth State Management with Riverpod

**Decision**: Create an `AuthNotifier` (`AsyncNotifier`) that wraps
`Supabase.instance.client.auth.onAuthStateChange` stream. Expose `AuthState`
(authenticated / unauthenticated / loading / error) as a Riverpod provider.

**Rationale**: Riverpod is constitution-mandated (Principle V). An
`AsyncNotifier` handles the initial loading state cleanly and emits
immutable state snapshots. The notifier subscribes to Supabase's auth
state changes and maps them to our `AuthState` domain enum.

**Key Configuration**:
- `authStateProvider`: `AsyncNotifierProvider<AuthNotifier, AuthState>`.
- Listens to `onAuthStateChange` for session events (signIn, signOut,
  tokenRefresh, passwordRecovery).
- On token refresh failure: emits `AuthState.unauthenticated` with error
  message, triggering GoRouter redirect.

**Alternatives Considered**:
- *StreamProvider directly*: Simpler but cannot handle imperative actions
  (login, logout) cleanly. AsyncNotifier supports both reactive streams
  and imperative methods.
- *BLoC pattern*: Would require a separate library (flutter_bloc) and
  conflicts with constitution Riverpod mandate.

---

## R-005: GoRouter Auth Guard (Route Protection)

**Decision**: Use GoRouter's `redirect` callback reading from the
`authStateProvider`. Unauthenticated users are redirected to `/login`.
Authenticated users on `/login` are redirected to `/home`.

**Rationale**: GoRouter's redirect is the standard Flutter routing guard
pattern. By making the router a Riverpod provider that listens to auth
state changes, route protection is reactive — logging out anywhere in
the app immediately triggers a redirect to login.

**Key Configuration**:
- `routerProvider` uses `ref.listen(authStateProvider, ...)` to refresh
  on auth state changes.
- Public routes: `/login`, `/register`, `/forgot-password`, `/verify-email`.
- Protected routes: everything else (all existing shell routes from 001).
- Redirect logic: if unauthenticated and not on a public route → `/login`;
  if authenticated and on a public route → `/home`.

**Alternatives Considered**:
- *Per-route guard middleware*: More granular but GoRouter's global redirect
  is sufficient and simpler for binary auth/no-auth gating.
- *Navigator.onGenerateRoute*: Legacy API; GoRouter is already adopted in
  feature 001.

---

## R-006: Deep Linking for Auth Callbacks

**Decision**: Configure custom URL scheme `com.feynman.app://` for OAuth
redirects and email verification links. Register the scheme in
`AndroidManifest.xml` (Android) and as a web redirect URL in Supabase
Dashboard.

**Rationale**: After OAuth or email verification, the browser must redirect
back to the app. Deep links are the standard mechanism for this. Supabase
Flutter SDK intercepts the redirect and extracts the session tokens.

**Key Configuration**:
- Android: Intent filter in `AndroidManifest.xml` for `com.feynman.app`.
- Web: Supabase redirect URL set to `https://<domain>/auth/callback`.
- `Supabase.initialize()` receives `authCallbackUrlHostname` for proper
  deep link handling.

**Alternatives Considered**:
- *Universal Links / App Links*: More secure but require server-side
  `.well-known` file hosting. Can be added later for production hardening.

---

## R-007: Profile Avatar Upload

**Decision**: Use Supabase Storage to upload avatar images. Crop to square
on-client using the `image_cropper` package before upload. Store the public
URL in `user_profile.avatar_url`.

**Rationale**: Supabase Storage provides direct file upload with RLS policies.
Client-side cropping ensures consistent avatar dimensions without server-side
processing. The URL is stored locally in Drift for offline profile display.

**Key Configuration**:
- Supabase Storage bucket: `avatars` (public read, authenticated write).
- Upload path: `avatars/{user_id}/profile.{ext}`.
- Max file size: 5 MB (client-side enforcement).
- Accepted formats: JPEG, PNG, WebP.

**Alternatives Considered**:
- *Firebase Storage*: Adds a Firebase dependency. Supabase Storage is
  already part of the stack.
- *Base64 in database*: Bloats the database and slows sync. Rejected.

---

## R-008: Account Deletion

**Decision**: Account deletion calls a Supabase Edge Function
(`delete-account`) that performs server-side cleanup: deletes all user
data across tables (notes, flashcards, quizzes, etc.), removes storage
files, and finally calls `supabase.auth.admin.deleteUser(userId)`.

**Rationale**: Client-side deletion cannot remove all server data securely
(RLS prevents cross-table cascading in some patterns). An Edge Function
with the service_role key handles complete data removal. Constitution
Principle VI requires the service key to stay server-side only.

**Key Configuration**:
- Edge Function validates caller's JWT to confirm identity.
- Deletes in dependency order: sync_queue → quizzes → flashcards → notes →
  folders → achievements → daily_goals → streaks → user_profile.
- Returns success/failure; client clears local Drift DB and tokens on success.

**Alternatives Considered**:
- *Client-side cascading deletes*: Cannot access admin API. Rejected.
- *Supabase database triggers*: Viable but less explicit; Edge Function
  provides clear audit trail and error handling.
