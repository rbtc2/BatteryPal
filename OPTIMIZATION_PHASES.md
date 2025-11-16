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

## Phase 3: 최적화 및 검증
**목표**: 성능 테스트 및 추가 최적화

### 3.1 성능 테스트
- 배터리 소모량 측정
- 메모리 사용량 확인
- 이벤트 처리 속도 검증

### 3.2 추가 최적화
- 불필요한 이벤트 필터링
- 캐싱 전략 개선
- 에러 처리 강화

---

## 예상 효과
- **배터리 소모**: 50-70% 감소 (폴링 제거)
- **정확도**: 향상 (이벤트 기반 실시간 업데이트)
- **백그라운드 지원**: 앱 종료 시에도 데이터 수집 가능

