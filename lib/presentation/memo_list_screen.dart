import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/fab_config.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/utils/DateUtils.dart';

class MemoListScreen extends HookConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          ref.read(memoPagedProvider.notifier).loadMore();
        }
      });
      return null;
    }, [scrollController]);

    final memoPagedState = ref.watch(memoPagedProvider);
    final deleteMemo = ref.watch(deleteMemoProvider);

    final groupedMemos = <String, List<MemoModel>>{};
    for (final memo in memoPagedState.memos) {
      final date = memo.createdAt;
      String key;
      if (isToday(now, date)) {
        key = '오늘';
      } else if (isYesterday(now, date)) {
        key = '어제';
      } else if (isThisWeek(now, date)) {
        key = '이번 주';
      } else if (isThisMonth(now, date)) {
        key = '이번 달';
      } else {
        key = '이전';
      }
      groupedMemos.putIfAbsent(key, () => []).add(memo);
    }

    // 📌 그룹 순서
    final order = ['오늘', '어제', '이번 주', '이번 달', '이전'];
    // final sortedGroups = order.where((o) => groupedMemos.containsKey(o)).toList();
    final sortedGroups = [
      for (final key in order)
        if ((groupedMemos[key]?.isNotEmpty ?? false)) key,
    ];

    Widget body;
    if (memoPagedState.memos.isEmpty) {
      body = memoPagedState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text('아직 메모가 없어요.'));
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(memoPagedProvider.notifier).refresh(),
        child: ListView.builder(
          controller: scrollController,
          itemCount: sortedGroups.length,
          itemBuilder: (context, groupIndex) {
            final groupKey = sortedGroups[groupIndex];
            final memos = groupedMemos[groupKey]!;
            if (memos.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(context, groupKey), // 📌 그룹 헤더

                ...memos.map((memo) {
                  final memoId = memo.memoId;
                  final memoDetailAsync = ref.watch(memoDetailProvider(memoId));

                  return memoDetailAsync.when(
                    data: (memoWithTags) {
                      if (memoWithTags == null) return const SizedBox();
                      final cleanTitle =
                      memoWithTags.memo.title.replaceAll(RegExp(r'#\w+'), '').trim();

                      Widget? leadingWidget;
                      if (groupKey == '오늘' || groupKey == '어제') {
                        leadingWidget =
                            Text(DateFormat('HH:mm').format(memo.createdAt));
                      } else {
                        leadingWidget =
                            Text(DateFormat('MM.dd').format(memo.createdAt));
                      }

                      return Dismissible(
                        key: ValueKey<int>(memoId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await deleteMemo(memo.memoId);
                          await ref.read(tagPagedProvider.notifier).reloadCurrent();

                          // 삭제된 메모가 그룹에서 제거되도록 갱신
                          ref.read(memoPagedProvider.notifier).removeMemo(memo.memoId);
                        },
                        child: ListTile(
                          leading: leadingWidget,
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                    cleanTitle,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16), // ✅ Remory 스타일 적용
                                  )
                              ),
                              if (!memoWithTags.tags.isEmpty) ...[
                                const SizedBox(width: 4),
                                const Text('🏷️', style: TextStyle(fontSize: 14)),
                              ],
                            ],
                          ),
                          onTap: () {
                            context.push('/memos/$memoId', extra: {'showBackButton': true});
                            /*final res = await context.push('/memos/$memoId');
                            if (res is int) {
                              ref.read(memoPagedProvider.notifier).removeMemo(res);
                            }*/
                          },
                        ),
                      );
                    },
                    loading: () =>
                    const ListTile(title: Text('Loading...')),
                    error: (err, _) =>
                        ListTile(title: Text('Error: $err')),
                  );
                }),
              ],
            );
          }
        )
      );
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: '타임라인',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '검색',
            onPressed: () => context.push('/memos/search'),
          ),
        ],
      ),
      fab: const FabConfig(
        icon: Icons.add,
        route: '/memos/add',
        tooltip: '추가',
      ),
      child: body,
    );
  }

  Widget _buildGroupHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: Colors.grey,
              thickness: 1,
              endIndent: 8,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Expanded(
            child: Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 8,
            ),
          ),
        ],
      ),
    );
  }
}
