import 'package:flutter/material.dart';

/// 홈 탭 UI 관련 상수
/// 홈 탭에서 사용되는 UI 요소들의 상수를 정의
class HomeUIConstants {
  // AppBar 관련
  static const String appBarTitle = 'BatteryPal';
  static const String refreshButtonTooltip = '배터리 정보 새로고침';
  static const String proBadgeText = '⚡ Pro';
  
  // 배터리 상태 카드
  static const String currentBatteryLabel = '현재 배터리';
  static const String temperatureLabel = '온도';
  static const String voltageLabel = '전압';
  static const String healthLabel = '건강도';
  static const String unknownValue = '알 수 없음';
  static const String unknownBatteryLevel = '--.-%';
  static const String unknownTemperature = '--.-°C';
  static const String unknownVoltage = '--mV';
  
  // 배터리 부스트 버튼
  static const String batteryBoostTitle = '⚡ 배터리 부스트';
  static const String batteryBoostSubtitle = '원클릭으로 즉시 최적화';
  static const String batteryBoostLoadingText = '최적화 중...';
  static const String batteryBoostLoadingSubtitle = '잠시만 기다려주세요';
  static const double batteryBoostButtonHeight = 120.0;
  static const double batteryBoostIconSize = 32.0;
  static const double batteryBoostTitleFontSize = 20.0;
  static const double batteryBoostSubtitleFontSize = 14.0;
  
  // 사용 제한 카드
  static const String usageLimitTitle = '무료 버전 사용 제한';
  static const String usageLimitUpgradeButton = 'Pro로 업그레이드';
  static const String usageLimitFormat = '오늘 %d/%d회 사용';
  
  // 충전 정보 섹션
  static const String chargingInfoIcon = 'bolt';
  static const double chargingInfoIconSize = 20.0;
  static const double chargingInfoFontSize = 14.0;
  
  // 마지막 업데이트
  static const String lastUpdatePrefix = '마지막 업데이트: ';
  static const double lastUpdateFontSize = 12.0;
  
  // 스낵바 메시지
  static const String refreshSuccessMessage = '배터리 정보를 새로고침했습니다 (%s)';
  static const String refreshErrorMessage = '새로고침 실패: %s';
  static const String optimizationSuccessMessage = '배터리 최적화가 완료되었습니다!';
  static const String proUpgradeMessage = 'Pro 업그레이드 기능이 곧 출시됩니다!';
  
  // 색상
  static const Color orangeColor = Colors.orange;
  static const Color redColor = Colors.red;
  static const Color greyColor = Colors.grey;
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  
  // 그라데이션 색상
  static const List<Color> proBadgeGradientColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFFA500), // Orange
  ];
  
  // 패딩 및 마진
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingMedium = EdgeInsets.all(12);
  static const EdgeInsets cardPaddingTiny = EdgeInsets.all(8);
  static const EdgeInsets cardPaddingMicro = EdgeInsets.all(6);
  
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 16.0;
  static const double smallSpacing = 12.0;
  static const double tinySpacing = 8.0;
  static const double microSpacing = 6.0;
  static const double nanoSpacing = 4.0;
  
  // 아이콘 크기
  static const double batteryIconSize = 48.0;
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 20.0;
  static const double largeIconSize = 24.0;
  static const double xlargeIconSize = 32.0;
  
  // 텍스트 크기
  static const double headlineLargeFontSize = 32.0;
  static const double titleMediumFontSize = 18.0;
  static const double bodyMediumFontSize = 14.0;
  static const double bodySmallFontSize = 12.0;
  static const double captionFontSize = 11.0;
  
  // Border radius
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double tinyBorderRadius = 6.0;
  static const double microBorderRadius = 2.0;
  
  // Elevation
  static const double cardElevation = 4.0;
  static const double cardElevationSmall = 2.0;
  
  // Shadow
  static const double shadowBlurRadius = 12.0;
  static const Offset shadowOffset = Offset(0, 6);
  
  // 애니메이션
  static const Duration refreshAnimationDuration = Duration(milliseconds: 2000);
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration snackBarErrorDuration = Duration(seconds: 3);
  static const Duration chargingAnimationDuration = Duration(milliseconds: 1000);
  
  // 로딩 인디케이터
  static const double loadingIndicatorSize = 20.0;
  static const double loadingIndicatorStrokeWidth = 2.0;
  static const double loadingIndicatorStrokeWidthLarge = 3.0;
  
  // 알파 값
  static const double alphaHigh = 0.9;
  static const double alphaMedium = 0.7;
  static const double alphaLow = 0.5;
  static const double alphaVeryLow = 0.3;
  static const double alphaUltraLow = 0.1;
  static const double alphaMicro = 0.08;
}
