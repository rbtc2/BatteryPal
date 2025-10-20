import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 공통 다이얼로그들을 위한 기본 클래스
/// Phase 4에서 실제 구현

/// Pro 업그레이드 다이얼로그
class ProUpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  final String? title;
  final String? content;
  final String? upgradeButtonText;
  final String? cancelButtonText;
  
  const ProUpgradeDialog({
    super.key,
    required this.onUpgrade,
    this.title,
    this.content,
    this.upgradeButtonText,
    this.cancelButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Pro 업그레이드'),
      content: Text(content ?? 
        'Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelButtonText ?? '취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpgrade();
          },
          child: Text(upgradeButtonText ?? '업그레이드'),
        ),
      ],
    );
  }
}

/// 최적화 다이얼로그
class OptimizationDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final String? confirmText;
  final VoidCallback? onConfirm;
  
  const OptimizationDialog({
    super.key,
    this.title,
    this.content,
    this.confirmText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? '배터리 최적화'),
      content: Text(content ?? 'Phase 5에서 실제 최적화 기능이 구현됩니다.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(confirmText ?? '확인'),
        ),
      ],
    );
  }
}

/// 배터리 진단 다이얼로그
class BatteryDiagnosticDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final String? confirmText;
  final VoidCallback? onConfirm;
  
  const BatteryDiagnosticDialog({
    super.key,
    this.title,
    this.content,
    this.confirmText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? '배터리 진단'),
      content: Text(content ?? 
        '배터리 상태를 진단하시겠습니까?\n\n• 배터리 건강도: 양호\n• 충전 성능: 정상\n• 온도 상태: 정상\n• 예상 수명: 2-3년'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(confirmText ?? '확인'),
        ),
      ],
    );
  }
}

/// 배터리 보정 다이얼로그
class BatteryCalibrationDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmText;
  final String? cancelText;
  
  const BatteryCalibrationDialog({
    super.key,
    this.title,
    this.content,
    this.onConfirm,
    this.onCancel,
    this.confirmText,
    this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? '배터리 보정'),
      content: Text(content ?? 
        '배터리 보정을 시작하시겠습니까?\n\n이 과정은 약 2-3시간 소요되며, 완전 방전 후 완전 충전이 필요합니다.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(cancelText ?? '취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(confirmText ?? '시작'),
        ),
      ],
    );
  }
}

/// 언어 선택 다이얼로그
class LanguageSelectionDialog extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final List<String> availableLanguages;
  
  const LanguageSelectionDialog({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.availableLanguages = const ['한국어', 'English'],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('언어 선택'),
      content: RadioGroup<String>(
        groupValue: currentLanguage,
        onChanged: (value) {
          if (value != null) {
            onLanguageChanged(value);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLanguages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 구독 관리 다이얼로그
class SubscriptionDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final String? confirmText;
  final VoidCallback? onConfirm;
  
  const SubscriptionDialog({
    super.key,
    this.title,
    this.content,
    this.confirmText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? '구독 관리'),
      content: Text(content ?? 'Phase 5에서 구독 관리 기능이 구현됩니다.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(confirmText ?? '확인'),
        ),
      ],
    );
  }
}

/// 확인 다이얼로그
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmButtonColor,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// 정보 다이얼로그
class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final IconData? icon;
  final VoidCallback? onConfirm;
  
  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = '확인',
    this.icon,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// 배터리 상태 상세 다이얼로그
class BatteryStatusDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback? onConfirm;
  
  const BatteryStatusDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = '확인',
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.battery_std,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// 설정 변경 확인 다이얼로그
class SettingsChangeDialog extends StatelessWidget {
  final String settingName;
  final String currentValue;
  final String newValue;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  
  const SettingsChangeDialog({
    super.key,
    required this.settingName,
    required this.currentValue,
    required this.newValue,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$settingName 변경'),
      content: Text('$settingName을(를) "$currentValue"에서 "$newValue"로 변경하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: const Text('변경'),
        ),
      ],
    );
  }
}

/// 앱 정보 다이얼로그
class AppInfoDialog extends StatelessWidget {
  final String appName;
  final String version;
  final String developer;
  final String license;
  final VoidCallback? onConfirm;
  
  const AppInfoDialog({
    super.key,
    required this.appName,
    required this.version,
    required this.developer,
    required this.license,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.info,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('$appName 정보')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('버전', version),
          _buildInfoRow('개발자', developer),
          _buildInfoRow('라이선스', license),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
