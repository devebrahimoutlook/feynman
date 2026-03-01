import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';

class StreakTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().unique().references(UserProfileTable, #id)();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastActivityDate => text().nullable()();
  IntColumn get totalStudyTimeMinutes =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
