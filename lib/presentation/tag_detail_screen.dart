import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/analytics_provider.dart';
import 'package:remory/provider/tag_provider.dart';

class TagDetailScreen extends HookConsumerWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final initialized = useRef(false);
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

    Future<void> save() async {
      await ref.read(editTagProvider)(tagId, textEditController.text.trim());
      await ref.read(tagPagedProvider.notifier).refresh();

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
        await ref.read(deleteTagProvider)(tagId);
        ref.read(tagPagedProvider.notifier).removeTag(tagId);

        ref.invalidate(analyticsProvider);

        if (context.mounted) Navigator.pop(context);
      }
    }

    return AppScaffold(
      appBar: AppBarConfig(
        title: '태그',
        showBackButton: true,
        actions: tagDetailAsync.maybeWhen(
          data: (memoDetail) => [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: delete,
            ),
          ],
          orElse: () => [],
        ),
      ),
      child: tagDetailAsync.when(
        data: (tagDetailData) {
          if (tagDetailData == null) {
            return const Center(child: Text('해당 태그를 찾을 수 없습니다.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: textEditController,
                    maxLines: null,
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