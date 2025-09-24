import 'package:drift/drift.dart';

class Memos extends Table {
  IntColumn get memoId => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)(); // DB가 자동
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())(); // insert 시 자동
  
  // 🗑️ 휴지통 기능을 위한 소프트 삭제 필드  
  // deletedAt이 null이면 활성 메모, null이 아니면 삭제된 메모
  DateTimeColumn get deletedAt => dateTime().nullable()();
}