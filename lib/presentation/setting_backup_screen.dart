import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';

class SettingBackupScreen extends ConsumerWidget {
  const SettingBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const AppBarConfig(
        title: '백업 / 복원',
        showBackButton: true,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 내보내기
          ListTile(
            title: const Text('데이터 내보내기'),
            subtitle: const Text('메모 데이터를 JSON 파일로 저장'),
            trailing: const Icon(Icons.file_upload),
            onTap: () {
              // 나중에 내보내기 로직 연결
            },
          ),

          const SizedBox(height: 16),

          // 불러오기
          ListTile(
            title: const Text('데이터 불러오기'),
            subtitle: const Text('JSON 파일에서 메모 데이터를 복원'),
            trailing: const Icon(Icons.file_download),
            onTap: () {
              // 나중에 불러오기 로직 연결
            },
          ),
        ],
      ),
    );
  }
}