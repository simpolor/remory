import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/analytics_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/utils/DateUtils.dart';
import 'package:textfield_tags/textfield_tags.dart';

class MemoDetailScreen extends HookConsumerWidget {
  final int memoId;

  const MemoDetailScreen({super.key, required this.memoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final initialized = useState(false);
    final viewCountIncremented = useState(false);
    final textEditController = useTextEditingController();
    final tagController = useMemoized(() => StringTagController());

    final memoDetailAsync = ref.watch(memoDetailProvider(memoId));
    final memoWithTags = memoDetailAsync.asData?.value;

    useEffect(() {
      if (!initialized.value && memoWithTags != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!initialized.value) {
            textEditController.value = textEditController.value.copyWith(
              text: memoWithTags.memo.title,
              selection: TextSelection.collapsed(offset: memoWithTags.memo.title.length),
            );
            initialized.value = true;
          }
        });
      }
      return null;
    }, [memoDetailAsync]);

    useEffect(() {
      // 화면 진입 시 한 번만 viewCount 증가
      if (!viewCountIncremented.value && memoWithTags != null) {
        viewCountIncremented.value = true;
        Future.microtask(() {
          ref.read(incrementViewCountProvider)(memoId);
          // viewCount 증가 후 캐시 무효화해서 UI 갱신
          ref.invalidate(memoDetailProvider(memoId));
        });
      }
      return null;
    }, [memoId, memoWithTags?.memo.memoId]);

    useEffect(() {
      initialized.value = false;
      textEditController.clear();
      viewCountIncremented.value = false;
      return null;
    }, [memoId]);

    useEffect(() => tagController.dispose, []);

    final keywordState = useState(''); // 태그 입력용 keyword 상태 분리
    final suggestionsAsync = ref.watch(tagSuggestionsProvider(keywordState.value));

    Future<void> save() async {
      await ref.read(editMemoProvider)(memoId, textEditController.text.trim(), tagController.getTags ?? []);
      await ref.read(tagPagedProvider.notifier).reloadCurrent();

      ref.invalidate(memoDetailProvider(memoId));
      ref.invalidate(analyticsProvider);

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
        await ref.read(deleteMemoProvider)(memoId);
        await ref.read(tagPagedProvider.notifier).reloadCurrent();

        ref.read(memoPagedProvider.notifier).removeMemo(memoId);
        ref.invalidate(memoDetailProvider(memoId));
        ref.invalidate(analyticsProvider);

        // if (context.mounted) Navigator.pop(context);
        if (context.mounted) context.pop(memoId);
      }
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: '타임라인',
        showBackButton: true,
        actions: memoDetailAsync.maybeWhen(
          data: (memoWithTags) => [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: delete, // 삭제 버튼 클릭 시 deleteMemo 호출
            ),
          ],
          orElse: () => [],
        ),
      ),
      child: memoDetailAsync.when(
        data: (memoWithTags) {
          if (!initialized.value && memoWithTags != null) {
            return const Center(child: CircularProgressIndicator()); // 또는 스켈레톤
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '생성일: ${formatSimpleDateTime(memoWithTags?.memo.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '수정일: ${formatSimpleDateTime(memoWithTags?.memo.updatedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '조회수: ${memoWithTags?.memo.viewCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              TextFormField(
                autofocus: true,
                controller: textEditController,
                maxLines: null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: '내용 입력',
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
                validator: (v) {
                  final len = v?.trim().length ?? 0;
                  if (len > 255) return '메모는 최대 255자까지 입력할 수 있어요.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFieldTags<String>(
                textfieldTagsController: tagController,
                textSeparators: const [' ', ','],
                initialTags: memoWithTags?.tags.map((t) => t.name).toList(),
                validator: (value) {
                  final trimmed = value.trim() ?? '';
                  if (trimmed.length < 2) {
                    return '(최소 길이 오류) 태그는 2자 이상으로 입력해 주세요.';
                  }
                  if (trimmed.length > 15) {
                    return '(최대 길이 오류) 태그는 15자 이내로 입력해 주세요.';
                  }
                  // 태그 개수 제한 (현재 태그 + 추가하려는 태그 = 총 개수)
                  final currentTags = tagController.getTags ?? [];
                  if (currentTags.length >= 5) {
                    return '태그는 최대 5개까지 등록할 수 있어요.';
                  }
                  return null;
                },
                inputFieldBuilder: (context, inputFieldValues) {
                  final keyword = keywordState.value;
                  final showSuggestions = keyword.length >= 2;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: inputFieldValues.textEditingController,
                        focusNode: inputFieldValues.focusNode,
                        decoration: InputDecoration(
                          hintText: '태그 입력 (스페이스 또는 쉼표로 구분)',
                          border: const UnderlineInputBorder(),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        onChanged: (value) {
                          keywordState.value = value;
                          inputFieldValues.onTagChanged(value);
                        },
                        onSubmitted: (value) {
                          // 태그 개수 체크
                          if (inputFieldValues.tags.length >= 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('태그는 최대 5개까지 등록할 수 있어요.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          inputFieldValues.onTagSubmitted(value);
                        },
                      ),
                      if (inputFieldValues.error != null) // 에러 표시
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            inputFieldValues.error!,
                            style: Theme.of(context).inputDecorationTheme.errorStyle,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (showSuggestions) /// 추천 태그 리스트
                        suggestionsAsync.when(
                          loading: () => const Text('...'),
                          error: (e, _) => const Text('검색 실패'),
                          data: (tagList) {
                            if (tagList.isEmpty) return const SizedBox();
                            return Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tagList.map((tag) {
                                return GestureDetector(
                                  onTap: () {
                                    // 태그 개수 체크
                                    if (inputFieldValues.tags.length >= 5) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('태그는 최대 5개까지 등록할 수 있어요.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    inputFieldValues.textEditingController.clear();
                                    keywordState.value = '';
                                    inputFieldValues.onTagSubmitted(tag.name);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(color: Colors.grey, width: 1),
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                    child: Text(
                                      '#${tag.name}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      if (inputFieldValues.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: inputFieldValues.tags.map((tag) {
                            return Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                color: Colors.grey,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('#$tag', style: const TextStyle(color: Colors.white)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => inputFieldValues.onTagRemoved(tag),
                                    child: const Icon(Icons.cancel, size: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: save,
                  child: const Text('저장'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러 발생: $e')),
      ),
    );
  }
}