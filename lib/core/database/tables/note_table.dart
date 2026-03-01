import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';
import 'package:feynman/core/database/tables/folder_table.dart';

class NoteTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get folderId => text().nullable().references(FolderTable, #id)();
  TextColumn get title => text()();
  TextColumn get sourceType => text()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get definitions => text().nullable()();
  TextColumn get examples => text().nullable()();
  TextColumn get tags => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get processingStatus =>
      text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
