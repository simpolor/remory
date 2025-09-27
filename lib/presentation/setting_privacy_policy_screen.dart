import 'package:flutter/material.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';

class SettingPrivacyPolicyScreen extends StatelessWidget {
  const SettingPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppBarConfig(
        title: '개인정보 처리방침',
        showBackButton: true,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remory 개인정보 처리방침',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '''
1. 수집하는 개인정보
- 이메일, 사용자명 등 계정 생성 시 필요한 정보
- 앱 사용 기록, 메모 작성 기록 등 서비스 제공을 위해 필요한 정보

2. 개인정보 이용 목적
- 서비스 제공 및 개선
- 사용자의 요청에 대한 처리
- 알림 및 공지 제공
- 법령 준수 및 분쟁 해결

3. 개인정보 보관 기간
- 계정 삭제 시 즉시 파기
- 법령에 따라 보관이 필요한 경우 해당 기간 동안 보관

4. 개인정보 제3자 제공
- 사용자의 동의 없이는 제공하지 않음
- 단, 법령에 의거 필요한 경우 예외

5. 개인정보 보호 조치
- SSL 암호화 전송
- 서버 접근 제한 및 보안 관리
- 주기적인 보안 점검

6. 사용자의 권리
- 언제든 개인정보 열람, 정정, 삭제 요청 가능
- 문의: support@remoryapp.com

7. 정책 변경
- 변경 시 앱 내 공지 또는 이메일 안내
''',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}