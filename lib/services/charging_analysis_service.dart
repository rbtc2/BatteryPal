import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/charging_models.dart';
import '../constants/charging_constants.dart';

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

    if (chargingCurrent >= ChargingConstants.ultraFastChargingThreshold) {
      // 초고속 충전 (2A 이상)
      speedLabel = ChargingConstants.ultraFastChargingLabel;
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = ChargingConstants.ultraFastChargingColor;
      icon = ChargingConstants.ultraFastChargingIcon;
      tips = ChargingConstants.ultraFastChargingTips;
    } else if (chargingCurrent >= ChargingConstants.fastChargingThreshold) {
      // 고속 충전 (1A ~ 2A)
      speedLabel = ChargingConstants.fastChargingLabel;
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = ChargingConstants.fastChargingColor;
      icon = ChargingConstants.fastChargingIcon;
      tips = ChargingConstants.fastChargingTips;
    } else if (chargingCurrent >= ChargingConstants.normalChargingThreshold) {
      // 일반 충전 (0.5A ~ 1A)
      speedLabel = ChargingConstants.normalChargingLabel;
      description = '${(chargingCurrent / 1000).toStringAsFixed(1)}A 충전 중';
      color = ChargingConstants.normalChargingColor;
      icon = ChargingConstants.normalChargingIcon;
      tips = ChargingConstants.normalChargingTips;
    } else {
      // 저속 충전 (0.5A 미만)
      speedLabel = ChargingConstants.slowChargingLabel;
      description = '${chargingCurrent}mA 충전 중';
      color = ChargingConstants.slowChargingColor;
      icon = ChargingConstants.slowChargingIcon;
      tips = ChargingConstants.slowChargingTips;
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
      label: ChargingConstants.unknownChargingLabel,
      description: '충전 정보 확인 중',
      color: ChargingConstants.unknownChargingColor,
      icon: ChargingConstants.unknownChargingIcon,
      tips: ChargingConstants.unknownChargingTips,
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
    if (chargingCurrent >= ChargingConstants.ultraFastChargingThreshold) {
      chargingSpeed = ChargingSpeed.fast;
    } else if (chargingCurrent >= ChargingConstants.fastChargingThreshold) {
      chargingSpeed = ChargingSpeed.medium;
    } else if (chargingCurrent >= ChargingConstants.normalChargingThreshold) {
      chargingSpeed = ChargingSpeed.slow;
    } else {
      chargingSpeed = ChargingSpeed.verySlow;
    }

    // 충전 효율성 분석
    ChargingEfficiency efficiency;
    if (temperature < ChargingConstants.excellentEfficiencyThreshold) {
      efficiency = ChargingEfficiency.excellent;
    } else if (temperature < ChargingConstants.goodEfficiencyThreshold) {
      efficiency = ChargingEfficiency.good;
    } else if (temperature < ChargingConstants.fairEfficiencyThreshold) {
      efficiency = ChargingEfficiency.fair;
    } else {
      efficiency = ChargingEfficiency.poor;
    }

    // 예상 충전 완료 시간 계산 (개선된 알고리즘)
    Duration? estimatedTimeToFull;
    if (batteryInfo.isCharging && chargingCurrent > 0) {
      final remainingPercentage = 100.0 - currentLevel;
      
      // 배터리 용량과 충전 효율성을 고려한 계산
      // 일반적인 스마트폰 배터리 용량: 3000-5000mAh
      // 충전 효율성: 80-90% (열 손실, 회로 손실 등)
      const double batteryCapacity = ChargingConstants.defaultBatteryCapacity;
      const double chargingEfficiency = ChargingConstants.chargingEfficiency;
      
      // 실제 충전 속도 계산 (효율성 고려)
      final effectiveChargingRate = (chargingCurrent * chargingEfficiency) / batteryCapacity;
      
      // 남은 충전 시간 계산 (분 단위)
      final estimatedMinutes = remainingPercentage / (effectiveChargingRate * 100);
      
      // 최소 1분, 최대 24시간으로 제한
      final clampedMinutes = estimatedMinutes.clamp(
        ChargingConstants.minEstimatedMinutes.toDouble(), 
        ChargingConstants.maxEstimatedMinutes.toDouble()
      );
      
      estimatedTimeToFull = Duration(minutes: clampedMinutes.round());
      
      debugPrint('ChargingAnalysisService: 충전 예상 시간 계산 - '
          '현재: $currentLevel%, 남은: $remainingPercentage%, '
          '충전전류: ${chargingCurrent}mA, 예상시간: $clampedMinutes.round()분');
    }

    // 권장사항 생성
    List<String> recommendations = [];
    
    if (temperature > ChargingConstants.criticalTemperatureThreshold) {
      recommendations.add('배터리 온도가 높습니다. 충전을 일시 중단하세요');
    }
    
    if (chargingCurrent < ChargingConstants.normalChargingThreshold) {
      recommendations.add('충전 속도가 느립니다. 고전력 충전기를 사용하세요');
    }
    
    if (currentLevel > ChargingConstants.highBatteryThreshold) {
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
    if (batteryInfo.temperature > ChargingConstants.highTemperatureThreshold) {
      tips.add('배터리 온도가 높습니다. 시원한 곳에서 충전하세요');
    } else if (batteryInfo.temperature < ChargingConstants.lowTemperatureThreshold) {
      tips.add('배터리 온도가 낮습니다. 따뜻한 곳에서 충전하세요');
    }

    // 충전 전류 기반 팁
    final chargingCurrent = batteryInfo.chargingCurrent.abs();
    if (chargingCurrent < ChargingConstants.normalChargingThreshold) {
      tips.add('충전 속도가 느립니다. 고전력 충전기를 사용하세요');
    } else if (chargingCurrent > ChargingConstants.ultraFastChargingThreshold) {
      tips.add('초고속 충전 중입니다. 충전 완료 후 즉시 분리하세요');
    }

    // 배터리 레벨 기반 팁
    if (batteryInfo.level > ChargingConstants.highBatteryThreshold) {
      tips.add('80% 이상 충전되었습니다. 과충전 방지를 위해 분리하세요');
    } else if (batteryInfo.level < ChargingConstants.lowBatteryThreshold) {
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
