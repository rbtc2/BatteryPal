import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 공통 위젯들을 위한 기본 클래스
/// Phase 2에서 실제 구현

/// 공통 카드 위젯
class CustomCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const CustomCard({
    super.key,
    required this.child,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: backgroundColor,
      shape: borderRadius != null 
          ? RoundedRectangleBorder(borderRadius: borderRadius!)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? AppSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}

/// 정보 아이템 위젯 (라벨-값 쌍)
class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double? valueFontSize;
  final double? labelFontSize;
  final FontWeight? valueFontWeight;
  
  const InfoItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize,
    this.labelFontSize,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: valueFontWeight ?? AppTextStyles.bold,
            fontSize: valueFontSize ?? AppTextStyles.bodyLarge,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaHigh),
            fontSize: labelFontSize ?? AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// 요약 아이템 위젯 (일일 요약용)
class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  
  const SummaryItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: AppTextStyles.bold,
            fontSize: AppTextStyles.titleMedium,
            color: valueColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaHigh),
            fontSize: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Pro 배지 위젯
class ProBadge extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  
  const ProBadge({
    super.key,
    this.text = '⚡ Pro',
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(AppColors.proColorValue), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize ?? AppTextStyles.bodySmall,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

/// 로딩 인디케이터 위젯
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? AppIconSizes.xlarge,
            height: size ?? AppIconSizes.xlarge,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaHigh),
                fontSize: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 빈 상태 위젯
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSizes.xxlarge,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaMedium),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaHigh),
                  fontSize: AppTextStyles.bodyMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 효과 아이템 위젯 (최적화 효과 표시용)
class EffectItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double? valueFontSize;
  final double? labelFontSize;
  final FontWeight? valueFontWeight;
  
  const EffectItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize,
    this.labelFontSize,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: valueFontWeight ?? AppTextStyles.bold,
            fontSize: valueFontSize ?? AppTextStyles.titleMedium,
            color: valueColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppColors.alphaHigh),
            fontSize: labelFontSize ?? AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// 섹션 헤더 위젯
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.cardPadding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: AppIconSizes.large,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
