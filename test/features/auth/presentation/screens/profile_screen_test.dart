import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/features/auth/domain/entities/auth_state.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/core/providers/auth_provider.dart';
import 'package:feynman/features/auth/presentation/controllers/profile_controller.dart';
import 'package:feynman/features/auth/presentation/screens/profile_screen.dart';
import 'package:feynman/features/auth/presentation/widgets/avatar_picker.dart';

class FakeAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  final AuthState initialState;
  FakeAuthNotifier(this.initialState);

  @override
  Future<AuthState> build() async => initialState;

  @override
  void updateProfile(UserProfile profile) {
    state = AsyncData(AuthState.authenticated(user: profile));
  }
}

class FakeProfileController extends AutoDisposeAsyncNotifier<void>
    implements ProfileController {
  final AsyncValue<void> initialState;
  FakeProfileController(this.initialState);

  @override
  FutureOr<void> build() {
    state = initialState;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> uploadAvatar(File imageFile) async {}
}

void main() {
  final tUser = UserProfile(
    id: '123',
    email: 'test@example.com',
    displayName: 'Test User',
    avatarUrl: null,
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
  );

  Widget createWidgetUnderTest({
    required UserProfile user,
    AsyncValue<void> profileState = const AsyncValue.data(null),
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          () => FakeAuthNotifier(AuthState.authenticated(user: user)),
        ),
        profileControllerProvider.overrideWith(
          () => FakeProfileController(profileState),
        ),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('renders ProfileScreen with user details', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(user: tUser));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.byType(AvatarPicker), findsOneWidget);
  });

  testWidgets('shows loading indicator when profile is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarPicker(
            currentAvatarUrl: null,
            isLoading: true,
            onImageCropped: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
