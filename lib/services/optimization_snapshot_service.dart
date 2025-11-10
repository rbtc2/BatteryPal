import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 최적화 설정 스냅샷을 관리하는 서비스
/// 자동 최적화 항목의 상태를 저장하고 복원하는 기능 제공
class OptimizationSnapshotService {
  static const String _keyPrefix = 'optimization_snapshot_';
  static const String _autoOptimizationKey = '${_keyPrefix}auto_optimization';
  static const String _savedAtKey = '${_keyPrefix}saved_at';

  /// 자동 최적화 항목의 현재 상태를 저장
  /// 
  /// [states]는 항목 ID를 키로, 활성화 여부를 값으로 하는 Map
  /// 예: {'background_apps': true, 'memory_clean': false, ...}
  Future<bool> saveAutoOptimizationSnapshot(Map<String, bool> states) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 각 항목의 상태를 개별적으로 저장
      for (final entry in states.entries) {
        await prefs.setBool('${_autoOptimizationKey}_${entry.key}', entry.value);
      }
      
      // 저장된 항목 ID 목록 저장 (복원 시 어떤 항목들이 저장되었는지 알기 위해)
      await prefs.setStringList(
        '${_autoOptimizationKey}_items',
        states.keys.toList(),
      );
      
      // 저장 시간 기록
      await prefs.setString(_savedAtKey, DateTime.now().toIso8601String());
      
      debugPrint('자동 최적화 스냅샷 저장 완료: ${states.length}개 항목');
      return true;
    } catch (e) {
      debugPrint('자동 최적화 스냅샷 저장 실패: $e');
      return false;
    }
  }

  /// 저장된 자동 최적화 항목 상태를 불러오기
  /// 
  /// 저장된 스냅샷이 없으면 null 반환
  Future<Map<String, bool>?> loadAutoOptimizationSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 항목 ID 목록 불러오기
      final itemIds = prefs.getStringList('${_autoOptimizationKey}_items');
      if (itemIds == null || itemIds.isEmpty) {
        debugPrint('저장된 자동 최적화 스냅샷이 없습니다');
        return null;
      }
      
      // 각 항목의 상태 불러오기
      final Map<String, bool> states = {};
      for (final itemId in itemIds) {
        final value = prefs.getBool('${_autoOptimizationKey}_$itemId');
        if (value != null) {
          states[itemId] = value;
        }
      }
      
      if (states.isEmpty) {
        debugPrint('저장된 자동 최적화 스냅샷이 비어있습니다');
        return null;
      }
      
      debugPrint('자동 최적화 스냅샷 불러오기 완료: ${states.length}개 항목');
      return states;
    } catch (e) {
      debugPrint('자동 최적화 스냅샷 불러오기 실패: $e');
      return null;
    }
  }

  /// 저장된 스냅샷이 있는지 확인
  Future<bool> hasAutoOptimizationSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemIds = prefs.getStringList('${_autoOptimizationKey}_items');
      return itemIds != null && itemIds.isNotEmpty;
    } catch (e) {
      debugPrint('스냅샷 존재 여부 확인 실패: $e');
      return false;
    }
  }

  /// 저장된 스냅샷의 저장 시간 가져오기
  Future<DateTime?> getSavedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAtString = prefs.getString(_savedAtKey);
      if (savedAtString == null) {
        return null;
      }
      return DateTime.parse(savedAtString);
    } catch (e) {
      debugPrint('저장 시간 불러오기 실패: $e');
      return null;
    }
  }

  /// 저장된 스냅샷 삭제
  Future<bool> clearAutoOptimizationSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 항목 ID 목록 불러오기
      final itemIds = prefs.getStringList('${_autoOptimizationKey}_items');
      if (itemIds != null) {
        // 각 항목의 상태 삭제
        for (final itemId in itemIds) {
          await prefs.remove('${_autoOptimizationKey}_$itemId');
        }
        await prefs.remove('${_autoOptimizationKey}_items');
      }
      
      // 저장 시간 삭제
      await prefs.remove(_savedAtKey);
      
      debugPrint('자동 최적화 스냅샷 삭제 완료');
      return true;
    } catch (e) {
      debugPrint('자동 최적화 스냅샷 삭제 실패: $e');
      return false;
    }
  }

  // ========== 수동 설정 항목 이전 값 저장/불러오기 ==========

  static const String _manualSettingKey = '${_keyPrefix}manual_setting';

  /// 수동 설정 항목의 이전 값 저장
  /// 
  /// [itemId]는 항목 ID (예: 'battery_saver', 'network_optimize' 등)
  /// [previousValue]는 이전 값 문자열 (예: '밝기 80%', 'Wi-Fi' 등)
  Future<bool> saveManualSettingPreviousValue(String itemId, String previousValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_manualSettingKey}_$itemId', previousValue);
      debugPrint('수동 설정 이전 값 저장 완료: $itemId = $previousValue');
      return true;
    } catch (e) {
      debugPrint('수동 설정 이전 값 저장 실패: $e');
      return false;
    }
  }

  /// 수동 설정 항목의 이전 값 불러오기
  /// 
  /// 저장된 값이 없으면 null 반환
  Future<String?> getManualSettingPreviousValue(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('${_manualSettingKey}_$itemId');
      if (value != null) {
        debugPrint('수동 설정 이전 값 불러오기 완료: $itemId = $value');
      }
      return value;
    } catch (e) {
      debugPrint('수동 설정 이전 값 불러오기 실패: $e');
      return null;
    }
  }

  /// 수동 설정 항목의 이전 값 삭제
  Future<bool> clearManualSettingPreviousValue(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_manualSettingKey}_$itemId');
      debugPrint('수동 설정 이전 값 삭제 완료: $itemId');
      return true;
    } catch (e) {
      debugPrint('수동 설정 이전 값 삭제 실패: $e');
      return false;
    }
  }
}

