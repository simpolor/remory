import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata; // initializeTimeZones()
import 'package:timezone/timezone.dart' as tz;        // TZDateTime, setLocalLocation, local
import 'package:flutter_timezone/flutter_timezone.dart' as fzt;

class NotificationService {

  /*
  “인스턴스 하나만 쓴다”를 컴파일 타임에 보장하고,
  어디서나 NotificationService.I로 접근하게 하는 간단·안전한 싱글턴이야.
   */
  NotificationService._internal(); // 1) 프라이빗(named) 생성자
  static final NotificationService I = NotificationService._internal(); // 2) 전역 단일 인스턴스

  final _plugin = FlutterLocalNotificationsPlugin();

  /// iOS/Android 공통 채널/카테고리 정의(필요 시 확장)
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,   // 포그라운드에서도 배너
    presentBadge: true,
    presentSound: true,
  );

  static const _androidDetails = AndroidNotificationDetails(
    'remory_default',         // 채널 ID
    'Remory Notifications',   // 채널 이름
    channelDescription: 'Remory local notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const _details = NotificationDetails(
    iOS: _iosDetails,
    android: _androidDetails,
  );

  Future<void> init() async {
    // 1) 타임존 초기화 (반복/예약 정확도 ↑)
    tzdata.initializeTimeZones();
    try {
      final name = await fzt.FlutterTimezone.getLocalTimezone(); // e.g. "Asia/Seoul"
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // 실패 UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final now = tz.TZDateTime.now(tz.local);
    print('tz.local.name = ${now.location.name}');     // 예: Asia/Seoul 또는 UTC
    print('timeZoneName  = ${now.timeZoneName}');      // 예: KST / UTC
    print('offset        = ${now.timeZoneOffset}');    // 예: 9:00:00 / 0:00:00

    // 2) 플랫폼별 초기화
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,   // 초기화 시 권한 요청
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,      // 포그라운드에서 알림 표시
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      iOS: iosInit,
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 탭 시 처리 (필요시 구현)
        print('알림 응답: ${response.payload}');
      },
    );

    // iOS에서 포그라운드 표시 옵션은 위의 DarwinNotificationDetails로 충분
  }

  /// iOS 권한 요청 (사용자 트리거 타이밍에 호출)
  Future<bool> requestPermission() async {
    bool result = true;
    
    // iOS 권한
    if (Platform.isIOS) {
      final ios = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final okIOS = await ios?.requestPermissions(
        alert: true, 
        badge: true, 
        sound: true,
        critical: false,  // 중요 알림 (선택사항)
      );
      result = result && (okIOS ?? true);
    }

    // Android 13+ 권한
    if (Platform.isAndroid) {
      final android = await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final okAndroid = await android?.requestNotificationsPermission();
      result = result && (okAndroid ?? true);
    }

    return result;
  }

  /// 즉시 알림(테스트용)
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(id, title, body, _details, payload: payload);
  }

  /// 단발 예약 (특정 시각)
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleAtLocal, // 로컬 시간 기준
    String? payload,
    bool allowWhileIdle = true,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduleAtLocal, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      _details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: null, // 단발이므로 null
    );
  }

  /// 매일 반복 (예: 매일 09:30)
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour, // 0~23
    required int minute, // 0~59
    String? payload,
  }) async {
    // zonedSchedule + matchDateTimeComponents.daily 사용 → DST 안전
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시각
    );
  }

  /// 매주 반복 (예: 매주 월/수 07:00 → 요일마다 id 다르게 2개 등록)
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required Day day,      // flutter_local_notifications의 Day enum
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // Day enum: sunday=1, monday=2 ... saturday=7
    final now = tz.TZDateTime.now(tz.local);
    // 이번 주의 목표 요일 시각 구하기
    var scheduled = _nextInstanceOfWeekday(day, hour, minute, from: now);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // 주 반복
    );
  }

  tz.TZDateTime _nextInstanceOfWeekday(Day day, int hour, int minute, {tz.TZDateTime? from}) {
    final base = from ?? tz.TZDateTime.now(tz.local);
    final targetWeekday = day.value; // 1~7 (일=1)
    // Dart에서는 월=1..일=7 (DateTime.weekday). Day enum과 약간 다름 → 맞춰서 처리
    // 여기서는 Day.value가 일=1, 월=2…이므로 아래 변환으로 통일
    int current = base.weekday % 7 + 1; // Dart: 월=1..일=7 → 일=1..토=7로 보정
    var scheduled = tz.TZDateTime(tz.local, base.year, base.month, base.day, hour, minute);
    while (current != targetWeekday || !scheduled.isAfter(base)) {
      scheduled = scheduled.add(const Duration(days: 1));
      current = scheduled.weekday % 7 + 1;
    }
    return scheduled;
  }

  /// 취소
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  /// 디버그: 예약된 알림 나열
  Future<List<PendingNotificationRequest>> pending() => _plugin.pendingNotificationRequests();
  
  /// 디버그: 권한 상태 확인
  Future<void> checkPermissionStatus() async {
    if (Platform.isIOS) {
      final ios = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      print('iOS 권한 상태: $settings');
    }
    
    if (Platform.isAndroid) {
      final android = await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final hasPermission = await android?.areNotificationsEnabled();
      print('Android 권한 상태: $hasPermission');
    }
  }
  
  /// 디버그: 5초 후 알림 테스트
  Future<void> showDelayedTest() async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 5));
    
    await scheduleOnce(
      id: 999,
      title: '5초 후 테스트 알림',
      body: '${now.hour}:${now.minute.toString().padLeft(2, '0')}에 예약된 알림입니다.',
      scheduleAtLocal: scheduledTime,
    );
    
    print('5초 후 알림 예약됨: $scheduledTime');
  }
}