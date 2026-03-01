import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';
import 'package:feynman/features/auth/domain/usecases/update_profile.dart';
import 'package:feynman/features/auth/domain/usecases/upload_avatar.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  late MockProfileRepository mockRepository;
  late UpdateProfile updateProfile;
  late UploadAvatar uploadAvatar;

  setUp(() {
    mockRepository = MockProfileRepository();
    updateProfile = UpdateProfile(mockRepository);
    uploadAvatar = UploadAvatar(mockRepository);
  });

  final tUserProfile = UserProfile(
    id: '123',
    email: 'test@example.com',
    displayName: 'Old Name',
    avatarUrl: 'old_url',
    createdAt: DateTime(2023),
    updatedAt: DateTime(2023),
  );

  group('UpdateProfile', () {
    test(
      'should call updateProfile on the repository and return the updated profile',
      () async {
        final updatedProfile = tUserProfile.copyWith(displayName: 'New Name');
        when(
          () => mockRepository.updateProfile(
            displayName: any(named: 'displayName'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenAnswer((_) async => updatedProfile);

        final result = await updateProfile(displayName: 'New Name');

        expect(result.displayName, 'New Name');
        verify(
          () => mockRepository.updateProfile(
            displayName: 'New Name',
            avatarUrl: null,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );
  });

  group('UploadAvatar', () {
    test(
      'should call uploadAvatar on the repository and return the URL',
      () async {
        final mockFile = MockFile();
        const tUrl = 'https://example.com/avatar.png';

        when(
          () => mockRepository.uploadAvatar(any()),
        ).thenAnswer((_) async => tUrl);

        final result = await uploadAvatar(mockFile);

        expect(result, tUrl);
        verify(() => mockRepository.uploadAvatar(mockFile)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );
  });
}
