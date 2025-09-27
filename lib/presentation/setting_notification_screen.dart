import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/provider/notification_provider.dart';

class SettingNotificationScreen extends ConsumerWidget {
  const SettingNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationEnabledProvider);

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
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.notifications_active_outlined, color: Colors.blue.shade700),
            ),
            title: const Text('알림 받기'),
            subtitle: Text(
              enabled
                  ? '현재: 켜짐 · 기본 시간 오전 9시 · 밤 9시'
                  : '현재: 꺼짐 · 알림이 전송되지 않습니다',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            trailing: Switch(
              value: enabled,
              onChanged: (val) {
                ref.read(notificationEnabledProvider.notifier).setEnabled(context, val);
              },
            ),
          ),

          const SizedBox(height: 24),

          // 알림 안내 카드
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
                        '알림 정보',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 기본 알림은 매일 오전 9시, 밤 9시에 도착합니다\n'
                        '• 알림은 기기(현지) 시간대를 기준으로 전송돼요\n'
                        '• 스위치를 켜면 기본 스케줄이 등록되고, 끄면 모든 알림이 취소됩니다\n'
                        '• 기록을 놓치지 않도록 아침엔 시작 안내, 밤에는 하루 회고를 도와줘요',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 주의사항 카드
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '주의사항',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• iOS에서 알림 권한을 거부하면 설정에서 직접 허용해야 합니다\n'
                        '• 집중 모드/방해금지 모드에서는 배너가 보이지 않을 수 있어요\n'
                        '• 시뮬레이터에서는 배너 대신 알림 센터/잠금화면에서 확인되는 경우가 있습니다',
                    style: Theme.of(context).textTheme.bodyMedium,
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