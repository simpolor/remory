import 'package:drift/drift.dart';

class Memos extends Table {
  IntColumn get memoId => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)(); // DB가 자동
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())(); // insert 시 자동
}