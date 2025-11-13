import 'package:flutter/foundation.dart';
import '../models/battery_history_models.dart';
import '../services/battery_history_service.dart';
import '../services/native_battery_service.dart';

/// 방전 전류 계산 서비스
/// 
/// 특정 날짜의 총 방전 전류(mAh)를 계산합니다.
/// BatteryHistoryDataPoint의 레벨 변화를 기반으로 계산합니다.
class DischargeCurrentCalculator {
  static final DischargeCurrentCalculator _instance = 
      DischargeCurrentCalculator._internal();
  factory DischargeCurrentCalculator() => _instance;
  DischargeCurrentCalculator._internal();

  final BatteryHistoryService _batteryHistoryService = BatteryHistoryService();
  
  /// 특정 날짜의 총 방전 전류(mAh) 계산
  /// 
  /// [targetDate]: 계산할 날짜
  /// 
  /// Returns: 총 방전 전류 (mAh), 계산 실패 시 -1
  Future<int> calculateDischargeCurrentForDate(DateTime targetDate) async {
    try {
      debugPrint('방전 전류 계산 시작: ${targetDate.toString().split(' ')[0]}');
      
      // 날짜 범위 설정 (00:00:00 ~ 23:59:59)
      final startTime = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endTime = startTime.add(const Duration(days: 1));
      
      // 해당 날짜의 배터리 히스토리 데이터 가져오기
      final historyData = await _batteryHistoryService.getBatteryHistoryData(
        startTime: startTime,
        endTime: endTime,
      );
      
      if (historyData.isEmpty) {
        debugPrint('방전 전류 계산: 데이터가 없음');
        return -1;
      }
      
      // 방전 구간만 필터링 (isCharging == false)
      final dischargeData = historyData
          .where((point) => !point.isCharging)
          .toList();
      
      if (dischargeData.isEmpty) {
        debugPrint('방전 전류 계산: 방전 구간이 없음');
        return 0; // 방전이 없었으면 0 mAh
      }
      
      // 배터리 용량 가져오기
      int batteryCapacity = await _getBatteryCapacity(dischargeData);
      
      if (batteryCapacity <= 0) {
        debugPrint('방전 전류 계산: 배터리 용량을 가져올 수 없음');
        return -1;
      }
      
      // 방전 전류 누적 계산
      int totalDischargeCurrent = 0;
      
      for (int i = 0; i < dischargeData.length - 1; i++) {
        final current = dischargeData[i];
        final next = dischargeData[i + 1];
        
        // 레벨 차이 (%)
        final levelDiff = current.level - next.level;
        
        // 레벨이 감소한 경우만 계산 (방전)
        if (levelDiff > 0) {
          // 시간 차이 (초)
          final timeDiff = next.timestamp.difference(current.timestamp).inSeconds;
          
          // mAh 계산: (레벨 차이 / 100) * 배터리 용량
          final mAh = (levelDiff / 100.0) * batteryCapacity;
          
          totalDischargeCurrent += mAh.round();
          
          debugPrint('방전 구간: ${current.level.toStringAsFixed(1)}% → ${next.level.toStringAsFixed(1)}% '
              '(${levelDiff.toStringAsFixed(1)}%, $timeDiff초, ${mAh.round()}mAh)');
        }
      }
      
      debugPrint('방전 전류 계산 완료: ${totalDischargeCurrent}mAh');
      return totalDischargeCurrent;
      
    } catch (e, stackTrace) {
      debugPrint('방전 전류 계산 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return -1;
    }
  }
  
  /// 배터리 용량 가져오기
  /// 
  /// 먼저 히스토리 데이터에서 용량을 찾고, 없으면 Native API에서 가져옵니다.
  Future<int> _getBatteryCapacity(List<BatteryHistoryDataPoint> dischargeData) async {
    // 히스토리 데이터에서 유효한 용량 찾기
    for (final point in dischargeData) {
      if (point.hasCapacity && point.capacity > 0) {
        return point.capacity;
      }
    }
    
    // 히스토리 데이터에 용량이 없으면 Native API에서 가져오기
    try {
      final capacity = await NativeBatteryService.getBatteryCapacity();
      if (capacity > 0) {
        return capacity;
      }
    } catch (e) {
      debugPrint('Native API에서 배터리 용량 가져오기 실패: $e');
    }
    
    return -1;
  }
}

