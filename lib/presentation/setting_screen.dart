import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppBarConfig(
        title: '설정',
        showBackButton: false,
        actions: [],
      ),
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('백업 및 복원'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/backup');
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('앱스토어에 리뷰 작성'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              const url = 'https://www.naver.com';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보 처리 방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/privacy_policy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('문의하기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@remoryapp.com',
                queryParameters: {
                  'subject': 'Remory 앱 문의',
                  'body': '문의 내용을 작성해주세요.'
                },
              );

              if (!await launchUrl(emailUri)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('메일 앱을 열 수 없습니다.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('버전'),
            trailing: const Text('1.0.0'),
            onTap: () {
              // 버전 정보 상세가 필요하면 이동
            },
          ),
        ],
      ),
    );
  }
}