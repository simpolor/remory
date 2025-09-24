# 🚨 Remory 에러 모니터링 가이드

## 개요
Remory 앱의 에러 모니터링 시스템은 다층 구조로 설계되어 개발부터 프로덕션까지 체계적인 에러 관리를 제공합니다.

## 📊 모니터링 구조

### 1. 에러 수집 레이어
```
Flutter Framework Error → FlutterError.onError
Platform Error → PlatformDispatcher.onError  
Zone Error → runZonedGuarded
Service Layer Error → ErrorHandlerMixin
```

### 2. 에러 분류 시스템
- **Database**: 데이터베이스 관련 오류
- **Network**: 네트워크 연결 오류  
- **Permission**: 권한 관련 오류
- **FileSystem**: 파일 시스템 오류
- **Unknown**: 분류되지 않은 오류

## 🔧 개발자 사용법

### 서비스 레이어에서 에러 처리
```dart
class MyService with ErrorHandlerMixin {
  Future<void> someOperation() async {
    try {
      // 비즈니스 로직
    } catch (error, stackTrace) {
      handleProviderError(
        error,
        stackTrace,
        type: ErrorType.database,
        context: 'someOperation',
        additionalData: {'userId': 123},
      );
      rethrow;
    }
  }
}
```

### Provider에서 AsyncValue 에러 처리
```dart
final dataProvider = FutureProvider<Data>((ref) async {
  return await someAsyncOperation();
}).handleErrors(
  errorType: ErrorType.network,
  context: 'dataProvider',
);
```

### 성능 모니터링 적용
```dart
class MyService with PerformanceMonitorMixin {
  Future<List<Data>> loadData() async {
    return await measurePerformance('loadData', () async {
      // 실제 로직
      return await repository.fetchData();
    });
  }
}
```

## 📱 사용자 경험

### 에러 표시
- **자동 스낵바**: 중요한 에러만 사용자에게 표시
- **타입별 아이콘**: 네트워크(📶), 데이터베이스(💾), 권한(🔒) 등
- **사용자 친화적 메시지**: 기술적 용어 대신 이해하기 쉬운 설명

### 개발 모드 디버깅
- **설정 > 에러 로그**: 실시간 에러 확인
- **설정 > 성능 모니터**: 앱 성능 통계
- **테스트 에러 발생**: 각 타입별 에러 시뮬레이션

## 🔍 로그 레벨

### Logger 출력 예시
```
🗄️ Database Error: Connection timeout
🌐 Network Error: Failed to connect
🔒 Permission Error: Camera access denied
📁 FileSystem Error: File not found
❌ Unknown Error: Unexpected error
```

## 🚀 프로덕션 설정

### Firebase Crashlytics 연동 (선택사항)
```dart
// lib/core/firebase_setup.dart에서 주석 해제
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

### 릴리스 빌드 시 자동 적용
- kReleaseMode에서만 Crashlytics 전송
- 개발 모드에서는 콘솔 로그만 출력

## 📈 성능 모니터링

### 측정 항목
- **평균 실행 시간**: 작업별 평균 소요 시간
- **최소/최대**: 가장 빠른/느린 실행 시간
- **P50/P95**: 50%, 95% 백분위수
- **실행 횟수**: 각 작업의 호출 빈도

### 경고 임계값
- **1000ms 이상**: ⚠️ 느린 작업 경고
- **500ms 이상**: ⏱️ 보통 작업 로그
- **500ms 미만**: 디버그 모드에서만 로그

## 🛠️ 확장 가능한 설계

### 새로운 에러 타입 추가
```dart
enum ErrorType {
  database,
  network,
  permission,
  fileSystem,
  payment,    // 새로운 타입 추가
  unknown,
}
```

### 커스텀 에러 핸들러
```dart
ErrorHandler().addListener((error) {
  // 커스텀 로직 (예: 슬랙 알림, 메트릭스 전송)
});
```

## 🔐 개인정보 보호

### 수집하지 않는 정보
- 사용자 개인정보
- 메모 내용
- 위치 정보

### 수집하는 정보
- 에러 발생 시간
- 앱 버전
- 플랫폼 정보
- 스택 트레이스 (코드 위치만)

## 📋 체크리스트

### 개발 시
- [ ] 새로운 서비스에 ErrorHandlerMixin 적용
- [ ] 중요한 작업에 성능 측정 적용
- [ ] 에러 타입 적절히 분류
- [ ] 개발자 도구로 에러 테스트

### 배포 전
- [ ] Firebase 설정 (필요시)
- [ ] 프로덕션 빌드에서 에러 수집 확인
- [ ] 사용자 메시지 검토
- [ ] 성능 임계값 검토

---

**문제가 발생하면:**
1. 설정 > 에러 로그에서 상세 정보 확인
2. 성능 모니터로 느린 작업 식별  
3. 필요시 Firebase Crashlytics에서 집계 데이터 분석
