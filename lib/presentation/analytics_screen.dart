import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return AppScaffold(
      appBar: const AppBarConfig(title: '통계', showBackButton: false, actions: []),
      child: analyticsAsync.when(
        data: (dto) {
          final tiles = <Widget>[
            // 요약(묶음)
            ..._buildStatSection(context, title: '요약', items: [
              _StatRow('총 메모 수', '${dto.totalMemos}'),
              _StatRow('최근 7일 작성 수', '${dto.recent7DaysCount}'),
              _StatRow('최근 30일', '${dto.recent30DaysCount}'),
            ]),

            // 연속 기록(묶음)
            ..._buildStatSection(context, title: '연속 기록', items: [
              _StatRow('최대 연속', '${dto.streaks.maxStreak}일'),
              _StatRow('현재 연속', '${dto.streaks.currentStreak}일'),
            ]),

            // Top 그룹(최근 30일) — 헤더 한 번 + 소제목 3개
            ..._buildRankGroupSection(
              context,
              title: 'Top',
              suffix: _rangeLabel30(),
              groups: [
                _RankGroup(
                  '태그',
                  dto.topTags
                      .map((e) => _RankRow(label: e.name, value: e.count))
                      .toList(),
                ),
                _RankGroup(
                  '요일',
                  dto.topWeekdays
                      .map((e) => _RankRow(label: _weekdayName(e.weekday), value: e.count))
                      .toList(),
                ),
                _RankGroup(
                  '시간대',
                  dto.topHours
                      .map((e) => _RankRow(label: '${e.hour}:00', value: e.count))
                      .toList(),
                ),
              ],
            ),
          ];

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemBuilder: (_, i) => tiles[i],
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemCount: tiles.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러 발생: $e')),
      ),
    );
  }

  // ---------- Helpers (섹션/그룹 공통) ----------

  static List<Widget> _buildStatSection(
      BuildContext context, {
        required String title,
        List<_StatRow> items = const [],
        String? suffix,
      }) {
    return [
      _sectionHeader(context, title, suffix: suffix),
      ...items.map((e) => _statTile(context, e.label, e.value)),
      const Divider(height: 24),
    ];
  }

  static List<Widget> _buildRankGroupSection(
      BuildContext context, {
        required String title,
        required List<_RankGroup> groups,
        String? suffix,
      }) {
    final widgets = <Widget>[
      _sectionHeader(context, title, suffix: suffix),
    ];

    for (final g in groups) {
      widgets.add(_subHeader(context, g.title));      // 소제목(태그/요일/시간대)
      widgets.addAll(_rankTiles(context, g.rows));     // 각 랭킹 타일들
      widgets.add(const SizedBox(height: 8));
    }

    widgets.add(const Divider(height: 24));
    return widgets;
  }

  static Widget _sectionHeader(BuildContext context, String title, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), // 22px로 변경
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Text(
              suffix,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), // 12px로 변경
            ),
          ],
        ],
      ),
    );
  }

  static Widget _subHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  static Widget _statTile(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
    );
  }

  static List<Widget> _rankTiles(BuildContext context, List<_RankRow> rows) {
    return List<Widget>.generate(rows.length, (i) {
      final r = rows[i];
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: _rankBadge(context, i + 1),
        title: Text(r.label, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text('${r.value}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      );
    });
  }

  static Widget _rankBadge(BuildContext context, int rank) {
    final txt = Text(
      '$rank',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    if (rank <= 3) return CircleAvatar(radius: 12, child: txt);
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: txt,
    );
  }

  static String _weekdayName(int weekday) {
    const names = ['일', '월', '화', '수', '목', '금', '토'];
    if (weekday < 0 || weekday > 6) return '알수없음';
    return names[weekday];
  }

  static String _rangeLabel30() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    String f(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '최근 30일 (${f(from)}–${f(now)})';
  }
}

// 내부 표현용 DTO들
class _RankRow {
  final String label;
  final int value;
  const _RankRow({required this.label, required this.value});
}

class _StatRow {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
}

class _RankGroup {
  final String title;            // 소제목("태그", "요일", "시간대")
  final List<_RankRow> rows;     // 해당 랭킹 데이터
  const _RankGroup(this.title, this.rows);
}