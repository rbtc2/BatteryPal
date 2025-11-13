import 'package:flutter/material.dart';
import '../models/models.dart';
import '../constants/charging_constants.dart';
import 'battery_service.dart';

/// 충전 예상 시간 안정화 클래스
/// 충전 예상 시간의 급격한 변화를 방지하여 부드러운 사용자 경험 제공
class ChargingTimeStabilizer {
  static final List<Duration> _recentEstimates = [];
  static Duration? _lastStableEstimate;
  
  /// 안정화된 충전 예상 시간 반환
  static Duration? getStabilizedEstimatedTime(Duration? currentEstimate) {
    if (currentEstimate == null) return null;
    
    // 첫 번째 측정값이거나 충분한 데이터가 없는 경우
    if (_recentEstimates.isEmpty || _recentEstimates.length < ChargingConstants.minStableMeasurements) {
      _recentEstimates.add(currentEstimate);
      _lastStableEstimate = currentEstimate;
      return currentEstimate;
    }
    
    // 급격한 변화 감지 및 제한
    final stabilizedEstimate = _applyGradualChange(currentEstimate);
    
    // 최근 측정값 목록 업데이트
    _recentEstimates.add(stabilizedEstimate);
    if (_recentEstimates.length > ChargingConstants.chargingTimeStabilizationWindow) {
      _recentEstimates.removeAt(0);
    }
    
    _lastStableEstimate = stabilizedEstimate;
    return stabilizedEstimate;
  }
  
  /// 급격한 변화를 방지하고 점진적 변화 적용
  static Duration _applyGradualChange(Duration currentEstimate) {
    if (_lastStableEstimate == null) return currentEstimate;
    
    final currentMinutes = currentEstimate.inMinutes;
    final lastMinutes = _lastStableEstimate!.inMinutes;
    
    // 변화 비율 계산
    final changeRatio = (currentMinutes - lastMinutes).abs() / lastMinutes;
    
    // 급격한 변화인 경우 점진적 변화 적용
    if (changeRatio > ChargingConstants.maxTimeChangeRatio) {
      final maxChange = (lastMinutes * ChargingConstants.maxTimeChangeRatio).round();
      final direction = currentMinutes > lastMinutes ? 1 : -1;
      final adjustedMinutes = lastMinutes + (maxChange * direction);
      
      debugPrint('ChargingTimeStabilizer: 급격한 변화 감지 - '
          '이전: $lastMinutes분, 현재: $currentMinutes분, '
          '조정후: $adjustedMinutes분');
      
      return Duration(minutes: adjustedMinutes);
    }
    
    return currentEstimate;
  }
  
  /// 안정화 상태 초기화 (충전 시작/종료 시)
  static void reset() {
    _recentEstimates.clear();
    _lastStableEstimate = null;
    debugPrint('ChargingTimeStabilizer: 안정화 상태 초기화');
  }
}

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
      // 충전 상태가 없으면 안정화 상태 초기화
      ChargingTimeStabilizer.reset();
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

    // 예상 충전 완료 시간 계산 (안정화된 알고리즘)
    Duration? estimatedTimeToFull;
    if (batteryInfo.isCharging) {
      final remainingPercentage = 100.0 - currentLevel;
      
      // 안정화된 충전 전류 사용 (요동 방지)
      final batteryService = BatteryService();
      final stableChargingCurrent = batteryService.getStableChargingCurrent();
      final isStable = batteryService.isChargingCurrentStable();
      
      // 안정화된 데이터가 충분하지 않으면 현재 값 사용
      final effectiveChargingCurrent = stableChargingCurrent > 0 ? stableChargingCurrent : chargingCurrent;
      
      if (effectiveChargingCurrent > 0) {
        // 배터리 용량과 충전 효율성을 고려한 계산
        const double batteryCapacity = ChargingConstants.defaultBatteryCapacity; // mAh
        const double chargingEfficiency = ChargingConstants.chargingEfficiency;
        
        // 실제 충전 속도 계산 (시간당 퍼센트)
        final chargingRatePerHour = (effectiveChargingCurrent * chargingEfficiency) / batteryCapacity;
        
        // 남은 충전 시간 계산 (시간 단위)
        final estimatedHours = remainingPercentage / (chargingRatePerHour * 100);
        
        // 분 단위로 변환하고 제한
        final estimatedMinutes = estimatedHours * 60;
        final clampedMinutes = estimatedMinutes.clamp(
          ChargingConstants.minEstimatedMinutes.toDouble(), 
          ChargingConstants.maxEstimatedMinutes.toDouble()
        );
        
        final rawEstimatedTime = Duration(minutes: clampedMinutes.round());
        
        // 충전 예상 시간 안정화 적용
        estimatedTimeToFull = ChargingTimeStabilizer.getStabilizedEstimatedTime(rawEstimatedTime);
        
        debugPrint('ChargingAnalysisService: 안정화된 충전 예상 시간 계산 - '
            '현재: $currentLevel%, 남은: $remainingPercentage%, '
            '원본전류: ${chargingCurrent}mA, 안정화전류: ${effectiveChargingCurrent}mA, '
            '안정성: $isStable, 충전속도: ${(chargingRatePerHour * 100).toStringAsFixed(1)}%/시간, '
            '원본예상시간: ${clampedMinutes.round()}분, 최종예상시간: ${estimatedTimeToFull?.inMinutes}분');
      }
    } else {
      // 충전이 중단되었으면 안정화 상태 초기화
      ChargingTimeStabilizer.reset();
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
