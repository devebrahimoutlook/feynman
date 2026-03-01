import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';

class FolderTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#4A9EFF'))();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
