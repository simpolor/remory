import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/memo_detail_screen.dart';
import 'package:remory/provider/analytics_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';

class TagDetailScreen extends HookConsumerWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final initialized = useState(false);
    final textEditController = useTextEditingController();

    final tagDetailAsync = ref.watch(tagDetailProvider(tagId));
    final tag = tagDetailAsync.asData?.value;

    useEffect(() {
      if (!initialized.value && tag != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!initialized.value) {
            textEditController.value = textEditController.value.copyWith(
              text: tag.name,
              selection: TextSelection.collapsed(offset: tag.name.length),
            );
            initialized.value = true;
          }
        });
      }
      return null;
    }, [tagDetailAsync]);

    useEffect(() {
      initialized.value = false;
      textEditController.clear();
      return null;
    }, [tagId]);

    useEffect(() {
      // 화면 복귀 시 첫 페이지 새로고침
      Future.microtask(() {
        ref.read(tagMemoPagedProvider(tagId).notifier).refresh();
      });
      return null;
    });

    Future<void> save() async {
      final tagMemoPagedState = ref.read(tagMemoPagedProvider(tagId));
      final affectedMemoIds = tagMemoPagedState.memos.map((memo) => memo.memoId).toList();

      await ref.read(editTagProvider)(tagId, textEditController.text.trim());
      await ref.read(tagPagedProvider.notifier).refresh();

      ref.invalidate(tagDetailProvider(tagId));
      ref.invalidate(analyticsProvider);

      for (final memoId in affectedMemoIds) {
        ref.invalidate(memoDetailProvider(memoId));
      }

      if (context.mounted) Navigator.pop(context);
    }

    Future<void> delete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('이 메모를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final tagMemoPagedState = ref.read(tagMemoPagedProvider(tagId));
        final affectedMemoIds = tagMemoPagedState.memos.map((memo) => memo.memoId).toList();

        await ref.read(deleteTagProvider)(tagId);
        ref.read(tagPagedProvider.notifier).removeTag(tagId);

        ref.invalidate(analyticsProvider);
        for (final memoId in affectedMemoIds) {
          ref.invalidate(memoDetailProvider(memoId));
        }

        if (context.mounted) Navigator.pop(context);
      }
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: '태그',
        showBackButton: true,
        actions: tagDetailAsync.maybeWhen(
          data: (tag) => [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: delete,
            ),
          ],
          orElse: () => [],
        ),
      ),
      child: tagDetailAsync.when(
        data: (tag) {
          if (!initialized.value && tag != null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: textEditController,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyLarge, // titleMedium에서 bodyLarge로 변경
                    decoration: const InputDecoration(
                      hintText: '태그 내용을 입력하세요...',
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return '태그명을 입력해주세요.';
                      }
                      if (trimmed.length < 2) {
                        return '태그명은 2글자 이상 입력해주세요.';
                      }
                      if (trimmed.length > 15) {
                        return '태그명은 15글자 이하로 입력해주세요.';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: save,
                      child: const Text('저장'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.bookmark, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '이 태그를 사용하는 메모',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final tagMemoPagedState = ref.watch(tagMemoPagedProvider(tagId));

                        if (tagMemoPagedState.memos.isEmpty && tagMemoPagedState.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (tagMemoPagedState.memos.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_alt_outlined,
                                    size: 48,
                                    color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  '이 태그를 사용하는 메모가 없습니다.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(tagMemoPagedProvider(tagId).notifier).refresh();
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: tagMemoPagedState.memos.length + (tagMemoPagedState.hasMore ? 1 : 0), // +1 for header
                            itemBuilder: (context, index) {
                              // 로딩 인디케이터
                              if (index >= tagMemoPagedState.memos.length) {
                                // 페이지 로딩 트리거
                                Future.microtask(() {
                                  if (tagMemoPagedState.hasMore && !tagMemoPagedState.isLoading) {
                                    ref.read(tagMemoPagedProvider(tagId).notifier).loadMore();
                                  }
                                });

                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              // 메모 아이템
                              final memo = tagMemoPagedState.memos[index];
                              final memoDetailAsync = ref.watch(memoDetailProvider(memo.memoId));

                              return memoDetailAsync.when(
                                data: (memoWithTags) {
                                  if (memoWithTags == null) return const SizedBox();
                                  final cleanTitle = memoWithTags.memo.title
                                      .replaceAll(RegExp(r'#\w+'), '')
                                      .trim();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      leading: Text(
                                        '${memo.createdAt.month.toString().padLeft(2, '0')}.${memo.createdAt.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
                                        ],
                                      ),
                                      onTap: () {
                                        context.push('/memos/${memo.memoId}',
                                            extra: {'showBackButton': true});
                                      },
                                    ),
                                  );
                                },
                                loading: () => const ListTile(
                                  leading: SizedBox(width: 40),
                                  title: Text('Loading...'),
                                ),
                                error: (err, _) => ListTile(
                                  leading: const Icon(Icons.error, color: Colors.red),
                                  title: Text('Error: $err'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러 발생: $e')),
      ),
    );
  }
}