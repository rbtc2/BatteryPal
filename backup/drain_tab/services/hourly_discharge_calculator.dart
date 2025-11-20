import 'package:flutter/foundation.dart';
// 백업 파일: 원본 프로젝트의 package 경로 사용
import 'package:batterypal/models/battery_history_models.dart';
import 'package:batterypal/services/battery_history_service.dart';

/// 시간대별 방전 소모량 계산 서비스
/// 
/// 특정 날짜의 시간대별 방전 소모량(%)을 계산합니다.
/// 그래프 표시를 위해 2시간 간격(0, 2, 4, ..., 22시)으로 집계합니다.
class HourlyDischargeCalculator {
  static final HourlyDischargeCalculator _instance = 
      HourlyDischargeCalculator._internal();
  factory HourlyDischargeCalculator() => _instance;
  HourlyDischargeCalculator._internal();

  final BatteryHistoryService _batteryHistoryService = BatteryHistoryService();
  
  /// 시간대별 소모량을 계산할 시간대 목록 (2시간 간격)
  static const List<int> _hourSlots = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];
  
  /// 특정 날짜의 시간대별 방전 소모량(%) 계산
  /// 
  /// [targetDate]: 계산할 날짜
  /// 
  /// Returns: 시간대별 소모량 Map (시간대 → 소모량 %)
  /// 예: {0: 1.2, 2: 0.8, 4: 0.5, ...}
  /// 계산 실패 시 빈 Map 반환
  Future<Map<int, double>> calculateHourlyDischargeForDate(DateTime targetDate) async {
    try {
      debugPrint('시간대별 방전 소모량 계산 시작: ${targetDate.toString().split(' ')[0]}');
      
      // 날짜 범위 설정 (00:00:00 ~ 23:59:59)
      final startTime = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endTime = startTime.add(const Duration(days: 1));
      
      // 해당 날짜의 배터리 히스토리 데이터 가져오기
      final historyData = await _batteryHistoryService.getBatteryHistoryData(
        startTime: startTime,
        endTime: endTime,
      );
      
      if (historyData.isEmpty) {
        debugPrint('시간대별 방전 소모량 계산: 데이터가 없음');
        return _createEmptyHourlyMap();
      }
      
      // 방전 구간만 필터링 (isCharging == false)
      // 유효한 레벨을 가진 데이터만 사용
      final dischargeData = historyData
          .where((point) => !point.isCharging && point.isValidLevel)
          .toList();
      
      if (dischargeData.isEmpty) {
        debugPrint('시간대별 방전 소모량 계산: 방전 구간이 없음');
        return _createEmptyHourlyMap();
      }
      
      // 타임스탬프로 정렬 (시간순)
      dischargeData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('시간대별 방전 소모량 계산: 방전 데이터 포인트 ${dischargeData.length}개');
      
      // 시간대별 소모량 계산
      // 배터리 레벨이 이미 % 단위이므로 용량 없이도 계산 가능
      final hourlyDischarge = <int, double>{};
      
      for (final hour in _hourSlots) {
        final dischargePercent = _calculateDischargeForHourSlot(
          dischargeData,
          targetDate,
          hour,
        );
        hourlyDischarge[hour] = dischargePercent;
      }
      
      debugPrint('시간대별 방전 소모량 계산 완료: $hourlyDischarge');
      return hourlyDischarge;
      
    } catch (e, stackTrace) {
      debugPrint('시간대별 방전 소모량 계산 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return {};
    }
  }
  
  /// 특정 시간대 슬롯의 방전 소모량(%) 계산
  /// 
  /// [dischargeData]: 방전 구간 데이터
  /// [targetDate]: 대상 날짜
  /// [hour]: 시간대 (0, 2, 4, ..., 22)
  /// 
  /// Returns: 해당 시간대의 소모량 (%)
  /// 배터리 레벨이 이미 % 단위이므로 레벨 차이를 직접 계산합니다.
  double _calculateDischargeForHourSlot(
    List<BatteryHistoryDataPoint> dischargeData,
    DateTime targetDate,
    int hour,
  ) {
    // 시간대 범위 설정 (2시간 구간)
    // 예: 0시 슬롯 = 00:00:00 ~ 01:59:59
    //     2시 슬롯 = 02:00:00 ~ 03:59:59
    final slotStart = DateTime(targetDate.year, targetDate.month, targetDate.day, hour);
    final slotEnd = slotStart.add(const Duration(hours: 2));
    
    // 해당 시간대 구간의 데이터 필터링
    final slotData = dischargeData.where((point) {
      // 타임스탬프가 시간대 범위 내에 있는지 확인
      return point.timestamp.isAfter(slotStart.subtract(const Duration(milliseconds: 1))) &&
             point.timestamp.isBefore(slotEnd);
    }).toList();
    
    if (slotData.isEmpty || slotData.length < 2) {
      return 0.0;
    }
    
    // 타임스탬프로 정렬 (시간순)
    slotData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 유효한 레벨 범위 확인
    final validData = slotData.where((point) => point.isValidLevel).toList();
    
    if (validData.length < 2) {
      return 0.0;
    }
    
    // 시간대 내 방전량 누적 계산
    double totalDischargePercent = 0.0;
    
    for (int i = 0; i < validData.length - 1; i++) {
      final current = validData[i];
      final next = validData[i + 1];
      
      // 레벨 차이 (%)
      final levelDiff = current.level - next.level;
      
      // 레벨이 감소한 경우만 계산 (방전)
      // 비정상적으로 큰 변화는 제외 (예: 50% 이상 변화는 데이터 오류로 간주)
      if (levelDiff > 0 && levelDiff <= 50.0) {
        totalDischargePercent += levelDiff;
      } else if (levelDiff > 50.0) {
        // 비정상적으로 큰 변화는 로그만 남기고 무시
        debugPrint('시간대 $hour시: 비정상적인 레벨 변화 감지 (${current.level}% → ${next.level}%), 무시됨');
      }
    }
    
    debugPrint('시간대 $hour시 소모량: ${totalDischargePercent.toStringAsFixed(2)}% (데이터 포인트: ${validData.length}개)');
    return totalDischargePercent;
  }
  
  /// 빈 시간대별 Map 생성 (모든 시간대를 0.0으로 초기화)
  Map<int, double> _createEmptyHourlyMap() {
    final map = <int, double>{};
    for (final hour in _hourSlots) {
      map[hour] = 0.0;
    }
    return map;
  }
  
  
  /// 시간대별 소모 속도(%/h) 계산
  /// 
  /// [hourlyDischarge]: 시간대별 소모량 Map
  /// 
  /// Returns: 시간대별 소모 속도 Map (시간대 → 소모 속도 %/h)
  Map<int, double> calculateHourlyDischargeRate(Map<int, double> hourlyDischarge) {
    final hourlyRate = <int, double>{};
    
    for (final hour in _hourSlots) {
      final discharge = hourlyDischarge[hour] ?? 0.0;
      // 2시간 구간이므로 시간당 소모량 = 소모량 / 2
      hourlyRate[hour] = discharge / 2.0;
    }
    
    return hourlyRate;
  }
  
  /// 피크 시간대 정보 가져오기
  /// 
  /// [hourlyDischarge]: 시간대별 소모량 Map
  /// 
  /// Returns: 피크 시간대 정보 (시간대, 소모량, 소모 속도)
  /// 피크가 없으면 null 반환
  ({int hour, double discharge, double rate})? getPeakHour(Map<int, double> hourlyDischarge) {
    if (hourlyDischarge.isEmpty) {
      return null;
    }
    
    int? peakHour;
    double maxDischarge = 0.0;
    
    for (final entry in hourlyDischarge.entries) {
      if (entry.value > maxDischarge) {
        maxDischarge = entry.value;
        peakHour = entry.key;
      }
    }
    
    if (peakHour == null || maxDischarge == 0.0) {
      return null;
    }
    
    final rate = maxDischarge / 2.0; // 2시간 구간이므로
    
    return (
      hour: peakHour,
      discharge: maxDischarge,
      rate: rate,
    );
  }
}

