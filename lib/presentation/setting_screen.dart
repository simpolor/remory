import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/debug_screen.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/core/performance_monitor.dart';
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
          // 🗑️ 휴지통 메뉴 추가
          Consumer(
            builder: (context, ref, child) {
              final trashCountAsync = ref.watch(trashCountProvider);
              
              return ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('휴지통'),
                subtitle: const Text('삭제된 메모 관리'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 휴지통에 메모가 있을 때 배지 표시
                    trashCountAsync.when(
                      data: (count) => count > 0 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  context.push('/trash');
                },
              );
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
          
          // 개발 모드에서만 디버그 메뉴 표시
          if (kDebugMode) ...[
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '🔧 개발자 도구',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('에러 로그'),
              subtitle: const Text('앱 에러 및 로그 확인'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed, color: Colors.blue),
              title: const Text('성능 모니터'),
              subtitle: const Text('앱 성능 통계 확인'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPerformanceReport(context);
              },
            ),
          ],
          
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

  void _showPerformanceReport(BuildContext context) {
    final report = PerformanceMonitor().generateReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성능 리포트'),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              PerformanceMonitor().clearStatistics();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('성능 통계가 초기화되었습니다')),
              );
            },
            child: const Text('초기화'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}