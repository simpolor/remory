import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remory/service/notification_service.dart';

class NotificationToggle extends StateNotifier<bool> {
  final Ref ref;
  NotificationToggle(this.ref) : super(false); // 초기값: OFF (원하면 저장소 연동)

  Future<void> setEnabled(BuildContext context, bool enable) async {

    if (enable) {
      // A) 현재 권한 상태 확인
      // B) 아직 요청 전/거부면 정식 요청 (iOS/Android 모두 처리되도록)
      final ok = await NotificationService.I.requestPermission();

      // 권한 요청 후 더 긴 대기시간 (권한 상태 동기화 대기)
      await Future.delayed(const Duration(seconds: 1));

      // flutter_local_notifications에서 ok가 false인 경우에만 에러 처리
      if (!ok) {
        if (!context.mounted) return;

        // C) 여전히 거부 → 설정 유도 다이얼로그
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('알림 권한이 필요합니다'),
            content: const Text('설정에서 Remory 알림을 허용해주세요.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('설정 열기')),
            ],
          ),
        );
        if (go == true) {
          await openAppSettings();
        }
        // 권한이 없으면 켜짐 유지 금지
        state = false;
        return;
      }

      // D) 권한 확인 후 추가 딜레이
      await Future.delayed(const Duration(milliseconds: 500));

      // E) 여기 도달 = 권한 OK → 즉시 알림 테스트
      try {
        await NotificationService.I.scheduleDaily(
          id: 900, title: '오늘의 Remory ✍️', body: '아침 5분, 기록으로 하루를 시작해요.', hour: 9, minute: 0,
        );
        await NotificationService.I.scheduleDaily(
          id: 2100, title: '하루 마무리 ✨', body: '잠들기 전 오늘을 간단히 돌아봐요.', hour: 21, minute: 0,
        );

        /*
        print('⏰ 5초 후 알림 예약 시작');
        await NotificationService.I.showDelayedTest();
        */

        final pending = await NotificationService.I.pending();
        debugPrint('📋 최종 pending 알림 수: ${pending.length}');

        state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림이 켜졌습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 설정 중 오류가 발생했습니다: $e')),
        );
      }
    } else {
      // OFF → 모든 예약/표시 취소
      await NotificationService.I.cancelAll();
      await NotificationService.I.cancel(900);
      await NotificationService.I.cancel(2100);
      state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림이 꺼졌습니다.')),
      );
    }
  }
}