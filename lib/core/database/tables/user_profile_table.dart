import 'package:drift/drift.dart';

/// Drift table for [UserProfile].
/// Schema Version 2 adds [authProvider] and [emailVerified].
class UserProfileTable extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  // Added in schema v2 (002-auth-user-management)
  TextColumn get authProvider => text().withDefault(const Constant('email'))();
  BoolColumn get emailVerified =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
