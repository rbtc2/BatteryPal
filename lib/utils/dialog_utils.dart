import 'package:flutter/material.dart';
import '../widgets/dialogs/common_dialogs.dart';
import '../constants/app_constants.dart';
import '../utils/app_utils.dart';

/// 다이얼로그 헬퍼 유틸리티
/// Phase 4에서 실제 구현

class DialogUtils {
  /// Pro 업그레이드 다이얼로그 표시
  static void showProUpgradeDialog(
    BuildContext context, {
    required VoidCallback onUpgrade,
    String? title,
    String? content,
    String? upgradeButtonText,
    String? cancelButtonText,
  }) {
    showDialog(
      context: context,
      builder: (context) => ProUpgradeDialog(
        onUpgrade: onUpgrade,
        title: title,
        content: content,
        upgradeButtonText: upgradeButtonText,
        cancelButtonText: cancelButtonText,
      ),
    );
  }

  /// 최적화 다이얼로그 표시
  static void showOptimizationDialog(
    BuildContext context, {
    String? title,
    String? content,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => OptimizationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 배터리 진단 다이얼로그 표시
  static void showBatteryDiagnosticDialog(
    BuildContext context, {
    String? title,
    String? content,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => BatteryDiagnosticDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 배터리 보정 다이얼로그 표시
  static void showBatteryCalibrationDialog(
    BuildContext context, {
    String? title,
    String? content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
  }) {
    showDialog(
      context: context,
      builder: (context) => BatteryCalibrationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  /// 언어 선택 다이얼로그 표시
  static void showLanguageSelectionDialog(
    BuildContext context, {
    required String currentLanguage,
    required ValueChanged<String> onLanguageChanged,
    List<String>? availableLanguages,
  }) {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        currentLanguage: currentLanguage,
        onLanguageChanged: onLanguageChanged,
        availableLanguages: availableLanguages ?? const ['한국어', 'English'],
      ),
    );
  }

  /// 구독 관리 다이얼로그 표시
  static void showSubscriptionDialog(
    BuildContext context, {
    String? title,
    String? content,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => SubscriptionDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 확인 다이얼로그 표시
  static void showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmButtonColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText ?? '확인',
        cancelText: cancelText ?? '취소',
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmButtonColor: confirmButtonColor,
      ),
    );
  }

  /// 정보 다이얼로그 표시
  static void showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
    IconData? icon,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        content: content,
        buttonText: buttonText ?? '확인',
        icon: icon,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 배터리 상태 다이얼로그 표시
  static void showBatteryStatusDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => BatteryStatusDialog(
        title: title,
        content: content,
        buttonText: buttonText ?? '확인',
        onConfirm: onConfirm,
      ),
    );
  }

  /// 설정 변경 확인 다이얼로그 표시
  static void showSettingsChangeDialog(
    BuildContext context, {
    required String settingName,
    required String currentValue,
    required String newValue,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => SettingsChangeDialog(
        settingName: settingName,
        currentValue: currentValue,
        newValue: newValue,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// 앱 정보 다이얼로그 표시
  static void showAppInfoDialog(
    BuildContext context, {
    required String appName,
    required String version,
    required String developer,
    required String license,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AppInfoDialog(
        appName: appName,
        version: version,
        developer: developer,
        license: license,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 배터리 보정 시작 다이얼로그 (스낵바 포함)
  static void showBatteryCalibrationStartDialog(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showBatteryCalibrationDialog(
      context,
      onConfirm: () {
        onConfirm?.call();
        SnackBarUtils.showSuccess(context, '배터리 보정이 시작되었습니다');
      },
    );
  }

  /// Pro 업그레이드 성공 다이얼로그
  static void showProUpgradeSuccessDialog(
    BuildContext context, {
    required VoidCallback onUpgrade,
  }) {
    showProUpgradeDialog(
      context,
      onUpgrade: () {
        onUpgrade();
        SnackBarUtils.showSuccess(context, 'Pro 모드가 활성화되었습니다!');
      },
      title: 'Pro 업그레이드',
      content: 'Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원',
    );
  }

  /// 분석 탭용 Pro 업그레이드 다이얼로그 (분석 탭 제거로 인해 주석 처리)
  // 분석 탭이 백업되어 제거됨 (backup/analysis/)
  // 나중에 기능 탭에서 사용할 수 있으므로 메서드는 유지하되 주석 처리
  static void showAnalysisProUpgradeDialog(
    BuildContext context, {
    required VoidCallback onUpgrade,
  }) {
    showProUpgradeDialog(
      context,
      onUpgrade: onUpgrade,
      title: 'Pro 업그레이드',
      content: 'Pro 모드로 업그레이드하시겠습니까?\n\n• 모든 앱 분석 보기\n• 배터리 건강도 트렌드\n• AI 인사이트\n• 상세 리포트',
    );
  }

  /// 설정 탭용 Pro 업그레이드 다이얼로그
  static void showSettingsProUpgradeDialog(
    BuildContext context, {
    required VoidCallback onUpgrade,
  }) {
    showProUpgradeDialog(
      context,
      onUpgrade: onUpgrade,
      title: 'Pro 업그레이드',
      content: 'Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원',
    );
  }

  /// 앱 정보 다이얼로그 (상수 사용)
  static void showDefaultAppInfoDialog(BuildContext context) {
    showAppInfoDialog(
      context,
      appName: AppConstants.appName,
      version: AppConstants.appVersion,
      developer: AppConstants.developerName,
      license: AppConstants.license,
    );
  }

  /// 언어 변경 확인 다이얼로그
  static void showLanguageChangeDialog(
    BuildContext context, {
    required String currentLanguage,
    required String newLanguage,
    required VoidCallback onConfirm,
  }) {
    showSettingsChangeDialog(
      context,
      settingName: '언어',
      currentValue: currentLanguage,
      newValue: newLanguage,
      onConfirm: onConfirm,
    );
  }

  /// 테마 변경 확인 다이얼로그
  static void showThemeChangeDialog(
    BuildContext context, {
    required String currentTheme,
    required String newTheme,
    required VoidCallback onConfirm,
  }) {
    showSettingsChangeDialog(
      context,
      settingName: '테마',
      currentValue: currentTheme,
      newValue: newTheme,
      onConfirm: onConfirm,
    );
  }

  /// 배터리 임계값 변경 확인 다이얼로그
  static void showBatteryThresholdChangeDialog(
    BuildContext context, {
    required double currentThreshold,
    required double newThreshold,
    required VoidCallback onConfirm,
  }) {
    showSettingsChangeDialog(
      context,
      settingName: '배터리 알림 임계값',
      currentValue: '${currentThreshold.toStringAsFixed(0)}%',
      newValue: '${newThreshold.toStringAsFixed(0)}%',
      onConfirm: onConfirm,
    );
  }
}
