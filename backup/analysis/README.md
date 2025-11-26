# 분석 탭 백업

이 디렉토리는 분석 탭 관련 파일들의 백업입니다.

## 백업 일자
2025-11-26

## 백업 이유
앱 구조 재구성으로 인해 분석 탭을 제거하고, 기능 탭으로 대체하기 위해 백업했습니다.

## 백업된 파일들

### Screens
- `screens/analysis/` - 분석 탭 전체 디렉토리
  - `analysis_tab.dart` - 분석 탭 메인 위젯
  - `models/analysis_models.dart` - 분석 모델
  - `services/analysis_service.dart` - 분석 서비스
  - `widgets/` - 분석 탭 위젯들
    - `charging_patterns/` - 충전 패턴 분석 관련 전체

### Services
- `services/battery_analysis_engine.dart` - 배터리 분석 엔진
- `services/battery_analysis_chart_service.dart` - 분석 차트 서비스

## 복구 방법
필요시 이 디렉토리의 파일들을 원래 위치로 복사하여 복구할 수 있습니다.

## 참고사항
- `ChargingSessionService`는 `main.dart`에서 주석 처리됨
- `showAnalysisProUpgradeDialog`는 `dialog_utils.dart`에서 주석 처리됨
- `MainNavigationScreen`에서 분석 탭 제거됨

