import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// 충전 분석 서비스
/// 충전 속도 분석, 충전 최적화 팁 등의 로직을 관리
class ChargingAnalysisService {
  /// 실제 충전 전류값을 사용한 충전 속도 정보
  static ChargingSpeedInfo getChargingSpeedInfo(BatteryInfo? batteryInfo) {
    if (batteryInfo == null) {
      debugPrint('ChargingAnalysisService: 배터리 정보가 없음');
      return _getDefaultChargingSpeed();
    }

    // 충전 전류값 가져오기 (음수면 절댓값 사용)
    final chargingCurrent = batteryInfo.chargingCurrent.abs();
    debugPrint('ChargingAnalysisService: 현재 충전 전류 ${chargingCurrent}mA');
    
    // 충전 속도 분류
    String speedLabel;
    String description;
    Color color;
    IconData icon;
    List<String> tips;

    if (chargingCurrent >= 2000) {
      // 초고속 충전 (2A 이상)
      speedLabel = '초고속 충전';
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = Colors.red;
      icon = Icons.flash_on;
      tips = [
        '초고속 충전으로 빠르게 충전 중입니다',
        '80% 이상 충전 시 속도가 감소합니다',
        '충전 완료 후 즉시 분리 권장',
        '충전 중 고성능 작업은 피하세요',
      ];
    } else if (chargingCurrent >= 1000) {
      // 고속 충전 (1A ~ 2A)
      speedLabel = '고속 충전';
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = Colors.orange;
      icon = Icons.electric_bolt;
      tips = [
        '고속 충전으로 충전 중입니다',
        '80% 이상 충전 시 속도가 감소합니다',
        '충전 완료 후 30분 이내 분리 권장',
        '충전 중 고성능 작업은 피하세요',
      ];
    } else if (chargingCurrent >= 500) {
      // 일반 충전 (0.5A ~ 1A)
      speedLabel = '일반 충전';
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = Colors.blue;
      icon = Icons.battery_charging_full;
      tips = [
        '일반 충전으로 충전 중입니다',
        '충전 속도가 느릴 수 있습니다',
        '충전 완료 후 분리해주세요',
        '배터리 온도가 높으면 충전 속도가 느려집니다',
      ];
    } else {
      // 저속 충전 (0.5A 미만)
      speedLabel = '저속 충전';
      description = '${chargingCurrent}mA 충전 중';
      color = Colors.grey;
      icon = Icons.battery_charging_full;
      tips = [
        '저속 충전으로 충전 중입니다',
        '충전 속도가 매우 느립니다',
        '고전력 충전기 사용을 권장합니다',
        '충전 중 사용을 최소화하세요',
      ];
    }

    debugPrint('ChargingAnalysisService: 충전 속도 분석 결과 - $speedLabel ($description)');
    
    return ChargingSpeedInfo(
      label: speedLabel,
      description: description,
      color: color,
      icon: icon,
      tips: tips,
    );
  }

  /// 기본 충전 속도 정보 (배터리 정보가 없을 때)
  static ChargingSpeedInfo _getDefaultChargingSpeed() {
    return ChargingSpeedInfo(
      label: '충전 중',
      description: '충전 정보 확인 중',
      color: Colors.grey,
      icon: Icons.electric_bolt_outlined,
      tips: [
        '충전 정보를 확인하고 있습니다',
        '잠시만 기다려주세요',
      ],
    );
  }

  /// 충전 상태 분석
  static ChargingStatusAnalysis analyzeChargingStatus(BatteryInfo? batteryInfo) {
    if (batteryInfo == null) {
      return ChargingStatusAnalysis(
        isCharging: false,
        chargingSpeed: ChargingSpeed.unknown,
        estimatedTimeToFull: null,
        chargingEfficiency: ChargingEfficiency.unknown,
        recommendations: ['배터리 정보를 확인하고 있습니다'],
      );
    }

    final chargingCurrent = batteryInfo.chargingCurrent.abs();
    final currentLevel = batteryInfo.level;
    final temperature = batteryInfo.temperature;

    // 충전 속도 분류
    ChargingSpeed chargingSpeed;
    if (chargingCurrent >= 2000) {
      chargingSpeed = ChargingSpeed.fast;
    } else if (chargingCurrent >= 1000) {
      chargingSpeed = ChargingSpeed.medium;
    } else if (chargingCurrent >= 500) {
      chargingSpeed = ChargingSpeed.slow;
    } else {
      chargingSpeed = ChargingSpeed.verySlow;
    }

    // 충전 효율성 분석
    ChargingEfficiency efficiency;
    if (temperature < 30) {
      efficiency = ChargingEfficiency.excellent;
    } else if (temperature < 40) {
      efficiency = ChargingEfficiency.good;
    } else if (temperature < 50) {
      efficiency = ChargingEfficiency.fair;
    } else {
      efficiency = ChargingEfficiency.poor;
    }

    // 예상 충전 완료 시간 계산 (대략적)
    Duration? estimatedTimeToFull;
    if (batteryInfo.isCharging && chargingCurrent > 0) {
      final remainingPercentage = 100.0 - currentLevel;
      final estimatedMinutes = (remainingPercentage * 60) / (chargingCurrent / 1000);
      estimatedTimeToFull = Duration(minutes: estimatedMinutes.round());
    }

    // 권장사항 생성
    List<String> recommendations = [];
    
    if (temperature > 45) {
      recommendations.add('배터리 온도가 높습니다. 충전을 일시 중단하세요');
    }
    
    if (chargingCurrent < 500) {
      recommendations.add('충전 속도가 느립니다. 고전력 충전기를 사용하세요');
    }
    
    if (currentLevel > 80) {
      recommendations.add('80% 이상 충전되었습니다. 과충전 방지를 위해 분리하세요');
    }

    return ChargingStatusAnalysis(
      isCharging: batteryInfo.isCharging,
      chargingSpeed: chargingSpeed,
      estimatedTimeToFull: estimatedTimeToFull,
      chargingEfficiency: efficiency,
      recommendations: recommendations,
    );
  }

  /// 충전 최적화 팁 생성
  static List<String> generateOptimizationTips(BatteryInfo? batteryInfo) {
    if (batteryInfo == null) {
      return ['배터리 정보를 확인하고 있습니다'];
    }

    List<String> tips = [];
    
    // 온도 기반 팁
    if (batteryInfo.temperature > 40) {
      tips.add('배터리 온도가 높습니다. 시원한 곳에서 충전하세요');
    } else if (batteryInfo.temperature < 20) {
      tips.add('배터리 온도가 낮습니다. 따뜻한 곳에서 충전하세요');
    }

    // 충전 전류 기반 팁
    final chargingCurrent = batteryInfo.chargingCurrent.abs();
    if (chargingCurrent < 500) {
      tips.add('충전 속도가 느립니다. 고전력 충전기를 사용하세요');
    } else if (chargingCurrent > 2000) {
      tips.add('초고속 충전 중입니다. 충전 완료 후 즉시 분리하세요');
    }

    // 배터리 레벨 기반 팁
    if (batteryInfo.level > 80) {
      tips.add('80% 이상 충전되었습니다. 과충전 방지를 위해 분리하세요');
    } else if (batteryInfo.level < 20) {
      tips.add('배터리가 부족합니다. 충전을 계속하세요');
    }

    // 충전 방식 기반 팁
    if (batteryInfo.chargingType == 'Wireless') {
      tips.add('무선 충전 중입니다. 충전 패드와의 거리를 확인하세요');
    } else if (batteryInfo.chargingType == 'USB') {
      tips.add('USB 충전 중입니다. 충전 속도가 느릴 수 있습니다');
    }

    return tips.isNotEmpty ? tips : ['충전이 정상적으로 진행되고 있습니다'];
  }
}

/// 충전 상태 분석 결과 모델
class ChargingStatusAnalysis {
  final bool isCharging;
  final ChargingSpeed chargingSpeed;
  final Duration? estimatedTimeToFull;
  final ChargingEfficiency chargingEfficiency;
  final List<String> recommendations;

  const ChargingStatusAnalysis({
    required this.isCharging,
    required this.chargingSpeed,
    this.estimatedTimeToFull,
    required this.chargingEfficiency,
    required this.recommendations,
  });
}

/// 충전 속도 열거형
enum ChargingSpeed {
  verySlow,
  slow,
  medium,
  fast,
  unknown,
}

/// 충전 효율성 열거형
enum ChargingEfficiency {
  excellent,
  good,
  fair,
  poor,
  unknown,
}

/// 충전 속도 정보 모델 (Phase 2 백업용)
class ChargingSpeedInfo {
  final String label; // 충전 속도 라벨 (예: "초고속 충전", "고속 충전", "저속 충전")
  final String description; // 충전 속도 설명 (예: "2.1A 충전 중")
  final Color color; // 충전 속도에 따른 색상
  final IconData icon; // 충전 속도에 따른 아이콘
  final List<String> tips; // 충전 최적화 팁 목록

  const ChargingSpeedInfo({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.tips,
  });

  @override
  String toString() {
    return 'ChargingSpeedInfo(label: $label, description: $description, color: $color, icon: $icon)';
  }
}