import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/analytics_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:textfield_tags/textfield_tags.dart';

class MemoAddScreen extends HookConsumerWidget {
  const MemoAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final textEditController = useTextEditingController();

    final tagController = useMemoized(() => StringTagController());
    useEffect(() => tagController.dispose, []);

    final keywordState = useState(''); //=태그 입력용 keyword 상태 분리
    final suggestionsAsync = ref.watch(tagSuggestionsProvider(keywordState.value));

    final prevTagsLength = useRef(0); // 이전 태그 개수를 추적하여 태그 추가/삭제 감지

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;

      final text = textEditController.text.trim();
      final tags = tagController.getTags ?? [];

      await ref.read(addMemoProvider)(text, tags);
      await ref.read(memoPagedProvider.notifier).refreshHead();
      await ref.read(tagPagedProvider.notifier).reloadCurrent();
      ref.invalidate(analyticsProvider);

      if (!context.mounted) return;
      Navigator.pop(context);
    }

    return AppScaffold(
      appBar: const AppBarConfig(
        title: '타임라인',
        showBackButton: true,
        actions: [],
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemoBodyField(controller: textEditController),
              const SizedBox(height: 16),
              TextFieldTags<String>(
                key: const ValueKey('textfield_tags'),
                textfieldTagsController: tagController,
                textSeparators: const [' ', ','],
                validator: (value) {
                  final trimmed = value.trim() ?? '';
                  if (trimmed.length < 2) {
                    return '태그는 2자 이상으로 입력해 주세요.';
                  }
                  if (trimmed.length > 15) {
                    return '태그는 15자 이내로 입력해 주세요.';
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

                  // 태그 개수 변경 감지하여 키워드 초기화
                  final currentTagsLength = inputFieldValues.tags.length;
                  if (prevTagsLength.value != currentTagsLength) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      keywordState.value = '';
                    });
                    prevTagsLength.value = currentTagsLength;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: inputFieldValues.textEditingController,
                        focusNode: inputFieldValues.focusNode,
                        style: Theme.of(context).textTheme.bodyMedium, // 태그 입력은 14px 유지
                        decoration: InputDecoration(
                          hintText: '태그 입력 (스페이스 또는 쉼표로 구분)',
                          border: const UnderlineInputBorder(),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          /*helperText: '${inputFieldValues.tags.length}/5 (최대 5개)',
                          helperStyle: TextStyle(
                            color: inputFieldValues.tags.length >= 5 ? Colors.red : Colors.grey,
                          ),*/
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
                          keywordState.value = '';  // 엔터 시 키워드 초기화
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
                      if (inputFieldValues.tags.isNotEmpty) /// 등록된 태그 리스트
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: inputFieldValues.tags.map((tag) {
                            return Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                color: Colors.grey,
                              ),
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
            ]
          ),
        ),
      ),
    );
  }
}

class _MemoBodyField extends HookWidget {
  const _MemoBodyField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: true,
      controller: controller,
      maxLines: null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.bodyLarge, // titleMedium에서 bodyLarge로 변경
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
    );
  }
}


