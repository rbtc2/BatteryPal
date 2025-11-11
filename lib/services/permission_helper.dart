import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'system_settings_service.dart';

/// 권한 요청을 도와주는 헬퍼 클래스
/// 
/// 사용자에게 권한이 필요한 이유를 설명하고,
/// 직관적인 다이얼로그를 통해 권한 설정 화면으로 안내합니다.
class PermissionHelper {

  /// 알림 권한 요청 (다이얼로그와 함께)
  /// 
  /// [context] BuildContext
  /// [showDialogPrompt] 다이얼로그를 표시할지 여부 (기본값: true)
  /// 
  /// Returns 권한이 허용되었는지 여부
  static Future<bool> requestNotificationPermission(
    BuildContext context, {
    bool showDialogPrompt = true,
  }) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (!showDialogPrompt) {
      // 다이얼로그를 표시하지 않고 바로 권한 요청
      final newStatus = await Permission.notification.request();
      return newStatus.isGranted;
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
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('알림 권한 필요'),
          ],
        ),
        content: const Text(
          '배터리 충전 알림을 받으려면\n'
          '알림 권한이 필요합니다.\n\n'
          '알림을 허용하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('허용'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newStatus = await Permission.notification.request();
      return newStatus.isGranted;
    }

    return false;
  }

  /// 알림 권한 확인
  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 화면 밝기 조절 권한 요청 (WRITE_SETTINGS)
  /// 
  /// [context] BuildContext
  /// [showDialogPrompt] 다이얼로그를 표시할지 여부 (기본값: true)
  /// 
  /// Returns 권한이 허용되었는지 여부
  static Future<bool> requestWriteSettingsPermission(
    BuildContext context, {
    bool showDialogPrompt = true,
  }) async {
    // Android에서 WRITE_SETTINGS 권한 확인
    if (await Permission.systemAlertWindow.isGranted) {
      // 이미 권한이 있으면 true 반환
      return true;
    }

    if (!showDialogPrompt) {
      // 다이얼로그를 표시하지 않고 바로 시스템 설정으로 이동
      await openAppSettings();
      return false;
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
              Icons.brightness_6,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('화면 밝기 조절 권한 필요'),
          ],
        ),
        content: const Text(
          '배터리를 절약하기 위해 화면 밝기를 자동으로 조절하려면\n'
          '시스템 설정 변경 권한이 필요합니다.\n\n'
          '시스템 설정 화면에서 "권한 허용" 토글을 켜주세요.\n'
          '만약 토글이 회색으로 비활성화되어 있다면, 기기 제조사의\n'
          '보안 정책으로 인해 이 권한을 사용할 수 없을 수 있습니다.\n\n'
          '시스템 설정 화면으로 이동하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('설정으로 이동'),
          ),
        ],
      ),
    );

    if (result == true) {
      // WRITE_SETTINGS 권한 설정 화면으로 이동
      // openAppSettings()가 아닌 특별한 설정 화면으로 이동해야 함
      final systemSettingsService = SystemSettingsService();
      await systemSettingsService.openWriteSettingsPermission();
      // 사용자가 설정에서 권한을 허용했는지 확인하려면 앱이 다시 포그라운드로 돌아올 때 확인해야 함
      return false; // 일단 false 반환 (사용자가 돌아온 후 다시 확인 필요)
    }

    return false;
  }

  /// 화면 밝기 조절 권한 확인
  /// 
  /// Android에서는 Settings.System.canWrite()로 확인해야 하지만,
  /// permission_handler 패키지로는 직접 확인이 어려우므로
  /// 실제로 설정을 시도해보는 것이 더 정확합니다.
  static Future<bool> checkWriteSettingsPermission() async {
    // permission_handler로는 직접 확인이 어려우므로
    // 실제로는 SystemSettingsService에서 확인하는 것이 더 정확합니다
    return false; // 기본값은 false (실제 확인은 SystemSettingsService에서)
  }
}

