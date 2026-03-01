import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';
import 'package:feynman/core/database/tables/note_table.dart';

class QuizTable extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(NoteTable, #id)();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get title => text()();
  RealColumn get bestScore => real().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
