import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';
import 'package:feynman/core/database/tables/note_table.dart';

class FeynmanSessionTable extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(NoteTable, #id)();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get topic => text()();
  TextColumn get inputType => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  RealColumn get clarityScore => real().nullable()();
  RealColumn get accuracyScore => real().nullable()();
  RealColumn get structureScore => real().nullable()();
  RealColumn get examplesScore => real().nullable()();
  TextColumn get feedback => text().nullable()();
  IntColumn get attemptNumber => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
