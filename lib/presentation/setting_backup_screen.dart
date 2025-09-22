import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/backup_provider.dart';

class SettingBackupScreen extends ConsumerWidget {
  const SettingBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createBackup = ref.watch(createBackupProvider);
    final restoreBackup = ref.watch(restoreBackupProvider);

    return AppScaffold(
      appBar: const AppBarConfig(
        title: '백업 / 복원',
        showBackButton: true,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 백업 생성
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.backup, color: Colors.green.shade600),
            ),
            title: const Text('백업 생성'),
            subtitle: const Text('모든 메모와 태그를 백업 파일로 저장'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final message = await createBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('백업 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const Divider(),

          // 백업 복원
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restore, color: Colors.orange.shade600),
            ),
            title: const Text('백업 복원'),
            subtitle: const Text('백업 파일에서 데이터 복원 (기존 데이터 삭제됨)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // 확인 다이얼로그
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('데이터 복원'),
                  content: const Text(
                    '백업 파일에서 데이터를 복원합니다.\n\n'
                    '⚠️ 현재 저장된 모든 메모와 태그가 삭제됩니다.\n\n'
                    '계속하시겠습니까?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('복원'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  final message = await restoreBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: message.contains('완료') 
                          ? Colors.green 
                          : Colors.grey,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('복원 실패: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),

          const SizedBox(height: 32),

          // 백업 설명
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '백업 정보',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 모든 메모와 태그가 JSON 파일로 백업됩니다\n'
                        '• 백업 파일은 다른 앱으로 공유하거나 클라우드에 저장할 수 있습니다\n'
                        '• 복원 시 기존 데이터는 모두 삭제됩니다',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 주의사항
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '주의사항',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 복원 작업은 되돌릴 수 없습니다\n'
                    '• 중요한 데이터는 복원 전 백업을 권장합니다\n'
                    '• 백업 파일은 안전한 곳에 보관하세요',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}