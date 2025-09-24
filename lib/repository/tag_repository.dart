import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:remory/data/app_database.dart';
import 'package:remory/provider/state/tag_cursor.dart';
import 'package:remory/repository/dtos/tag_dto.dart';
import 'package:remory/repository/dtos/tag_with_count_dto.dart';

class TagRepository {
  final AppDatabase db;

  TagRepository(this.db);

  Future<List<TagWithCountDto>> fetchTagsWithAfter({
    TagCursor? tagCursor,
    required int limit,
    String? searchQuery,
  }) async {
    final t = db.tags;
    final mt = db.memoTags;
    final m = db.memos;

    // 🗑️ 삭제되지 않은 메모만 카운트하는 서브쿼리 사용
    String sql = '''
      SELECT t.tag_id, t.name, t.usage_count, t.last_used_at, t.created_at, t.updated_at,
             COUNT(CASE WHEN m.deleted_at IS NULL THEN mt.memo_id END) as memo_count
      FROM tags t
      LEFT JOIN memo_tags mt ON t.tag_id = mt.tag_id
      LEFT JOIN memos m ON mt.memo_id = m.memo_id
    ''';
    
    List<Variable> args = [];
    
    // 검색 조건 추가
    if (searchQuery?.isNotEmpty == true) {
      sql += ' WHERE t.name COLLATE NOCASE LIKE ?';
      args.add(Variable.withString('$searchQuery%'));
    }
    
    sql += ' GROUP BY t.tag_id';
    
    // 커서 조건
    if (tagCursor != null) {
      final whereClause = searchQuery?.isNotEmpty == true ? ' AND' : ' WHERE';
      sql += '$whereClause (t.name > ? OR (t.name = ? AND t.tag_id > ?))';
      args.addAll([
        Variable.withString(tagCursor.lastName),
        Variable.withString(tagCursor.lastName),
        Variable.withInt(tagCursor.lastTagId),
      ]);
    }
    
    sql += ' ORDER BY t.name ASC, t.tag_id ASC LIMIT ?';
    args.add(Variable.withInt(limit));

    final result = await db.customSelect(sql, variables: args).get();

    return result.map((row) {
      final tag = TagDto(
        tagId: row.read<int>('tag_id'),
        name: row.read<String>('name'),
        usageCount: row.read<int>('usage_count'),
        lastUsedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('last_used_at')),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
      );
      final count = row.read<int>('memo_count');
      
      return TagWithCountDto(
        tag: tag,
        count: count,
      );
    }).toList();
  }

  Future<TagDto?> findTagById(int id) async {
    final tag = await (
        db.select(db.tags)..where((tbl) => tbl.tagId.equals(id))
    ).getSingleOrNull();

    if (tag == null) return null;

    return TagDto.fromEntity(tag);
  }

  Future<TagDto?> findTagByName(String name) async {
    final tag = await (
        db.select(db.tags)..where((t) => t.name.equals(name))
          ..limit(1)
    ).getSingleOrNull();

    if (tag == null) return null;

    return TagDto.fromEntity(tag);
  }

  Future<List<TagDto>> findTagsByNames(List<String> names) async {
    final tags = db.select(db.tags)
      ..where((t) => t.name.isIn(names));

    return tags.map((tag) => TagDto.fromEntity(tag)).get();
  }

  /*Future<List<TagDto>> searchTagsByName(String keyword) async {
    if (keyword.length < 2) return Future.value([]);

    final tags = await (db.select(db.tags)
      ..where((t) => t.name.like('%$keyword%'))
      ..orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc)]))
        .get();

    return tags.map(TagDto.fromEntity).toList();
  }*/

  Future<List<TagDto>> searchTagsByName(String keyword) async {
    if (keyword.trim().length < 2) return [];

    final t = db.tags;
    final pattern = '%$keyword%';

    final rows = await (db.select(t)
    // ✅ 테이블 별칭을 받는 빌더로 작성
      ..where((tbl) => tbl.name
          .collate(const Collate('NOCASE'))  // 대소문자 구분 없이
          .like(pattern))                     // Variable(pattern)도 가능
      ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.usageCount, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.name,       mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.tagId,      mode: OrderingMode.asc),
      ])
      ..limit(3))
        .get();

    return rows.map(TagDto.fromEntity).toList();
  }

  Future<List<TagDto>> getOrCreateTagsByNames(List<String> names) async {
    /*final companions = names.map((name) {
      return TagsCompanion(
        name: Value(name),
      );
    }).toList();

    await db.batch((batch) {
      batch.insertAll(db.tags, companions, mode: InsertMode.insertOrIgnore,);
    });

    return findTagsByNames(names);*/

    // 1) 입력 정규화: 공백 제거 + 빈값 제거 + 중복 제거(입력 순서 유지)
    final inputNamesNormalized = LinkedHashSet<String>.from(
      names.map((s) => s.trim()),
    ).where((s) => s.isNotEmpty).toList();

    if (inputNamesNormalized.isEmpty) return [];

    // 2) 배치 삽입 (충돌은 무시)
    await db.batch((batch) {
      batch.insertAll(
        db.tags,
        [
          for (final n in inputNamesNormalized)
          // ← insert 생성자를 쓰면 required 필드가 명시적으로 필요해짐
            TagsCompanion.insert(
              name: n,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });

    // 3) DB에서 조회 후, 소문자 키 기반 매핑 생성 (NOCASE 대비 안전)

    final tagsFetchedByNames = await findTagsByNames(inputNamesNormalized);
    final Map<String, TagDto> tagsByLowerName = {
      for (final tag in tagsFetchedByNames) tag.name.toLowerCase(): tag,
    };

    // 4) 입력 순서대로 재정렬하여 반환
    final List<TagDto> tagsInInputOrder = [
      for (final name in inputNamesNormalized)
        if (tagsByLowerName.containsKey(name.toLowerCase()))
          tagsByLowerName[name.toLowerCase()]!,
    ];

    return tagsInInputOrder;
  }

  Future<int> updateTag(TagDto dto) async {
    final companion = TagsCompanion(
      name: Value(dto.name),
      updatedAt: Value(DateTime.now()),
    );

    return await (db.update(db.tags)..where((t) => t.tagId.equals(dto.tagId)))
        .write(companion);
  }

  Future<void> deleteTag(int id) =>
      (db.delete(db.tags)..where((tbl) => tbl.tagId.equals(id))).go();
}