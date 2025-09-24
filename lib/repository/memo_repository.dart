import 'package:remory/data/app_database.dart';
import 'package:drift/drift.dart';
import 'package:remory/repository/dtos/memo_with_tags_dto.dart';
import 'package:remory/provider/state/memo_cursor.dart';
import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class MemoRepository {
  final AppDatabase db;

  MemoRepository(this.db);

  Future<List<MemoDto>> fetchAllMemos() async {
    final query = db.select(db.memos)
      ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.memoId, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map(MemoDto.fromEntity).toList();
  }

  Future<List<MemoDto>> fetchMemosWithAfter({
    MemoCursor? memoCursor,
    required int limit,
    String? searchQuery,
  }) async {
    if (searchQuery?.isNotEmpty == true) {
      return _fetchMemosWithFTS(searchQuery!, memoCursor, limit);
    } else {
      return _fetchMemosNormal(memoCursor, limit);
    }
  }

  // 일반 메모 조회 (삭제되지 않은 메모만)
  Future<List<MemoDto>> _fetchMemosNormal(
    MemoCursor? memoCursor,
    int limit,
  ) async {
    final query = db.select(db.memos)
      ..where((tbl) => tbl.deletedAt.isNull()) // 🔥 isDeleted → deletedAt로 변경
      ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.memoId,    mode: OrderingMode.desc),
      ])
      ..limit(limit);

    if (memoCursor != null) {
      query.where((tbl) =>
        tbl.createdAt.isSmallerThanValue(memoCursor.createdAt) |
        (tbl.createdAt.equals(memoCursor.createdAt) &
        tbl.memoId.isSmallerThanValue(memoCursor.id))
      );
    }

    final rows = await query.get();
    return rows.map(MemoDto.fromEntity).toList();
  }

  // FTS 검색 조회
  Future<List<MemoDto>> _fetchMemosWithFTS(
    String searchQuery,
    MemoCursor? memoCursor,
    int limit,
  ) async {
    // FTS 검색어 준비
    final ftsQuery = _prepareFTSQuery(searchQuery);
    
    String sql = '''
      SELECT m.memo_id, m.title, m.view_count, m.created_at, m.updated_at, m.deleted_at
      FROM memos m
      JOIN memos_fts fts ON m.memo_id = fts.rowid
      WHERE memos_fts MATCH ? AND m.deleted_at IS NULL
    ''';
    
    List<Variable> args = [Variable.withString(ftsQuery)];
    
    // 커서 조건 추가
    if (memoCursor != null) {
      sql += '''
        AND (
          m.created_at < ? OR 
          (m.created_at = ? AND m.memo_id < ?)
        )
      ''';
      args.addAll([
        Variable.withInt(memoCursor.createdAt.millisecondsSinceEpoch),
        Variable.withInt(memoCursor.createdAt.millisecondsSinceEpoch),
        Variable.withInt(memoCursor.id),
      ]);
    }
    
    sql += '''
      ORDER BY m.created_at DESC, m.memo_id DESC
      LIMIT ?
    ''';
    args.add(Variable.withInt(limit));

    final result = await db.customSelect(sql, variables: args).get();
    
    return result.map((row) {
      return MemoDto(
        memoId: row.read<int>('memo_id'),
        title: row.read<String>('title'),
        viewCount: row.read<int>('view_count'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
      );
    }).toList();
  }

  // FTS 검색어 준비
  String _prepareFTSQuery(String query) {
    // 특수문자 제거하고 접두사 검색으로 변환
    final cleanQuery = query
        .replaceAll(RegExp(r'[^\w\sㄱ-ㅎ가-힣]'), ' ') // 특수문자 제거
        .trim()
        .split(RegExp(r'\s+')) // 공백으로 분리
        .where((word) => word.length >= 1) // 1글자 이상
        .map((word) => '"$word"*') // 각 단어를 따옴표로 감싸고 접두사 검색
        .join(' OR '); // OR 조건으로 결합
    
    return cleanQuery.isNotEmpty ? cleanQuery : '"${query.trim()}"*';
  }

  Future<List<MemoDto>> fetchMemosByTagIdPaged({
    required int tagId,
    MemoCursor? memoCursor,
    required int limit,
  }) async {
    final m = db.memos;
    final mt = db.memoTags;

    final query = db.select(m).join([
      innerJoin(mt, mt.memoId.equalsExp(m.memoId)),
    ])
      ..where(mt.tagId.equals(tagId) & m.deletedAt.isNull()) // 🗑️ 삭제된 메모 제외
      ..orderBy([
        OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
        OrderingTerm(expression: m.memoId, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    // 커서 조건 추가
    if (memoCursor != null) {
      query.where(
          m.createdAt.isSmallerThanValue(memoCursor.createdAt) |
          (m.createdAt.equals(memoCursor.createdAt) &
          m.memoId.isSmallerThanValue(memoCursor.id))
      );
    }

    final rows = await query.get();
    return rows.map((row) => MemoDto.fromEntity(row.readTable(m))).toList();
  }

  Future<MemoDto?> findMemoById(int memoId) async {
    final memo = await (
        db.select(db.memos)
          ..where((tbl) => tbl.memoId.equals(memoId))
    ).getSingleOrNull();

    if (memo == null) return null;

    return MemoDto.fromEntity(memo);
  }

  Future<MemoWithTagsDto?> fetchMemoWithTagsById(int memoId) async {
    final query = (db.select(db.memos)..where((m) => m.memoId.equals(memoId))).join([
      leftOuterJoin(db.memoTags, db.memoTags.memoId.equalsExp(db.memos.memoId)),
      leftOuterJoin(db.tags, db.tags.tagId.equalsExp(db.memoTags.tagId)),
    ]);

    final rows = await query.get(); // ← watch() 대신 get()

    final memo = rows.first.readTable(db.memos);
    /*final tags = rows
        .map((row) => row.readTableOrNull(db.tags))
        .where((tag) => tag != null)
        .toList();*/
    /*final List<Tag> tagRows = []; // 또는 List<TagsData>
    for (final r in rows) {
      final t = r.readTableOrNull(db.tags); // Tag? / TagsData?
      if (t != null) tagRows.add(t);        // 캐스팅 불필요
    }*/
    final tags = rows
        .map((row) => row.readTableOrNull(db.tags)) // Tag? 또는 TagsData?
        .whereType<Tag>() // 또는 .whereType<TagsData>()
        .toList(); // 여기서 캐스팅 불필요

    return MemoWithTagsDto(
      memo: MemoDto.fromEntity(memo),
      tags: tags.map(TagDto.fromEntity).toList(),  // 시그니처 맞춰서
    );
  }

  Future<int> insertMemo(String title) async {
    final companion = MemosCompanion.insert(title: title);

    return await db.into(db.memos).insert(companion);
  }

  Future<int> updateMemo(MemoDto dto) async {
    final companion = MemosCompanion(
      title: Value(dto.title),
      updatedAt: Value(DateTime.now()),
    );

    return await (db.update(db.memos)..where((t) => t.memoId.equals(dto.memoId)))
        .write(companion);
  }

  Future<int> deleteMemo(int memoId) async {
    return await (db.delete(db.memos)..where((tbl) => tbl.memoId.equals(memoId))).go();
  }

  // 🗑️ 휴지통 관련 메서드들
  
  /// 메모를 휴지통으로 이동 (소프트 삭제)
  Future<int> moveToTrash(int memoId) async {
    final companion = MemosCompanion(
      deletedAt: Value(DateTime.now()), // 🔥 isDeleted 제거, deletedAt만 설정
      updatedAt: Value(DateTime.now()),
    );

    return await (db.update(db.memos)..where((tbl) => tbl.memoId.equals(memoId)))
        .write(companion);
  }

  /// 휴지통에서 메모 복원
  Future<int> restoreFromTrash(int memoId) async {
    final companion = MemosCompanion(
      deletedAt: const Value(null), // 🔥 isDeleted 제거, deletedAt를 null로 설정
      updatedAt: Value(DateTime.now()),
    );

    return await (db.update(db.memos)..where((tbl) => tbl.memoId.equals(memoId)))
        .write(companion);
  }

  /// 휴지통 메모 목록 조회
  Future<List<MemoDto>> fetchTrashMemos({
    MemoCursor? memoCursor,
    required int limit,
  }) async {
    final query = db.select(db.memos)
      ..where((tbl) => tbl.deletedAt.isNotNull()) // 🔥 isDeleted → deletedAt로 변경
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.deletedAt, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.memoId, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    if (memoCursor != null) {
      query.where((tbl) =>
        tbl.deletedAt.isSmallerThanValue(memoCursor.createdAt) |
        (tbl.deletedAt.equals(memoCursor.createdAt) &
        tbl.memoId.isSmallerThanValue(memoCursor.id))
      );
    }

    final rows = await query.get();
    return rows.map(MemoDto.fromEntity).toList();
  }

  /// 휴지통 메모 영구 삭제
  Future<int> permanentlyDeleteMemo(int memoId) async {
    return await (db.delete(db.memos)
      ..where((tbl) => tbl.memoId.equals(memoId) & tbl.deletedAt.isNotNull()) // 🔥 isDeleted → deletedAt로 변경
    ).go();
  }

  /// 오래된 휴지통 메모 자동 정리 (예: 30일 이상)
  Future<int> cleanUpOldTrashMemos({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    return await (db.delete(db.memos)
      ..where((tbl) => 
        tbl.deletedAt.isNotNull() & // 🔥 isDeleted → deletedAt로 변경
        tbl.deletedAt.isSmallerThanValue(cutoffDate)
      )
    ).go();
  }

  /// 휴지통 메모 개수 조회
  Future<int> getTrashCount() async {
    final query = db.selectOnly(db.memos)
      ..addColumns([db.memos.memoId.count()])
      ..where(db.memos.deletedAt.isNotNull()); // 🔥 isDeleted → deletedAt로 변경

    final result = await query.getSingle();
    return result.read(db.memos.memoId.count()) ?? 0;
  }

  Future<void> incrementViewCount(int memoId) async {
    // 현재 viewCount 값을 먼저 조회
    final currentMemo = await (db.select(db.memos)
      ..where((tbl) => tbl.memoId.equals(memoId))
    ).getSingleOrNull();

    if (currentMemo != null) {
      await (db.update(db.memos)..where((tbl) => tbl.memoId.equals(memoId)))
          .write(MemosCompanion(
        viewCount: Value(currentMemo.viewCount + 1),
      ));
    }
  }
}
