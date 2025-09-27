import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/core/error_context_collector.dart';
import 'package:remory/provider/tag_provider.dart';

class TrashScreen extends HookConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      ErrorContextCollector.instance.setCurrentScreen('Trash');
      return null;
    }, []);

    final trashMemosAsync = ref.watch(trashMemosProvider(100));
    final restoreMemo = ref.watch(restoreMemoProvider);
    final permanentlyDeleteMemo = ref.watch(permanentlyDeleteMemoProvider);
    final cleanUpTrash = ref.watch(cleanUpTrashProvider);

    return AppScaffold(
      appBar: AppBarConfig(
        title: '휴지통',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'cleanup_30':
                  await _showCleanupDialog(context, ref, cleanUpTrash, 30);
                  break;
                case 'cleanup_7':
                  await _showCleanupDialog(context, ref, cleanUpTrash, 7);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cleanup_30',
                child: Text(
                  '30일 이상 된 메모 정리',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              PopupMenuItem(
                value: 'cleanup_7',
                child: Text(
                  '7일 이상 된 메모 정리',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trashMemosProvider);
          ref.invalidate(trashCountProvider);
        },
        child: trashMemosAsync.when(
          data: (memos) {
            if (memos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('휴지통이 비어있습니다', 
                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '휴지통 메모 ${memos.length}개 • 30일 후 자동 삭제',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: memos.length,
                    itemBuilder: (context, index) {
                      final memo = memos[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: Text(
                            memo.title, 
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            '삭제일: ${DateFormat('MM.dd HH:mm').format(memo.updatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'restore') {
                                await _restoreMemo(context, ref, memo.memoId, restoreMemo);
                              } else if (value == 'delete') {
                                await _permanentlyDelete(context, ref, memo.memoId, permanentlyDeleteMemo);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'restore', 
                                child: Text(
                                  '복원',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete', 
                                child: Text(
                                  '영구삭제',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              '오류 발생: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreMemo(BuildContext context, WidgetRef ref, int memoId, Function restoreMemo) async {
    await restoreMemo(memoId);
    ref.invalidate(trashMemosProvider);
    ref.invalidate(memoPagedProvider);
    ref.read(tagPagedProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모를 복원했어요.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _permanentlyDelete(BuildContext context, WidgetRef ref, int memoId, Function deleteFunc) async {
    await deleteFunc(memoId);
    ref.invalidate(trashMemosProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모를 영구 삭제했어요.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCleanupDialog(BuildContext context, WidgetRef ref, Function cleanUpTrash, int days) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '휴지통 정리',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          '$days일 이상 지난 메모를 영구 삭제합니다.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), 
            child: Text(
              '취소',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), 
            child: Text(
              '정리',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedCount = await cleanUpTrash(daysOld: days);
      ref.invalidate(trashMemosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 $deletedCount개를 정리했어요.')),
        );
      }
    }
  }
}
