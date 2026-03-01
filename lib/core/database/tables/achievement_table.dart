import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';

class AchievementTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get badgeType => text()();
  DateTimeColumn get earnedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
