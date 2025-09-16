import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/repository/memo_tag_repository.dart';

final memoTagRepositoryProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  return MemoTagRepository(db);
});