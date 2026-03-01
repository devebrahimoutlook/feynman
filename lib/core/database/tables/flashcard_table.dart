import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/user_profile_table.dart';
import 'package:feynman/core/database/tables/note_table.dart';

class FlashcardTable extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(NoteTable, #id)();
  TextColumn get userId => text().references(UserProfileTable, #id)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get hint => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('new'))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitionCount => integer().withDefault(const Constant(0))();
  IntColumn get lapseCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
