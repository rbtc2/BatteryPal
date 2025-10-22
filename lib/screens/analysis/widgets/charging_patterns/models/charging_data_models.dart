// 충전 패턴 분석을 위한 데이터 모델들

/// 충전 데이터 포인트 클래스
class ChargingDataPoint {
  final double hour; // 0.0 ~ 24.0
  final double currentMa;
  
  ChargingDataPoint(this.hour, this.currentMa);
}

/// 충전 세션 정보 모델
class ChargingSession {
  final String icon;
  final String title;
  final String timeRange;
  final String batteryChange;
  final String duration;
  final String avgCurrent;
  final String efficiency;
  final String temperature;
  final List<String> speedChanges;
  final String colorHex;
  final bool isExpanded;

  ChargingSession({
    required this.icon,
    required this.title,
    required this.timeRange,
    required this.batteryChange,
    required this.duration,
    required this.avgCurrent,
    required this.efficiency,
    required this.temperature,
    required this.speedChanges,
    required this.colorHex,
    this.isExpanded = false,
  });
}

/// 통계 카드 데이터 모델
class StatCardData {
  final String title;
  final String mainValue;
  final String unit;
  final String subValue;
  final String trend;
  final String trendColorHex;
  final String iconName;

  StatCardData({
    required this.title,
    required this.mainValue,
    required this.unit,
    required this.subValue,
    required this.trend,
    required this.trendColorHex,
    required this.iconName,
  });
}

/// Pro 기능 정보 모델
class ProFeature {
  final String title;
  final String description;
  final String icon;

  ProFeature({
    required this.title,
    required this.description,
    required this.icon,
  });
}
