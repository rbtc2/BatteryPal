import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
}

