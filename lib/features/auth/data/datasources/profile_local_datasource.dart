import 'package:drift/drift.dart' as drift;
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/features/auth/domain/entities/user_profile.dart';

/// Local datasource for the user profile using Drift.
abstract interface class ProfileLocalDatasource {
  /// Fetches a cached profile by [userId].
  Future<UserProfile?> getProfile(String userId);

  /// Saves or updates the given [profile] locally.
  Future<void> saveProfile(UserProfile profile);

  /// Clears the cached profile for [userId].
  Future<void> clearProfile(String userId);
}

class ProfileLocalDatasourceImpl implements ProfileLocalDatasource {
  final AppDatabase _db;

  const ProfileLocalDatasourceImpl(this._db);

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final record = await (_db.select(
      _db.userProfileTable,
    )..where((t) => t.id.equals(userId))).getSingleOrNull();

    if (record == null) return null;

    return UserProfile(
      id: record.id,
      email: record.email,
      displayName: record.displayName,
      avatarUrl: record.avatarUrl,
      level: record.level,
      totalXp: record.totalXp,
      authProvider: record.authProvider,
      emailVerified: record.emailVerified,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _db
        .into(_db.userProfileTable)
        .insertOnConflictUpdate(
          UserProfileTableCompanion.insert(
            id: profile.id,
            email: profile.email,
            displayName: drift.Value(profile.displayName),
            avatarUrl: drift.Value(profile.avatarUrl),
            level: drift.Value(profile.level),
            totalXp: drift.Value(profile.totalXp),
            authProvider: drift.Value(profile.authProvider),
            emailVerified: drift.Value(profile.emailVerified),
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
          ),
        );
  }

  @override
  Future<void> clearProfile(String userId) async {
    await (_db.delete(
      _db.userProfileTable,
    )..where((t) => t.id.equals(userId))).go();
  }
}
