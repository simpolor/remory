import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';

class SettingNotificationScreen extends ConsumerWidget {
  const SettingNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const AppBarConfig(
        title: '알림 설정',
        showBackButton: true,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 알림 ON/OFF
          ListTile(
            title: const Text('알림 ON/OFF'),
            trailing: Switch(
              value: true, // 나중에 provider 연결
              onChanged: (val) {}, // 나중에 로직 연결
            ),
          ),

          const SizedBox(height: 16),

          // 아침 알림
          ListTile(
            title: const Text('아침 알림'),
            subtitle: const Text('기본: 09:00'),
            trailing: Switch(
              value: true,
              onChanged: (val) {},
            ),
            onTap: () {
              // 나중에 시간 선택 다이얼로그 연결
            },
          ),

          const SizedBox(height: 16),

          // 저녁 알림
          ListTile(
            title: const Text('저녁 알림'),
            subtitle: const Text('기본: 21:00'),
            trailing: Switch(
              value: true,
              onChanged: (val) {},
            ),
            onTap: () {
              // 나중에 시간 선택 다이얼로그 연결
            },
          ),
        ],
      ),
    );
  }
}