# Quickstart: Authentication & User Management

**Feature**: 002-auth-user-management
**Date**: 2026-02-28

## Prerequisites

- Flutter SDK ≥ 3.22 (Dart ≥ 3.2)
- Feature 001-Foundation & Base Architecture MUST be implemented first
- A Supabase project with:
  - Email provider enabled in Authentication settings
  - Google OAuth provider configured (client ID + secret from Google Cloud Console)
  - `avatars` storage bucket created (public read, authenticated write)
- Google Cloud Console project with OAuth 2.0 client IDs (Web + Android)

## 1. Environment Setup

Ensure the following `--dart-define` variables are available:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

## 2. Install New Dependencies

Add to `pubspec.yaml` and run `flutter pub get`:

```yaml
dependencies:
  google_sign_in: ^6.2.0
  flutter_secure_storage: ^9.0.0
  image_cropper: ^8.0.0
```

## 3. Configure Deep Linking (Android)

Add to `android/app/src/main/AndroidManifest.xml` inside the `<activity>`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.feynman.app" />
</intent-filter>
```

## 4. Configure Supabase Dashboard

1. **Authentication → Providers → Email**: Ensure "Enable Email Provider" is on.
2. **Authentication → Providers → Google**: Add Web Client ID and Client Secret.
3. **Authentication → URL Configuration**: Add `com.feynman.app://login-callback/`
   to "Additional Redirect URLs".
4. **Storage → Create Bucket**: Name `avatars`, toggle public.

## 5. Deploy Edge Function

```bash
supabase functions deploy delete-account
```

## 6. Run Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 7. Run the App

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your_client_id
```

## 8. Run Tests

```bash
# All auth tests
flutter test test/features/auth/
flutter test test/core/providers/auth_provider_test.dart
flutter test test/core/router/app_router_auth_test.dart

# Edge Function test
cd supabase/functions/delete-account && deno test

# Full suite
flutter test
```

## 9. Test Scenarios

| Scenario | Steps | Expected |
|----------|-------|----------|
| Email Registration | Open app → Register → Enter email/password → Submit | Verification email sent, "Check email" screen shown |
| Email Login | Verify email → Open app → Login with credentials | Navigated to Home |
| Google OAuth | Open app → "Continue with Google" → Complete flow | Navigated to Home, account created in Supabase |
| Session Persistence | Login → Force-close → Reopen | Goes directly to Home (no login screen) |
| Forgot Password | Login screen → "Forgot?" → Enter email → Submit | "If account exists" message shown |
| Logout | Settings → Log out | Navigated to Login, tokens cleared |
| Profile Edit | Settings → Profile → Change name → Save | Name updated, reflected immediately |
| Account Deletion | Settings → Account → Delete → Type "DELETE" → Confirm | Logged out, data removed |
| Offline Profile | Login → Airplane mode → Settings → Profile | Profile data visible from cache |
