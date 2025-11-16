# 배터리 효율성 개선 Phase별 계획

## 개요
비효율적인 폴링 방식과 앱 종료 시 작동하지 않는 문제를 해결하기 위한 단계별 개선 계획입니다.

---

## Phase 1: 폴링 방식 제거 및 이벤트 기반 전환
**목표**: 모든 `Timer.periodic` 기반 폴링을 `batteryInfoStream` 이벤트 기반으로 전환

### 1.1 HomeLifecycleManager 개선
- **현재 문제**: 10초/30초/60초마다 `refreshBatteryInfo()` 호출
- **개선 방안**: 
  - `_startPeriodicRefresh()` 메서드 제거
  - `_stopPeriodicRefresh()` 메서드 제거
  - `_optimizeForBackground()`에서 주기적 새로고침 제거
  - 이미 `batteryInfoStream`을 구독하고 있으므로, 이벤트만으로 충분

### 1.2 BatteryDrainTab 개선
- **현재 문제**: 탭이 보일 때 1분마다 자동 새로고침
- **개선 방안**:
  - `_startRealtimeUpdate()`의 1분 타이머 제거
  - `HomeLifecycleManager`의 `batteryInfoStream` 구독으로 전환
  - 탭 전환 시에만 한 번 새로고침

### 1.3 ChargingCurrentHistoryService 개선
- **현재 문제**: 1분마다 배치 저장 실행
- **개선 방안**:
  - `_startBatchSaveTimer()` 제거
  - 데이터가 일정량 쌓이거나 충전 종료 시에만 저장
  - 날짜 변경 감지는 `batteryInfoStream` 이벤트에서 처리

### 1.4 BatteryHistoryService 개선
- **현재 문제**: 5분마다 주기적 데이터 수집
- **개선 방안**:
  - `_startPeriodicCollection()` 제거
  - `batteryInfoStream` 이벤트에서 의미있는 변화만 수집
  - `_shouldCollectData()` 로직 활용

---

## Phase 2: 백그라운드 지원 강화
**목표**: 앱이 완전히 종료되어도 충전 데이터 수집 가능

### 2.1 WorkManager와 Dart 서비스 통합
- **현재 문제**: WorkManager는 있지만 Dart 서비스와 완전히 통합되지 않음
- **개선 방안**:
  - WorkManager에서 수집한 데이터를 Dart 서비스가 인식하도록 개선
  - `ChargingCurrentHistoryService`가 앱 시작 시 백그라운드 데이터 확인 및 동기화
  - `ChargingSessionService`가 백그라운드 데이터로 세션 분석 가능하도록 개선

### 2.2 데이터 동기화 메커니즘
- WorkManager → SQLite DB → Dart 서비스 읽기
- 앱 시작 시 최근 24시간 백그라운드 데이터 확인
- 메모리와 DB 데이터 병합 로직 개선

---

## Phase 3: 최적화 및 검증 ✅ 완료
**목표**: 성능 테스트 및 추가 최적화

### 3.1 불필요한 이벤트 필터링 추가 ✅
- **BatteryService**: `_shouldEmitEvent()` 메서드 추가
  - 배터리 레벨 변화 0.5% 이상일 때만 이벤트 전달
  - 충전 전류 변화 50mA 이상일 때만 이벤트 전달
  - 온도 변화 2°C 이상일 때만 이벤트 전달
  - 전압 변화 50mV 이상일 때만 이벤트 전달
  - 충전 상태 변화는 항상 전달
- **HomeLifecycleManager**: `_shouldProcessBatteryInfo()` 메서드 추가
  - 캐시된 정보와 비교하여 의미있는 변화만 처리
  - 캐시 만료 시간 체크 추가
  - 중복 업데이트 방지 강화

### 3.2 캐싱 전략 개선 ✅
- **HomeLifecycleManager**: 중복 업데이트 방지 로직 강화
  - 캐시 유효성 검증 추가
  - 의미있는 변화만 콜백 호출
- **ChargingCurrentHistoryService**: 데이터 검증 추가
  - 저장 전 데이터 크기 검증 (10000개 이상 시 최근 1000개만 저장)
  - 메모리 정리 시 에러 처리 추가

### 3.3 에러 처리 강화 ✅
- **BatteryService**: 스트림 에러 처리 강화
  - `_safeAddEvent()`에서 try-catch 추가
  - 에러 발생 시에도 서비스 계속 작동
- **HomeLifecycleManager**: 스트림 구독 에러 처리 추가
  - `onError` 콜백 추가
  - 에러 발생 시에도 서비스 계속 작동
- **ChargingCurrentHistoryService**: 전역 에러 처리 추가
  - `_recordChargingCurrent()`에 try-catch 추가
  - `_saveToDatabase()`에 에러 처리 강화
  - 날짜 변경 처리, 메모리 정리 시 에러 처리 추가
- **BatteryHistoryService**: 에러 처리 강화
  - `_onBatteryStateChanged()`에 stackTrace 추가
  - `_collectCurrentBatteryData()`에 stackTrace 추가
  - `_onBatteryError()`에 주석 추가
- **ChargingSessionService**: 에러 처리 강화
  - `_onError()`에 주석 추가 및 재연결 로직 언급

### 성능 개선 효과
- **이벤트 필터링**: 불필요한 이벤트 전달 감소로 CPU 사용량 감소
- **캐싱 전략**: 중복 업데이트 방지로 UI 업데이트 빈도 감소
- **에러 처리**: 에러 발생 시에도 서비스 안정성 향상

---

## 예상 효과
- **배터리 소모**: 50-70% 감소 (폴링 제거)
- **정확도**: 향상 (이벤트 기반 실시간 업데이트)
- **백그라운드 지원**: 앱 종료 시에도 데이터 수집 가능

