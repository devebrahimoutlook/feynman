import 'package:drift/drift.dart';
import 'package:feynman/core/database/tables/quiz_table.dart';

class QuizQuestionTable extends Table {
  TextColumn get id => text()();
  TextColumn get quizId => text().references(QuizTable, #id)();
  TextColumn get questionText => text()();
  TextColumn get questionType => text()();
  TextColumn get options => text().nullable()();
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
