import 'package:flutter/material.dart';
import 'system_settings_service.dart';

/// Phase 3: 배터리 최적화 예외 처리 헬퍼
/// 
/// 사용자에게 배터리 최적화 예외 설정을 안내하고,
/// 설정 화면으로 이동할 수 있도록 도와줍니다.
class BatteryOptimizationHelper {
  static final SystemSettingsService _settingsService = SystemSettingsService();

  /// 배터리 최적화 예외 여부 확인
  /// 
  /// Returns: 배터리 최적화에서 제외되었으면 true, 그렇지 않으면 false
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _settingsService.isIgnoringBatteryOptimizations();
      return result ?? false;
    } catch (e) {
      debugPrint('배터리 최적화 예외 확인 실패: $e');
      return false;
    }
  }

  /// 배터리 최적화 설정 화면으로 이동
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _settingsService.openBatteryOptimizationSettings();
    } catch (e) {
      debugPrint('배터리 최적화 설정 화면 열기 실패: $e');
    }
  }

  /// 배터리 최적화 예외 설정 안내 다이얼로그 표시
  /// 
  /// [context] BuildContext
  /// [showDialogPrompt] 다이얼로그를 표시할지 여부 (기본값: true)
  /// 
  /// Returns: 사용자가 설정 화면으로 이동하기로 했으면 true
  static Future<bool> requestBatteryOptimizationException(
    BuildContext context, {
    bool showDialogPrompt = true,
  }) async {
    // 이미 예외 설정되어 있으면 true 반환
    final isIgnoring = await isIgnoringBatteryOptimizations();
    if (isIgnoring) {
      debugPrint('배터리 최적화 예외가 이미 설정되어 있습니다');
      return true;
    }

    if (!showDialogPrompt) {
      // 다이얼로그를 표시하지 않고 바로 설정 화면으로 이동
      await openBatteryOptimizationSettings();
      return false; // 사용자가 돌아온 후 다시 확인 필요
    }

    // 권한이 없으면 다이얼로그 표시
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.battery_saver_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('배터리 최적화 예외 필요'),
          ],
        ),
        content: const Text(
          '앱이 꺼져 있을 때도 충전 데이터를 수집하려면\n'
          '배터리 최적화에서 제외해야 합니다.\n\n'
          '배터리 최적화 설정 화면에서\n'
          '이 앱을 "최적화 안 함"으로 설정해주세요.\n\n'
          '설정 화면으로 이동하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('설정으로 이동'),
          ),
        ],
      ),
    );

    if (result == true) {
      await openBatteryOptimizationSettings();
      // 사용자가 설정 화면에서 설정을 변경했는지 확인하려면
      // 앱이 다시 포그라운드로 돌아올 때 확인해야 함
      return false; // 일단 false 반환 (사용자가 돌아온 후 다시 확인 필요)
    }

    return false;
  }

  /// 배터리 최적화 예외 설정 확인 및 안내 (앱 시작 시 자동 체크)
  /// 
  /// [context] BuildContext
  /// [autoShowDialog] 자동으로 다이얼로그를 표시할지 여부 (기본값: false)
  /// 
  /// Returns: 배터리 최적화 예외가 설정되어 있으면 true
  static Future<bool> checkAndPromptBatteryOptimization(
    BuildContext context, {
    bool autoShowDialog = false,
  }) async {
    final isIgnoring = await isIgnoringBatteryOptimizations();
    
    if (!isIgnoring && autoShowDialog) {
      // 배터리 최적화 예외가 설정되지 않았고, 자동 다이얼로그 표시가 활성화되어 있으면
      await requestBatteryOptimizationException(context);
    }
    
    return isIgnoring;
  }
}

