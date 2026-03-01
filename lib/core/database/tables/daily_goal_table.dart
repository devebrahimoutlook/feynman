import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';

class DailyGoalTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  IntColumn get notesTarget => integer().withDefault(const Constant(1))();
  IntColumn get flashcardsTarget => integer().withDefault(const Constant(10))();
  IntColumn get studyMinutesTarget =>
      integer().withDefault(const Constant(15))();
  TextColumn get date => text()();
  IntColumn get notesCompleted => integer().withDefault(const Constant(0))();
  IntColumn get flashcardsCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get studyMinutesCompleted =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
