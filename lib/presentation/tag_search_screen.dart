import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';

class TagSearchScreen extends HookConsumerWidget {
  const TagSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();

    // 초기값 설정
    useEffect(() {
      controller.text = ref.read(tagSearchQueryProvider.notifier).state;
      return null;
    }, []);

    void runSearch() {
      final query = controller.text.trim();
      if (query.isNotEmpty) {
        ref.read(tagSearchQueryProvider.notifier).state = query;
        focusNode.unfocus();
        context.pop(); // 검색 후 태그 목록으로 돌아가기
      }
    }

    void clearSearch() {
      controller.clear();
      ref.read(tagSearchQueryProvider.notifier).state = '';
    }

    return AppScaffold(
      appBar: const AppBarConfig(
        title: '태그 검색',
        showBackButton: true,
        actions: [],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            // 선택
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '태그 검색...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: '검색어 지우기',
                    onPressed: clearSearch,
                  ),
                ],
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => runSearch(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: runSearch,
              child: const Text('검색'),
            ),
          ),
        ],
      ),
    );
  }
}
