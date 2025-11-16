# 백그라운드 충전 감지 문제 분석 및 해결 방안

## 1. 문제 원인 분석

### 현재 상황
앱이 켜져 있지 않을 때 충전이 발생해도 충전 감지 기능(분석-충전 분석 카드 생성 등)이 작동하지 않습니다. 현재는 앱이 최소 백그라운드에 켜져 있어야만 충전 감지가 작동합니다.

### 근본 원인

#### 1.1 BatteryStateReceiver는 작동하지만 데이터 수집은 안 됨
- **BatteryStateReceiver.kt**는 AndroidManifest.xml에 정적으로 등록되어 있어 앱이 완전히 종료되어도 충전 시작/종료를 감지할 수 있습니다.
- 하지만 이 리시버는 단순히 **SharedPreferences에만 메타데이터를 저장**할 뿐, 실제 충전 전류 데이터 수집이나 세션 분석은 수행하지 않습니다.

#### 1.2 Dart 서비스들은 앱 실행 중에만 작동
다음 서비스들은 모두 `BatteryService.batteryInfoStream`을 구독하여 작동합니다:
- **ChargingSessionService**: 충전 세션 감지 및 분석
- **ChargingCurrentHistoryService**: 충전 전류 히스토리 수집

이 스트림은 `BatteryService.startMonitoring()`이 호출되어야 작동하는데, 이는 **앱이 실행 중일 때만 가능**합니다.

#### 1.3 데이터 수집의 공백
앱이 꺼져 있을 때:
1. ✅ BatteryStateReceiver는 충전 시작/종료를 감지하고 SharedPreferences에 저장
2. ❌ ChargingSessionService는 실행되지 않음 → 세션 분석 불가
3. ❌ ChargingCurrentHistoryService는 실행되지 않음 → 충전 전류 데이터 수집 불가
4. ❌ BatteryService 스트림이 작동하지 않음 → 실시간 데이터 수집 불가

### 현재 아키텍처의 한계

```
앱 실행 중:
  BatteryService.startMonitoring() 
    → batteryInfoStream 활성화
      → ChargingSessionService 구독
      → ChargingCurrentHistoryService 구독
      → 실시간 데이터 수집 ✅

앱 종료 상태:
  BatteryStateReceiver (네이티브)
    → SharedPreferences에 메타데이터만 저장
    → Dart 서비스들은 실행되지 않음 ❌
    → 데이터 수집 불가 ❌
```

## 2. 해결 방안 (Phase별)

### Phase 1: 네이티브 백그라운드 서비스 구현
**목표**: 앱이 꺼져 있어도 충전 전류 데이터를 수집할 수 있는 네이티브 서비스 구현

#### 1.1 Foreground Service 또는 WorkManager 선택
- **Foreground Service**: 
  - 장점: 지속적인 데이터 수집 보장, 실시간 모니터링 가능
  - 단점: 사용자에게 알림 표시 필요, 배터리 소모 증가
- **WorkManager**: 
  - 장점: 배터리 효율적, 시스템이 최적화된 시점에 실행
  - 단점: 정확한 타이밍 보장 어려움, 주기적 실행 제한

**권장**: **WorkManager** 사용 (충전 중 주기적 데이터 수집에 적합)

#### 1.2 BatteryStateReceiver 확장
현재 `BatteryStateReceiver`는 충전 시작/종료만 감지합니다. 이를 확장하여:
- 충전 시작 시: WorkManager 주기적 작업 예약
- 충전 종료 시: WorkManager 작업 취소
- 충전 중: 주기적으로 배터리 정보 수집 및 데이터베이스에 저장

#### 1.3 네이티브 데이터 수집 서비스 구현
**새 파일**: `android/app/src/main/kotlin/com/example/batterypal/ChargingDataCollector.kt`
- 충전 중 주기적으로 (예: 10초마다) 배터리 정보 수집
- 충전 전류, 배터리 레벨, 시간 등을 SQLite 데이터베이스에 직접 저장
- Flutter의 데이터베이스와 동일한 스키마 사용

### Phase 2: Flutter 데이터베이스와 동기화
**목표**: 네이티브에서 수집한 데이터를 Flutter 앱이 인식할 수 있도록 통합

#### 2.1 데이터베이스 스키마 통일
- 네이티브 서비스가 Flutter와 동일한 SQLite 데이터베이스 파일을 사용
- 또는 네이티브에서 수집한 데이터를 별도 테이블에 저장하고, 앱 시작 시 Flutter 데이터베이스로 마이그레이션

#### 2.2 앱 시작 시 데이터 복구
**수정 파일**: `lib/services/charging_current_history_service.dart`
- 앱 시작 시 네이티브에서 수집한 데이터 확인
- 누락된 데이터를 Flutter 데이터베이스로 로드
- ChargingSessionService가 이 데이터를 기반으로 세션 분석 수행

#### 2.3 충전 세션 복구 로직
**수정 파일**: `lib/screens/analysis/widgets/charging_patterns/services/charging_session_service.dart`
- 앱 시작 시 SharedPreferences에서 충전 세션 메타데이터 확인
- 네이티브에서 수집한 충전 전류 데이터와 결합하여 세션 재구성
- 앱이 꺼져 있던 동안의 충전 세션도 분석 가능하도록

### Phase 3: 백그라운드 작업 최적화
**목표**: 배터리 효율성과 데이터 정확성의 균형

#### 3.1 적응형 수집 주기
- 충전 전류가 높을 때: 더 자주 수집 (예: 5초)
- 충전 전류가 낮을 때: 덜 자주 수집 (예: 30초)
- 충전이 완료되면 수집 중지

#### 3.2 배터리 최적화 예외 처리
- 사용자에게 배터리 최적화 예외 설정 안내
- WorkManager의 `setExpedited()` 또는 `setImportantWhileForeground()` 사용 고려

#### 3.3 데이터 정리 및 중복 방지
- 네이티브와 Flutter에서 동시에 수집되는 경우 중복 방지
- 타임스탬프 기반 중복 체크
- 앱 시작 시 데이터 병합 로직

### Phase 4: 사용자 경험 개선
**목표**: 사용자가 앱을 켜지 않아도 충전 데이터를 확인할 수 있도록

#### 4.1 앱 시작 시 데이터 동기화 알림
- 앱 시작 시 백그라운드에서 수집된 충전 데이터가 있으면 알림 표시
- "X개의 충전 세션이 새로 추가되었습니다" 같은 메시지

#### 4.2 충전 분석 카드 자동 업데이트
- 앱 시작 시 자동으로 최신 충전 데이터 로드
- 분석 탭의 충전 분석 카드가 자동으로 업데이트

#### 4.3 설정 옵션 추가
- 백그라운드 데이터 수집 활성화/비활성화 옵션
- 수집 주기 설정 (5초, 10초, 30초 등)

## 3. 구현 우선순위

### High Priority (필수)
1. **Phase 1.2**: BatteryStateReceiver 확장 (WorkManager 작업 예약/취소)
2. **Phase 1.3**: 네이티브 데이터 수집 서비스 구현
3. **Phase 2.1**: 데이터베이스 스키마 통일
4. **Phase 2.2**: 앱 시작 시 데이터 복구

### Medium Priority (중요)
5. **Phase 2.3**: 충전 세션 복구 로직
6. **Phase 3.1**: 적응형 수집 주기
7. **Phase 4.2**: 충전 분석 카드 자동 업데이트

### Low Priority (선택)
8. **Phase 3.2**: 배터리 최적화 예외 처리
9. **Phase 4.1**: 데이터 동기화 알림
10. **Phase 4.3**: 설정 옵션 추가

## 4. 기술적 고려사항

### 4.1 Android 버전 호환성
- WorkManager는 Android 5.0 (API 21) 이상 지원
- Foreground Service는 Android 8.0 (API 26) 이상에서 알림 채널 필요
- 배터리 최적화는 Android 6.0 (API 23) 이상에서 중요

### 4.2 데이터베이스 접근
- 네이티브와 Flutter가 동일한 SQLite 파일에 접근하는 경우 동시성 문제 고려
- WAL (Write-Ahead Logging) 모드 사용 권장
- 트랜잭션 처리 필요

### 4.3 배터리 소모
- 주기적 데이터 수집은 배터리 소모 증가
- 적응형 주기와 효율적인 WorkManager 사용으로 최소화
- 사용자에게 선택권 제공

## 5. 예상 효과

### 해결 전
- 앱이 꺼져 있을 때 충전 발생 → 데이터 수집 안 됨
- 앱을 켜도 과거 충전 데이터 확인 불가
- 사용자가 앱을 항상 실행해야 함

### 해결 후
- 앱이 꺼져 있어도 충전 데이터 자동 수집
- 앱 시작 시 자동으로 과거 충전 데이터 복구 및 분석
- 사용자가 앱을 켜지 않아도 충전 이력 확인 가능
- 완전한 충전 이력 추적 가능

## 6. 참고 사항

### 현재 구현된 기능
- ✅ BatteryStateReceiver: 충전 시작/종료 감지 (네이티브)
- ✅ SharedPreferences에 충전 세션 메타데이터 저장
- ✅ Flutter에서 SharedPreferences 데이터 읽기 (`getChargingSessionInfo`)

### 부족한 기능
- ❌ 백그라운드에서 충전 전류 데이터 수집
- ❌ 앱 시작 시 백그라운드 데이터 복구
- ❌ 백그라운드 데이터 기반 세션 분석

### 관련 파일
- `android/app/src/main/kotlin/com/example/batterypal/BatteryStateReceiver.kt`
- `lib/services/charging_current_history_service.dart`
- `lib/screens/analysis/widgets/charging_patterns/services/charging_session_service.dart`
- `lib/services/battery_service.dart`
- `android/app/src/main/kotlin/com/example/batterypal/MainActivity.kt`

