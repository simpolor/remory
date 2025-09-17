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

    final scrollController = useScrollController();

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          ref.read(tagPagedProvider.notifier).loadMore();
        }
      }
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    final tagPagedState = ref.watch(tagPagedProvider);

    Widget body;
    if (tagPagedState.tags.isEmpty) {
      body = tagPagedState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text('아직 태그가 없어요.'));
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(tagPagedProvider.notifier).refresh(),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Wrap(
            spacing: 6,    // 간격을 조금 늘림
            runSpacing: 8, // 줄 간격도 늘림
            crossAxisAlignment: WrapCrossAlignment.center, // 세로 중앙 정렬
            children: [
              for (final model in tagPagedState.tags)
                TagChip(
                  label: model.tag.name,
                  count: model.count, // 필요시
                  onTap: () => context.push('/tags/${model.tag.tagId}'),
                ),
              if (tagPagedState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: '태그',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '태그 검색',
            onPressed: () => context.push('/tags/search'),
          ),
        ],
      ),
      child: body,
    );
  }
}