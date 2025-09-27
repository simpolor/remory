import 'package:flutter/material.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingContactScreen extends StatelessWidget {
  const SettingContactScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@remoryapp.com',
      queryParameters: {
        'subject': 'Remory 앱 문의',
        'body': '문의 내용을 작성해주세요.'
      },
    );

    if (!await launchUrl(emailUri)) {
      // 앱에 메일 앱이 없거나 실패했을 때 처리
      throw Exception('메일 앱을 열 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppBarConfig(
        title: '문의하기',
        showBackButton: true,
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: _launchEmail,
          child: Text(
            '메일 보내기',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
