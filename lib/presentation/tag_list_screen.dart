import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/widgets/tag_chip_widget.dart';

class TagListScreen extends HookConsumerWidget {
  const TagListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTimer = useRef<Timer?>(null);

    final scrollController = useScrollController();
    final searchController = useTextEditingController();

    // 상태 구독
    final tagPagedState = ref.watch(tagPagedProvider);
    final searchQuery = ref.watch(tagSearchQueryProvider);
    final isSearchVisible = useState(false); // 검색창 표시 상태

    // 검색어 ↔ 컨트롤러 동기화 + 커서 끝 유지
    useEffect(() {
      if (searchController.text != searchQuery) {
        searchController.value = TextEditingValue(
          text: searchQuery,
          selection: TextSelection.collapsed(offset: searchQuery.length),
        );
      }
      return null;
    }, [searchQuery]);

    // 검색창이 닫힐 때 검색어 초기화
    useEffect(() {
      if (!isSearchVisible.value && searchQuery.isNotEmpty) {
        searchController.clear();
        ref.read(tagSearchQueryProvider.notifier).state = '';
      }
      return null;
    }, [isSearchVisible.value]);

    // 무한 스크롤 (검색 중이 아닐 때만, isLoading/hasMore 가드)
    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 200) {
          if (searchQuery.isEmpty &&
              !tagPagedState.isLoading &&
              tagPagedState.hasMore) {
            ref.read(tagPagedProvider.notifier).loadMore();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, searchQuery, tagPagedState.isLoading, tagPagedState.hasMore]);

    // 메시지 빌더
    Widget _emptyOrProgress() {
      if (tagPagedState.isLoading && tagPagedState.tags.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final text = searchQuery.isNotEmpty
          ? '"$searchQuery"에 대한 검색 결과가 없습니다.'
          : '아직 태그가 없어요.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: searchQuery.isNotEmpty ? '태그 검색' : '태그',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(isSearchVisible.value ? Icons.search_off : Icons.search),
            onPressed: () {
              isSearchVisible.value = !isSearchVisible.value;
              if (!isSearchVisible.value && searchQuery.isNotEmpty) {
                searchController.clear();
                ref.read(tagSearchQueryProvider.notifier).state = '';
              }
            },
            tooltip: isSearchVisible.value ? '검색 닫기' : '검색',
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(tagPagedProvider.notifier).refresh(),
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // 검색창 (토글 가능)
            if (isSearchVisible.value) ...[
              TextField(
                controller: searchController,
                autofocus: true, // 검색창이 열릴 때 자동 포커스
                decoration: InputDecoration(
                  hintText: '검색어 입력',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      ref.read(tagSearchQueryProvider.notifier).state = '';
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
                  searchTimer.value?.cancel();
                  searchTimer.value = Timer(const Duration(milliseconds: 300), () {
                    ref.read(tagSearchQueryProvider.notifier).state = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],

            // 검색 상태 배지
            if (searchQuery.isNotEmpty && isSearchVisible.value) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        '"$searchQuery" 검색 결과 ${tagPagedState.tags.length}개',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 태그 목록 / 비어있음 / 로딩
            if (tagPagedState.tags.isEmpty)
              _emptyOrProgress()
            else
              Wrap(
                spacing: 6,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final model in tagPagedState.tags)
                    TagChip(
                      key: ValueKey(model.tag.tagId),
                      label: model.tag.name,
                      count: model.count, // 검색 시 count 숨김
                      onTap: () => context.push('/tags/${model.tag.tagId}'),
                    ),
                ],
              ),

            // 추가 로딩 인디케이터 (페이지네이션 중)
            if (tagPagedState.isLoading && tagPagedState.tags.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}