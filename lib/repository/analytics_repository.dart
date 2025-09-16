import 'package:drift/drift.dart';
import 'package:remory/data/app_database.dart';

class AnalyticsRepository {
  final AppDatabase db;

  AnalyticsRepository(this.db);

  Future<int> totalMemos() async {
    final result = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM memos',
      readsFrom: {db.memos},
    ).getSingle();

    return (result.data['cnt'] as int?) ?? 0;  // null 안전 처리
  }

  Future<int> recent7Days() async {
    /*final result = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM memos WHERE created_at >= datetime(\'now\', \'-7 days\')',
      readsFrom: {db.memos},
    ).getSingle();

    return (result.data['cnt'] as int?) ?? 0;*/

    final row = await db.customSelect(
      "SELECT COUNT(*) AS cnt "
          "FROM memos "
          "WHERE created_at >= strftime('%s','now','-7 days')",
      readsFrom: {db.memos},
    ).getSingle();

    // drift 버전에 따라 둘 중 하나 사용
    // return row.read<int>('cnt');
    return (row.data['cnt'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>> recent30Days() async {
    /*final result = await db.customSelect(
      '''
      SELECT COUNT(*) AS cnt,
             COUNT(*) / 30.0 AS avg_per_day
      FROM memos
      WHERE created_at >= date(\'now\', \'-30 days\')
      ''',
      readsFrom: {db.memos},
    ).getSingle();

    return {
      'count': (result.data['cnt'] as int?) ?? 0,
      'avg': (result.data['avg_per_day'] as num?)?.toDouble() ?? 0.0,
    };*/

    final row = await db.customSelect(
      "SELECT COUNT(*) AS cnt "
          "FROM memos "
          "WHERE created_at >= strftime('%s','now','-30 days')",
      readsFrom: {db.memos},
    ).getSingle();

    return {
      // return row.read<int>('cnt');
      'count': (row.data['cnt'] as int?) ?? 0,
      // return row.read<double>('avg_per_day');
      'avg': (row.data['avg_per_day'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> topTags() async {
    final sinceSec = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;

    final rows = await db.customSelect(
      '''
    SELECT t.name AS name,
           COUNT(*) AS usage_count
    FROM memo_tags mt
    JOIN memos     m ON m.memo_id = mt.memo_id
    JOIN tags      t ON t.tag_id  = mt.tag_id
    WHERE m.created_at >= ?
    GROUP BY t.tag_id, t.name
    ORDER BY usage_count DESC, t.name ASC
    LIMIT 3
    ''',
      variables: [Variable<int>(sinceSec)],
      readsFrom: {db.memoTags, db.memos, db.tags},
    ).get();

    return rows.map((row) => {
      'name': row.data['name'] as String? ?? '',
      'count': (row.data['usage_count'] as int?) ?? 0,
    }).toList();
  }


  Future<List<Map<String, dynamic>>> topWeekdays() async {
    final sinceSec = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;

    final rows = await db.customSelect(
      '''
      SELECT strftime('%w', created_at, 'unixepoch', 'localtime') AS weekday,
             COUNT(*) AS cnt
      FROM memos
      WHERE created_at >= ?
      GROUP BY weekday
      ORDER BY cnt DESC, weekday ASC
      LIMIT 3
      ''',
      variables: [Variable<int>(sinceSec)],
      readsFrom: {db.memos},
    ).get();

    return rows.map((r) {
      final wd = int.tryParse(r.data['weekday'].toString()) ?? 0;
      final cnt = (r.data['cnt'] as int?) ?? 0;
      return {'weekday': wd, 'count': cnt};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> topHours() async {
    final sinceSec = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;

    final rows = await db.customSelect(
      '''
    SELECT strftime('%H', created_at, 'unixepoch', 'localtime') AS hour,
           COUNT(*) AS cnt
    FROM memos
    WHERE created_at >= ?
    GROUP BY hour
    ORDER BY cnt DESC, hour ASC
    LIMIT 3
    ''',
      variables: [Variable<int>(sinceSec)],
      readsFrom: {db.memos},
    ).get();

    return rows.map((r) => {
      'hour': int.tryParse(r.data['hour']?.toString() ?? '') ?? 0, // 00~23
      'count': (r.data['cnt'] as int?) ?? 0,
    }).toList();
  }

  Future<Map<String, int>> streaks() async {
    // created_at(epoch) → 로컬 날짜(YYYY-MM-DD)로 변환해 중복 제거, 최신→과거
    final rows = await db.customSelect(
      '''
    SELECT DISTINCT date(created_at, 'unixepoch', 'localtime') AS day
    FROM memos
    ORDER BY day DESC
    ''',
      readsFrom: {db.memos},
    ).get();

    final days = rows
        .map((r) => r.data['day']?.toString())
        .whereType<String>()
        .toList();

    if (days.isEmpty) return {'maxStreak': 0, 'currentStreak': 0};

    // 문자열 → DateTime (로컬), 정렬은 이미 DESC 보장
    final dates = days.map(DateTime.parse).toList();

    // 최대 연속(maxStreak): 전체 구간에서 가장 긴 연속
    int maxStreak = 1;
    int run = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        run++;
        if (run > maxStreak) maxStreak = run;
      } else {
        run = 1;
      }
    }

    // 현재 연속(currentStreak): "어제"를 포함하는 연속만 인정
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${two(yesterday.month)}-${two(yesterday.day)}';

    int currentStreak = 0;
    final startIdx = days.indexOf(yStr); // 어제가 존재해야 시작
    if (startIdx != -1) {
      currentStreak = 1; // 어제 1일
      for (int i = startIdx + 1; i < dates.length; i++) {
        if (dates[i - 1].difference(dates[i]).inDays == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    } else {
      currentStreak = 0; // 어제 작성 없으면 0일
    }

    return {'maxStreak': maxStreak, 'currentStreak': currentStreak};
  }
}