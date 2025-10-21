import 'package:flutter/material.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../utils/dialog_utils.dart';

/// 분석 탭에서 사용하는 공통 카드 위젯
class AnalysisCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showProUpgrade;
  final VoidCallback? onProUpgrade;
  final EdgeInsetsGeometry? padding;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showProUpgrade = false,
    this.onProUpgrade,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 4,
      padding: padding ?? const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showProUpgrade)
                TextButton(
                  onPressed: () => DialogUtils.showAnalysisProUpgradeDialog(
                    context,
                    onUpgrade: onProUpgrade ?? () {},
                  ),
                  child: const Text('Pro로 전체 보기'),
                ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: 16),
          
          // 콘텐츠 영역
          child,
        ],
      ),
    );
  }
}

/// 분석 탭에서 사용하는 메트릭 카드 위젯
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 분석 진행 상태를 표시하는 위젯
class AnalysisProgressWidget extends StatelessWidget {
  final String message;
  final double progress;
  final bool isIndeterminate;

  const AnalysisProgressWidget({
    super.key,
    required this.message,
    this.progress = 0.0,
    this.isIndeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isIndeterminate)
          const CircularProgressIndicator()
        else
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 분석 단계를 표시하는 위젯
class AnalysisStepWidget extends StatelessWidget {
  final String stepName;
  final bool isCompleted;
  final bool isActive;

  const AnalysisStepWidget({
    super.key,
    required this.stepName,
    this.isCompleted = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color stepColor;
    IconData stepIcon;

    if (isCompleted) {
      stepColor = Colors.green;
      stepIcon = Icons.check_circle;
    } else if (isActive) {
      stepColor = Theme.of(context).colorScheme.primary;
      stepIcon = Icons.radio_button_checked;
    } else {
      stepColor = Theme.of(context).colorScheme.outline;
      stepIcon = Icons.radio_button_unchecked;
    }

    return Row(
      children: [
        Icon(
          stepIcon,
          color: stepColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          stepName,
          style: TextStyle(
            color: stepColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Pro 업그레이드 버튼 위젯
class ProUpgradeButton extends StatelessWidget {
  final VoidCallback onUpgrade;
  final String? customText;

  const ProUpgradeButton({
    super.key,
    required this.onUpgrade,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        customText ?? '무료: 제한된 기능',
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
