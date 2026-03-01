import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:feynman/core/error/app_exception.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/data/datasources/profile_local_datasource.dart';
import 'package:feynman/features/auth/data/datasources/profile_remote_datasource.dart';
import 'package:feynman/features/auth/data/repositories/profile_repository_impl.dart';
import 'package:feynman/core/logging/app_logger.dart';

class MockProfileLocalDatasource extends Mock
    implements ProfileLocalDatasource {}

class MockProfileRemoteDatasource extends Mock
    implements ProfileRemoteDatasource {}

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockUser extends Mock implements supa.User {}

class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

class FakeUserProfile extends Fake implements UserProfile {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockProfileLocalDatasource mockLocal;
  late MockProfileRemoteDatasource mockRemote;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockAppLogger mockLogger;
  late ProfileRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    mockLocal = MockProfileLocalDatasource();
    mockRemote = MockProfileRemoteDatasource();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockLogger = MockAppLogger();

    when(() => mockSupabase.auth).thenReturn(mockAuth);

    repository = ProfileRepositoryImpl(
      localDatasource: mockLocal,
      remoteDatasource: mockRemote,
      supabaseClient: mockSupabase,
      logger: mockLogger,
    );
  });

  const tUserId = '123';
  final tUser = MockUser();
  when(() => tUser.id).thenReturn(tUserId);

  final tUserProfile = UserProfile(
    id: tUserId,
    email: 'test@example.com',
    displayName: 'Test User',
    avatarUrl: 'old_url',
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
  );

  group('updateProfile', () {
    test(
      'should return remote profile and save locally when remote is successful',
      () async {
        when(() => mockAuth.currentUser).thenReturn(tUser);
        when(
          () => mockRemote.updateProfile(
            userId: tUserId,
            displayName: any(named: 'displayName'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenAnswer((_) async => tUserProfile);
        when(() => mockLocal.saveProfile(any())).thenAnswer((_) async {});

        final result = await repository.updateProfile(displayName: 'Test User');

        expect(result, tUserProfile);
        verify(
          () => mockRemote.updateProfile(
            userId: tUserId,
            displayName: 'Test User',
            avatarUrl: null,
          ),
        ).called(1);
        verify(() => mockLocal.saveProfile(tUserProfile)).called(1);
      },
    );

    test(
      'should update local only when remote fails and local record exists',
      () async {
        when(() => mockAuth.currentUser).thenReturn(tUser);
        when(
          () => mockRemote.updateProfile(
            userId: tUserId,
            displayName: any(named: 'displayName'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenThrow(const AuthException(message: 'Network error'));
        when(
          () => mockLocal.getProfile(tUserId),
        ).thenAnswer((_) async => tUserProfile);
        when(() => mockLocal.saveProfile(any())).thenAnswer((_) async {});

        final result = await repository.updateProfile(displayName: 'New Name');

        expect(result.displayName, 'New Name');
        verify(() => mockLocal.getProfile(tUserId)).called(1);
        verify(() => mockLocal.saveProfile(any())).called(1);
      },
    );
  });

  group('uploadAvatar', () {
    test(
      'should upload remote and then update profile with public URL',
      () async {
        const tUrl = 'https://example.com/avatar.png';
        final mockFile = MockFile();
        when(() => mockFile.path).thenReturn('profile.png');
        when(() => mockAuth.currentUser).thenReturn(tUser);
        when(
          () => mockRemote.uploadAvatar(
            userId: tUserId,
            imageFile: any(named: 'imageFile'),
            extension: any(named: 'extension'),
          ),
        ).thenAnswer((_) async => tUrl);

        // Also need to stub updateProfile call inside uploadAvatar
        when(
          () => mockRemote.updateProfile(
            userId: tUserId,
            displayName: any(named: 'displayName'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenAnswer((_) async => tUserProfile.copyWith(avatarUrl: tUrl));
        when(() => mockLocal.saveProfile(any())).thenAnswer((_) async {});

        final result = await repository.uploadAvatar(mockFile);

        expect(result, tUrl);
        verify(
          () => mockRemote.uploadAvatar(
            userId: tUserId,
            imageFile: mockFile,
            extension: 'png',
          ),
        ).called(1);
        verify(
          () => mockRemote.updateProfile(userId: tUserId, avatarUrl: tUrl),
        ).called(1);
      },
    );
  });
}
