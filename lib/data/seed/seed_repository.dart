import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:remory/data/app_database.dart';
import 'package:remory/data/seed/seed_bundle.dart';
import 'package:remory/repository/dtos/memo_tag_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';
import 'package:remory/repository/memo_tag_repository.dart';
import 'package:remory/repository/tag_repository.dart';
import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/memo_repository.dart';

class SeedRepository {
  final AppDatabase db;

  final MemoRepository memoRepository;
  final TagRepository tagRepository;
  final MemoTagRepository memoTagRepository;

  // 초기화 리스트: db를 먼저 파라미터로 받고, 그 db로 memoRepository를 만든다.
  // 초기화 리스트(:)를 쓰면 final 필드를 안전하게 본문 전에 초기화 가능.
  // SeedRepository(this.db) : memoRepository = MemoRepository(db);
  SeedRepository(this.db, this.memoRepository, this.tagRepository, this.memoTagRepository);

  /// 파일 삭제(안전 가드) + DB close
  Future<void> reset() async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      return; // 웹 등 파일 삭제 불가
    }
    await db.close();
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'remory.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  }

  /// 트랜잭션 + 배치 + 청크 (대량 데이터 대비)
  Future<void> write(SeedBundle bundle) async {
    if (bundle.isEmpty) return;

    await db.transaction(() async {
      await _insertMemos(bundle.memos);
      await _insertTags(bundle.tags);
      await _insertMemoTags(bundle.memoTags);
    });
  }

  // Drift batch API를 활용한 bulk insert.
  // 필요 시 OnConflict upsert로 교체 가능.
  Future<void> _insertMemos(List<MemoDto> items) async {
    if (items.isEmpty) return;
    final rows = items.map(
            (item) => MemosCompanion(
                title: Value(item.title),
                createdAt: Value(item.createdAt),
                updatedAt: Value(item.updatedAt)
            )
    ).toList();
    await _insertByChunks(rows, (chunk) async {
      await db.batch((b) => b.insertAll(db.memos, chunk));
    });
  }

  Future<void> _insertTags(List<TagDto> items) async {
    if (items.isEmpty) return;
    final rows = items.map(
            (item) => TagsCompanion(
              name: Value(item.name),
              usageCount: const Value(0),
              createdAt: Value(item.createdAt),
              updatedAt: Value(item.updatedAt),
              lastUsedAt: Value(item.updatedAt),
            )
    ).toList();
    await _insertByChunks(rows, (chunk) async {
      await db.batch((b) => b.insertAll(db.tags, chunk));
    });
  }

  Future<void> _insertMemoTags(List<MemoTagDto> items) async {
    if (items.isEmpty) return;
    final rows = items.map(
            (item) => MemoTagsCompanion(
              memoId: Value(item.memoId),
              tagId: Value(item.tagId),
              sortOrder: Value(item.sortOrder),
            )
    ).toList();
    await _insertByChunks(rows, (chunk) async {
      await db.batch((b) => b.insertAll(db.memoTags, chunk));
    });
  }

  // 공통 청크 유틸 (바인드 변수 제한 대비)
  Future<void> _insertByChunks<T>(
      List<T> rows,
      Future<void> Function(List<T>) insertChunk,
      ) async {
    const chunkSize = 500;
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
      await insertChunk(rows.sublist(i, end));
    }
  }
}