# BatteryService 리팩토링 계획

## 목표
955줄의 `BatteryService`를 단일 책임 원칙에 따라 여러 클래스로 분리하여 유지보수성과 확장성을 향상시킵니다.

## 리팩토링 단계

### Phase 1: BatteryInfoValidator 생성 ✅
**목표**: 검증 로직을 독립적인 클래스로 분리

**작업 내용**:
- `lib/services/battery/battery_info_validator.dart` 생성
- 배터리 정보 유효성 검증 로직 이동 (`_isValidBatteryInfo`)
- 업데이트 간격 검증 로직 이동 (`_shouldUpdate`)
- `BatteryService`에서 `BatteryInfoValidator` 사용하도록 변경

**검증 방법**:
- 기존 기능 동작 확인
- 배터리 정보 업데이트 정상 작동 확인

**예상 소요 시간**: 15분

---

### Phase 2: BatteryDataCollector 생성 ✅
**목표**: 배터리 정보 수집 로직을 독립적인 클래스로 분리

**작업 내용**:
- `lib/services/battery/battery_data_collector.dart` 생성
- 네이티브 배터리 정보 수집 로직 이동 (`_getNativeBatteryInfo`)
- 플러그인 배터리 정보 수집 로직 이동 (`_getPluginBatteryInfo`)
- 폴백 로직 이동 (`_fallbackToMinimalBatteryInfo`)
- `BatteryService`에서 `BatteryDataCollector` 사용하도록 변경

**검증 방법**:
- 배터리 정보 수집 정상 작동 확인
- 네이티브/플러그인 폴백 동작 확인

**예상 소요 시간**: 20분

---

### Phase 3: ChargingCurrentMonitor 생성 ✅
**목표**: 충전 전류 모니터링 로직을 독립적인 클래스로 분리

**작업 내용**:
- `lib/services/battery/charging_current_monitor.dart` 생성
- 충전 전류 모니터링 관련 필드 및 메서드 이동:
  - `_chargingCurrentTimer`, `_chargingCurrentInterval`
  - `_recentChargingCurrents`, `_stabilityCheckCount`
  - `_chargingCurrentBuffer`, `_chargingCurrentSaveTimer`
  - `_startChargingCurrentMonitoring()`, `_stopChargingCurrentMonitoring()`
  - `_updateChargingCurrentOnly()`, `_saveChargingCurrentToDatabase()`
  - `_adjustMonitoringInterval()`, `_isChargingCurrentStable()`
  - `getStableChargingCurrent()`, `getMedianChargingCurrent()`
- `BatteryService`에서 `ChargingCurrentMonitor` 사용하도록 변경

**검증 방법**:
- 충전 전류 모니터링 정상 작동 확인
- 적응형 간격 조정 동작 확인
- 데이터베이스 저장 동작 확인

**예상 소요 시간**: 30분

---

### Phase 4: BatteryNotificationManager 생성 ✅
**목표**: 알림 관리 로직을 독립적인 클래스로 분리

**작업 내용**:
- `lib/services/battery/battery_notification_manager.dart` 생성
- 알림 관련 필드 및 메서드 이동:
  - `_hasNotifiedChargingComplete`, `_chargingPercentNotified`
  - `_checkChargingCompleteNotification()`
  - `_checkChargingPercentNotification()`
  - `_shouldNotifyForChargingType()`
- `BatteryService`에서 `BatteryNotificationManager` 사용하도록 변경

**검증 방법**:
- 충전 완료 알림 정상 작동 확인
- 충전 퍼센트 알림 정상 작동 확인
- 알림 타입 필터링 동작 확인

**예상 소요 시간**: 25분

---

### Phase 5: BatteryService 최종 리팩토링 ✅
**목표**: 분리된 서비스들을 조합하고 코드 정리

**작업 내용**:
- `BatteryService`에서 분리된 서비스들을 조합
- 중복 코드 제거 (충전 상태 변화 처리 로직을 헬퍼 메서드로 추출)
- 공통 유틸리티 메서드 정리 (`_debugLog` 등)
- 주석 및 문서화 개선 (클래스 문서, 메서드 문서 추가)
- 코드 구조 정리 (섹션 구분 주석 추가)

**검증 방법**:
- 전체 기능 통합 테스트
- 성능 테스트
- 메모리 누수 확인

**예상 소요 시간**: 20분

---

## 전체 예상 소요 시간
약 110분 (약 2시간)

## 주의사항
1. 각 Phase는 독립적으로 테스트 가능해야 함
2. 기존 기능이 깨지지 않도록 주의
3. 각 Phase 완료 후 커밋 권장
4. 리팩토링 중 기능 추가는 지양

## 리팩토링 후 실제 구조

```
lib/services/battery/
├── battery_service.dart              (443줄, 조합 및 조정)
├── battery_data_collector.dart       (169줄, 정보 수집)
├── battery_info_validator.dart       (76줄, 검증)
├── charging_current_monitor.dart     (345줄, 충전 전류 모니터링)
└── battery_notification_manager.dart (197줄, 알림 관리)
```

**총 실제 줄 수**: 1,230줄 (기존 955줄보다 많지만, 문서화와 구조 개선으로 인한 증가)

## 리팩토링 결과

### 개선 사항
1. **단일 책임 원칙 준수**: 각 클래스가 명확한 단일 책임을 가짐
2. **코드 재사용성 향상**: 분리된 서비스들을 독립적으로 테스트 및 재사용 가능
3. **유지보수성 향상**: 기능 추가/수정 시 해당 클래스만 수정하면 됨
4. **가독성 향상**: 섹션 구분 주석과 문서화로 코드 이해가 쉬워짐
5. **중복 코드 제거**: 충전 상태 변화 처리 로직을 헬퍼 메서드로 추출

### 주요 변경 사항
- **BatteryInfoValidator**: 검증 로직 전담
- **BatteryDataCollector**: 정보 수집 로직 전담 (네이티브/플러그인 폴백)
- **ChargingCurrentMonitor**: 충전 전류 모니터링 전담 (적응형 간격, 안정성 추적, DB 저장)
- **BatteryNotificationManager**: 알림 관리 전담 (충전 완료, 퍼센트 알림)
- **BatteryService**: 위 서비스들을 조합하여 통합 서비스 제공

