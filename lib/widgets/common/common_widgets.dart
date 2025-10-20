import 'package:flutter/material.dart';

/// 공통 위젯들을 위한 기본 클래스
/// Phase 2에서 실제 구현 예정

/// 공통 카드 위젯
class CustomCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  
  const CustomCard({
    super.key,
    required this.child,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// 정보 아이템 위젯
class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  
  const InfoItem({
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
