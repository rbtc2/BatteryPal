# ChargingStatsCard 리팩토링 계획

## 목표
1262줄의 `ChargingStatsCard`를 단일 책임 원칙에 따라 여러 클래스로 분리하여 유지보수성과 확장성을 향상시킵니다.

## 현재 문제점

1. **단일 책임 원칙 위반**: 다음 책임들이 한 위젯에 집중되어 있습니다.
   - 상태 관리 (날짜 선택, 세션 데이터, 통계)
   - 데이터 로딩 및 캐싱
   - 통계 계산
   - UI 빌드 (통계 카드, 세션 리스트, 진행 중인 충전 카드)
   - 타이머 관리
   - 날짜 선택 다이얼로그

2. **테스트 어려움**: 여러 책임이 결합되어 단위 테스트가 복잡함

3. **유지보수 어려움**: 기능 추가/수정 시 전체 위젯에 영향

4. **확장성 저하**: 기능 추가 시 위젯이 더 커짐

## 리팩토링 단계

### Phase 1: ChargingStatsCalculator 생성
**목표**: 통계 계산 로직을 독립적인 유틸리티 클래스로 분리

**작업 내용**:
- `lib/screens/analysis/widgets/charging_patterns/utils/charging_stats_calculator.dart` 생성
- 통계 계산 로직 이동 (`_calculateStats`)
- 평균 전류, 세션 개수, 주 시간대 계산 로직 분리
- `ChargingStatsCard`에서 `ChargingStatsCalculator` 사용하도록 변경

**검증 방법**:
- 기존 기능 동작 확인
- 통계 계산 결과 정확성 확인

**예상 소요 시간**: 15분

---

### Phase 2: DateSelectorController 생성
**목표**: 날짜 선택 및 관리 로직을 독립적인 컨트롤러로 분리

**작업 내용**:
- `lib/screens/analysis/widgets/charging_patterns/controllers/date_selector_controller.dart` 생성
- 날짜 선택 관련 상태 및 로직 이동:
  - `_selectedTab`, `_selectedDate`
  - `_getCurrentDate()`, `_getDateDisplayText()`, `_getDateUnitText()`
  - `_showDatePicker()`
- 날짜 변경 콜백 제공
- `ChargingStatsCard`에서 `DateSelectorController` 사용하도록 변경

**검증 방법**:
- 날짜 선택 기능 정상 작동 확인
- 탭 전환 동작 확인
- 날짜 선택 다이얼로그 동작 확인

**예상 소요 시간**: 25분

---

### Phase 3: ChargingSessionDataLoader 생성
**목표**: 데이터 로딩 및 캐싱 로직을 독립적인 클래스로 분리

**작업 내용**:
- `lib/screens/analysis/widgets/charging_patterns/controllers/charging_session_data_loader.dart` 생성
- 데이터 로딩 관련 로직 이동:
  - `_loadSessionsByDate()`
  - `_dateCache`, `_cleanupOldCache()`
  - `_getDateKey()`
- 캐싱 전략 관리
- 데이터 로딩 상태 관리
- `ChargingStatsCard`에서 `ChargingSessionDataLoader` 사용하도록 변경

**검증 방법**:
- 데이터 로딩 정상 작동 확인
- 캐싱 동작 확인
- 오늘/과거 날짜별 로딩 전략 확인

**예상 소요 시간**: 30분

---

### Phase 4: UI 컴포넌트 분리
**목표**: UI 빌드 로직을 독립적인 위젯으로 분리

**작업 내용**:
- `lib/screens/analysis/widgets/charging_patterns/widgets/stat_card.dart` 생성
  - `_buildEnhancedStatCard()` 로직 이동
  - 통계 카드 UI 전담
- `lib/screens/analysis/widgets/charging_patterns/widgets/active_charging_card.dart` 생성
  - `_buildActiveChargingCard()` 로직 이동
  - `_buildActiveInfoItem()` 로직 이동
  - `_PulsingDot` 위젯 이동
  - 진행 중인 충전 카드 UI 전담
- `lib/screens/analysis/widgets/charging_patterns/widgets/date_selector_tabs.dart` 생성
  - `_buildTabButton()` 로직 이동
  - 날짜 선택 탭 UI 전담
- `ChargingStatsCard`에서 위 위젯들 사용하도록 변경

**검증 방법**:
- 각 UI 컴포넌트 정상 렌더링 확인
- 상호작용 동작 확인

**예상 소요 시간**: 40분

---

### Phase 5: ChargingStatsController 생성
**목표**: 상태 관리 및 타이머 관리를 통합 컨트롤러로 분리

**작업 내용**:
- `lib/screens/analysis/widgets/charging_patterns/controllers/charging_stats_controller.dart` 생성
- 상태 관리 통합:
  - `_currentSessions`, `_isLoading`
  - `_avgCurrent`, `_sessionCount`, `_mainTimeSlot`
  - `_isSessionsExpanded`
- 타이머 관리:
  - `_refreshTimer`, `_activeSessionUpdateTimer`
  - `_startAutoRefresh()`, `_stopAutoRefresh()`
  - `_startActiveSessionUpdate()`
- 스트림 구독 관리
- 서비스 초기화 관리
- `ChargingStatsCard`에서 `ChargingStatsController` 사용하도록 변경

**검증 방법**:
- 상태 관리 정상 작동 확인
- 타이머 동작 확인
- 스트림 구독 동작 확인

**예상 소요 시간**: 35분

---

### Phase 6: ChargingStatsCard 최종 리팩토링
**목표**: 분리된 컴포넌트들을 조합하고 코드 정리

**작업 내용**:
- `ChargingStatsCard`에서 분리된 컴포넌트들을 조합
- 불필요한 코드 제거
- 주석 및 문서화 개선
- 코드 구조 정리 (섹션 구분 주석 추가)
- 최종 테스트 및 검증

**검증 방법**:
- 전체 기능 통합 테스트
- UI 렌더링 확인
- 성능 테스트

**예상 소요 시간**: 25분

---

## 전체 예상 소요 시간
약 170분 (약 2시간 50분)

## 주의사항
1. 각 Phase는 독립적으로 테스트 가능해야 함
2. 기존 기능이 깨지지 않도록 주의
3. 각 Phase 완료 후 커밋 권장
4. 리팩토링 중 기능 추가는 지양
5. Flutter 위젯 생명주기 고려 (mounted 체크 등)

## 리팩토링 후 예상 구조

```
lib/screens/analysis/widgets/charging_patterns/
├── widgets/
│   ├── charging_stats_card.dart              (~200줄, 조합 및 조정)
│   ├── active_charging_card.dart             (~150줄, 진행 중인 충전 카드)
│   ├── stat_card.dart                        (~100줄, 통계 카드)
│   ├── date_selector_tabs.dart               (~150줄, 날짜 선택 탭)
│   └── charging_session_list_section.dart   (~100줄, 세션 리스트 섹션)
├── controllers/
│   ├── charging_stats_controller.dart        (~200줄, 상태 관리 및 데이터 로딩)
│   ├── date_selector_controller.dart          (~100줄, 날짜 선택 관리)
│   └── charging_session_data_loader.dart     (~150줄, 데이터 로딩 및 캐싱)
└── utils/
    └── charging_stats_calculator.dart        (~100줄, 통계 계산)
```

**총 예상 줄 수**: ~1,250줄 (기존 1,262줄과 유사하지만 책임이 명확히 분리됨)

## 리팩토링 순서의 이유

1. **Phase 1 (통계 계산)**: 가장 독립적이고 의존성이 적음
2. **Phase 2 (날짜 선택)**: 데이터 로딩과 밀접하게 연관되지만 먼저 분리 가능
3. **Phase 3 (데이터 로딩)**: 통계 계산과 날짜 선택에 의존
4. **Phase 4 (UI 컴포넌트)**: 상태 관리와 독립적으로 분리 가능
5. **Phase 5 (컨트롤러)**: 위 단계들이 완료된 후 통합 관리
6. **Phase 6 (최종 정리)**: 모든 분리가 완료된 후 조합 및 정리

