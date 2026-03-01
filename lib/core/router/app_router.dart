import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:feynman/core/router/route_names.dart';
import 'package:feynman/core/widgets/scaffold_with_nav_bar.dart';
import 'package:feynman/core/error/error_boundary.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/home/presentation/home_screen.dart';
import 'package:feynman/features/library/presentation/library_screen.dart';
import 'package:feynman/features/progress/presentation/progress_screen.dart';
import 'package:feynman/features/settings/presentation/settings_screen.dart';
import 'package:feynman/features/auth/domain/entities/auth_state.dart';
import 'package:feynman/features/auth/presentation/screens/login_screen.dart';
import 'package:feynman/features/auth/presentation/screens/register_screen.dart';
import 'package:feynman/features/auth/presentation/screens/profile_screen.dart';
import 'package:feynman/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:feynman/features/auth/presentation/screens/forgot_password_screen.dart';

/// Set of routes accessible without authentication.
const _publicRoutes = {
  RouteNames.loginPath,
  RouteNames.registerPath,
  RouteNames.verifyEmailPath,
  RouteNames.forgotPasswordPath,
};

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter is rebuilt whenever auth state changes via [refreshListenable].
  final authStateListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: RouteNames.loginPath,
    refreshListenable: authStateListenable,
    redirect: (context, routerState) {
      final authState = ref.read(authStateProvider);
      final location = routerState.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      return authState.when(
        data: (s) => s.map(
          unauthenticated: (_) => isPublic ? null : RouteNames.loginPath,
          loading: (_) => null,
          authenticated: (_) => isPublic ? RouteNames.homePath : null,
          error: (e) => isPublic
              ? null
              : '${RouteNames.loginPath}?error=${Uri.encodeComponent(e.message)}',
        ),
        loading: () => null,
        error: (_, __) => RouteNames.loginPath,
      );
    },
    routes: [
      // ── Auth routes (public) ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) {
          // Depending on the implementation, you could pass the error state down,
          // but our provider/notifier handles it now. So we just return the screen.
          return const ErrorBoundary(child: LoginScreen());
        },
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) =>
            const ErrorBoundary(child: RegisterScreen()),
      ),
      GoRoute(
        path: RouteNames.verifyEmailPath,
        name: RouteNames.verifyEmail,
        builder: (context, state) =>
            const ErrorBoundary(child: VerifyEmailScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) =>
            const ErrorBoundary(child: ForgotPasswordScreen()),
      ),

      // ── Protected shell (main app) ───────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.homePath,
                name: RouteNames.home,
                builder: (context, state) =>
                    const ErrorBoundary(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.libraryPath,
                name: RouteNames.library,
                builder: (context, state) =>
                    const ErrorBoundary(child: LibraryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.progressPath,
                name: RouteNames.progress,
                builder: (context, state) =>
                    const ErrorBoundary(child: ProgressScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settingsPath,
                name: RouteNames.settings,
                builder: (context, state) =>
                    const ErrorBoundary(child: SettingsScreen()),
              ),
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) =>
                    const ErrorBoundary(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/// [ChangeNotifier] that fires whenever [authStateProvider] changes, allowing
/// GoRouter to re-evaluate its redirect logic reactively.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}
