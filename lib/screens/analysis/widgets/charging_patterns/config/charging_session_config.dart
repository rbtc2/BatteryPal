// 충전 세션 기록 관련 상수 정의

/// 충전 세션 기록 설정 상수
class ChargingSessionConfig {
  ChargingSessionConfig._(); // private constructor (정적 클래스)

  // ==================== 세션 감지 관련 상수 ====================

  /// 최소 충전 시간 (분)
  /// 5분 이상 충전한 세션만 기록
  static const int minChargingDurationMinutes = 5;

  /// 최소 충전 시간 (Duration)
  static const Duration minChargingDuration = Duration(minutes: minChargingDurationMinutes);

  /// 최소 유의미한 전류 (mA)
  /// 평균 전류가 100mA 이상인 세션만 기록
  static const int minSignificantCurrentMa = 100;

  /// 세션 종료 대기 시간 (초)
  /// 전류가 0으로 떨어진 후 30초 이상 유지되면 세션 종료로 판단
  static const int sessionEndWaitSeconds = 30;

  /// 세션 종료 대기 시간 (Duration)
  static const Duration sessionEndWaitDuration = Duration(seconds: sessionEndWaitSeconds);

  // ==================== 전류 분류 관련 상수 ====================

  /// 저속 충전 임계값 (mA)
  /// 0 ~ 500mA: 저속 충전
  static const int slowChargingThresholdMa = 500;

  /// 일반 충전 임계값 (mA)
  /// 500 ~ 1500mA: 일반 충전
  static const int normalChargingThresholdMa = 1500;

  /// 1500mA 이상: 급속 충전
  /// (별도 상수 없음, normalChargingThresholdMa 초과)

  // ==================== 전류 변화 감지 관련 상수 ====================

  /// 전류 변화 감지 임계값 (mA)
  /// 전류가 이 값 이상 변하면 변화 이벤트로 기록
  static const int currentChangeThresholdMa = 200;

  /// 전류 변화 감지 비율 (%)
  /// 현재 전류의 이 비율 이상 변하면 변화 이벤트로 기록
  /// (예: 500mA에서 20% 변화 = 100mA 이상 변화)
  static const double currentChangeThresholdPercent = 20.0;

  // ==================== 효율 계산 관련 상수 ====================

  /// 기본 배터리 전압 (mV)
  /// 전압 정보가 없을 때 사용하는 기본값
  /// 일반적인 리튬이온 배터리: 3.7V = 3700mV
  static const int defaultBatteryVoltageMv = 3700;

  /// 효율 계산 시 사용할 기본 전압 (V)
  static const double defaultBatteryVoltageV = 3.7;

  /// 효율 우수 기준 (%)
  /// 90% 이상: 우수 (녹색)
  static const double efficiencyExcellentThreshold = 90.0;

  /// 효율 양호 기준 (%)
  /// 80% 이상: 양호 (주황색)
  static const double efficiencyGoodThreshold = 80.0;

  /// 효율 보통 기준 (%)
  /// 70% 이상: 보통 (노란색)
  static const double efficiencyFairThreshold = 70.0;

  /// 70% 미만: 낮음 (빨간색)

  // ==================== 데이터 수집 관련 상수 ====================

  /// 세션 데이터 수집 간격 (초)
  /// 충전 중 데이터를 수집하는 주기
  static const int dataCollectionIntervalSeconds = 10;

  /// 세션 데이터 수집 간격 (Duration)
  static const Duration dataCollectionInterval = Duration(seconds: dataCollectionIntervalSeconds);

  /// 배터리 레벨 변화 감지 임계값 (%)
  /// 이 값 이상 변화하면 배터리 레벨 변화로 기록
  static const double batteryLevelChangeThreshold = 1.0;

  // ==================== 데이터 저장 관련 상수 ====================

  /// 세션 데이터 보관 기간 (일)
  /// 7일 이상 된 세션 데이터는 자동 삭제
  static const int sessionRetentionDays = 7;

  /// 세션 데이터 보관 기간 (Duration)
  static const Duration sessionRetentionDuration = Duration(days: sessionRetentionDays);

  // ==================== 유효성 검증 관련 상수 ====================

  /// 최소 배터리 변화량 (%)
  /// 세션이 유효하려면 최소 1% 이상 배터리가 증가해야 함
  static const double minBatteryChangePercent = 1.0;

  /// 최대 배터리 레벨 (%)
  static const double maxBatteryLevel = 100.0;

  /// 최소 배터리 레벨 (%)
  static const double minBatteryLevel = 0.0;

  /// 최대 효율 (%)
  static const double maxEfficiency = 100.0;

  /// 최소 효율 (%)
  static const double minEfficiency = 0.0;

  // ==================== UI 표시 관련 상수 ====================

  /// 세션 제목 최대 길이 (문자)
  static const int maxSessionTitleLength = 20;

  /// 전류 변화 이력 최대 개수
  /// 한 세션에 기록할 최대 전류 변화 이벤트 수
  static const int maxSpeedChangeEvents = 10;

  // ==================== 유틸리티 메서드 ====================

  /// 전류값을 충전 속도 타입으로 분류
  /// 
  /// 반환:
  /// - "저속": 0 ~ 500mA
  /// - "일반": 500 ~ 1500mA
  /// - "급속": 1500mA 이상
  static String getChargingSpeedType(int currentMa) {
    if (currentMa < slowChargingThresholdMa) {
      return '저속';
    } else if (currentMa < normalChargingThresholdMa) {
      return '일반';
    } else {
      return '급속';
    }
  }

  /// 전류값이 저속 충전인지 확인
  static bool isSlowCharging(int currentMa) {
    return currentMa < slowChargingThresholdMa && currentMa > 0;
  }

  /// 전류값이 일반 충전인지 확인
  static bool isNormalCharging(int currentMa) {
    return currentMa >= slowChargingThresholdMa && currentMa < normalChargingThresholdMa;
  }

  /// 전류값이 급속 충전인지 확인
  static bool isFastCharging(int currentMa) {
    return currentMa >= normalChargingThresholdMa;
  }

  /// 효율 등급 반환
  /// 
  /// 반환:
  /// - "우수": 90% 이상
  /// - "양호": 80% 이상
  /// - "보통": 70% 이상
  /// - "낮음": 70% 미만
  static String getEfficiencyGrade(double efficiency) {
    if (efficiency >= efficiencyExcellentThreshold) {
      return '우수';
    } else if (efficiency >= efficiencyGoodThreshold) {
      return '양호';
    } else if (efficiency >= efficiencyFairThreshold) {
      return '보통';
    } else {
      return '낮음';
    }
  }

  /// 효율이 우수한지 확인
  static bool isEfficiencyExcellent(double efficiency) {
    return efficiency >= efficiencyExcellentThreshold;
  }

  /// 효율이 양호한지 확인
  static bool isEfficiencyGood(double efficiency) {
    return efficiency >= efficiencyGoodThreshold && efficiency < efficiencyExcellentThreshold;
  }

  /// 효율이 보통인지 확인
  static bool isEfficiencyFair(double efficiency) {
    return efficiency >= efficiencyFairThreshold && efficiency < efficiencyGoodThreshold;
  }

  /// 효율이 낮은지 확인
  static bool isEfficiencyLow(double efficiency) {
    return efficiency < efficiencyFairThreshold;
  }

  /// 전류 변화가 유의미한지 확인
  /// 
  /// [previousCurrent] 이전 전류값 (mA)
  /// [newCurrent] 새로운 전류값 (mA)
  /// 
  /// 반환: 변화가 유의미하면 true
  static bool isSignificantCurrentChange(int previousCurrent, int newCurrent) {
    if (previousCurrent == 0 || newCurrent == 0) {
      // 0에서 변화하거나 0으로 변화하는 경우는 항상 유의미
      return true;
    }

    // 절대값 변화 확인
    final absoluteChange = (newCurrent - previousCurrent).abs();
    if (absoluteChange >= currentChangeThresholdMa) {
      return true;
    }

    // 비율 변화 확인
    final percentChange = (absoluteChange / previousCurrent) * 100;
    if (percentChange >= currentChangeThresholdPercent) {
      return true;
    }

    return false;
  }

  /// 세션이 유효한지 확인
  /// 
  /// [duration] 충전 시간
  /// [avgCurrent] 평균 전류 (mA)
  /// [batteryChange] 배터리 변화량 (%)
  /// 
  /// 반환: 세션이 유효하면 true
  static bool isValidSession({
    required Duration duration,
    required double avgCurrent,
    required double batteryChange,
  }) {
    // 최소 충전 시간 확인
    if (duration < minChargingDuration) {
      return false;
    }

    // 최소 유의미한 전류 확인
    if (avgCurrent < minSignificantCurrentMa) {
      return false;
    }

    // 최소 배터리 변화량 확인
    if (batteryChange < minBatteryChangePercent) {
      return false;
    }

    return true;
  }
}

