import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/fab_config.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/provider/analytics_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/utils/DateUtils.dart';
import 'package:remory/core/error_context_collector.dart';
import 'package:remory/core/user_tracking_mixin.dart';

class MemoListScreen extends HookConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 화면 진입 추적
    useEffect(() {
      ErrorContextCollector.instance.trackScreenEntry('MemoList');
      return null;
    }, []);

    final now = DateTime.now();
    final searchTimer = useRef<Timer?>(null);

    final scrollController = useScrollController();
    final searchController = useTextEditingController();
    final searchQuery = ref.watch(memoSearchQueryProvider);

    // 검색어 동기화
    useEffect(() {
      if (searchController.text != searchQuery) {
        searchController.value = TextEditingValue(
          text: searchQuery,
          selection: TextSelection.collapsed(offset: searchQuery.length),
        );
      }
      return null;
    }, [searchQuery]);

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 200) {
          if (searchQuery.isEmpty) {
            ref.read(memoPagedProvider.notifier).loadMore();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, searchQuery]);

    final memoPagedState = ref.watch(memoPagedProvider);
    final deleteMemo = ref.watch(deleteMemoProvider);

    // 메모 그룹핑 (검색 중이 아닐 때만)
    final groupedMemos = <String, List<MemoModel>>{};
    if (searchQuery.isEmpty) {
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
    }

    final order = ['오늘', '어제', '이번 주', '이번 달', '이전'];
    final sortedGroups = [
      for (final key in order)
        if ((groupedMemos[key]?.isNotEmpty ?? false)) key,
    ];

    // 빈 상태 메시지 빌더
    Widget _emptyOrProgress() {
      if (memoPagedState.isLoading && memoPagedState.memos.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final text = searchQuery.isNotEmpty
          ? '"$searchQuery"에 대한 검색 결과가 없습니다.'
          : '아직 메모가 없어요.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text(text)),
      );
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: searchQuery.isNotEmpty ? '메모 검색' : '타임라인',
        showBackButton: false,
        actions: const [],
      ),
      fab: const FabConfig(
        icon: Icons.add,
        route: '/memos/add',
        tooltip: '추가',
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(memoPagedProvider.notifier).refresh(),
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 검색창 (항상 표시)
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '메모 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    ref.read(memoSearchQueryProvider.notifier).state = '';
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                // 🎯 검색 액션 추적
                ErrorContextCollector.instance.trackSearch(value, 'memo');
                
                searchTimer.value?.cancel();
                searchTimer.value = Timer(const Duration(milliseconds: 300), () {
                  ref.read(memoSearchQueryProvider.notifier).state = value;
                });
              },
            ),

            // 검색 상태 배지
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"$searchQuery" 검색 결과 ${memoPagedState.memos.length}개',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        searchController.clear();
                        ref.read(memoSearchQueryProvider.notifier).state = '';
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            color: Colors.blue.shade600, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 메모 목록 / 빈 상태 / 로딩
            if (memoPagedState.memos.isEmpty)
              _emptyOrProgress()
            else if (searchQuery.isNotEmpty)
              // 검색 모드: 플랫 리스트
              ...memoPagedState.memos.map((memo) {
                final memoId = memo.memoId;
                final memoDetailAsync = ref.watch(memoDetailProvider(memoId));

                return memoDetailAsync.when(
                  data: (memoWithTags) {
                    if (memoWithTags == null) return const SizedBox();
                    final cleanTitle = memoWithTags.memo.title
                        .replaceAll(RegExp(r'#\w+'), '')
                        .trim();

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
                        // 🎯 삭제 액션 추적
                        ErrorContextCollector.instance.trackItemAction('delete', 'memo', memo.memoId);
                        
                        await deleteMemo(memo.memoId);
                        await ref.read(tagPagedProvider.notifier).reloadCurrent();

                        ref.read(memoPagedProvider.notifier).removeMemo(memo.memoId);
                        ref.invalidate(analyticsProvider);
                      },
                      child: ListTile(
                        leading: Text(DateFormat('MM.dd').format(memo.createdAt)),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cleanTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontSize: 16),
                              ),
                            ),
                            if (memoWithTags.tags.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              const Text('🏷️', style: TextStyle(fontSize: 14)),
                            ],
                          ],
                        ),
                        onTap: () {
                          context.push('/memos/$memoId',
                              extra: {'showBackButton': true});
                        },
                      ),
                    );
                  },
                  loading: () => const ListTile(title: Text('Loading...')),
                  error: (err, _) => ListTile(title: Text('Error: $err')),
                );
              }).toList()
            else
              // 일반 모드: 그룹화된 리스트
              ...sortedGroups.map((groupKey) {
                final memos = groupedMemos[groupKey]!;
                if (memos.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupHeader(context, groupKey),
                    ...memos.map((memo) {
                      final memoId = memo.memoId;
                      final memoDetailAsync = ref.watch(memoDetailProvider(memoId));

                      return memoDetailAsync.when(
                        data: (memoWithTags) {
                          if (memoWithTags == null) return const SizedBox();
                          final cleanTitle = memoWithTags.memo.title
                              .replaceAll(RegExp(r'#\w+'), '')
                              .trim();

                          Widget? leadingWidget;
                          if (groupKey == '오늘' || groupKey == '어제') {
                            leadingWidget = Text(
                                DateFormat('HH:mm').format(memo.createdAt));
                          } else {
                            leadingWidget = Text(
                                DateFormat('MM.dd').format(memo.createdAt));
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
                              ref.read(memoPagedProvider.notifier).removeMemo(memo.memoId);
                            },
                            child: ListTile(
                              leading: leadingWidget,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cleanTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(fontSize: 16),
                                    ),
                                  ),
                                  if (memoWithTags.tags.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    const Text('🏷️',
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ],
                              ),
                              onTap: () {
                                context.push('/memos/$memoId',
                                    extra: {'showBackButton': true});
                              },
                            ),
                          );
                        },
                        loading: () => const ListTile(title: Text('Loading...')),
                        error: (err, _) => ListTile(title: Text('Error: $err')),
                      );
                    }),
                  ],
                );
              }).toList(),

            // 추가 로딩 인디케이터 (페이지네이션 중)
            if (memoPagedState.isLoading && memoPagedState.memos.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
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
