import 'package:flutter/material.dart';

/// 통계 카드 위젯
/// 
/// 충전 통계를 표시하는 카드 컴포넌트입니다.
/// 아이콘, 제목, 메인 값, 단위, 서브 값, 트렌드를 표시합니다.
class StatCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final String unit;
  final String subValue;
  final String trend;
  final Color trendColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.mainValue,
    required this.unit,
    required this.subValue,
    required this.trend,
    required this.trendColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 제목
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: trendColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 메인 값 + 단위 (가로로 배치, 줄바꿈 방지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mainValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 4),
          
          // 서브 값과 트렌드
          Row(
            children: [
              Expanded(
                child: Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrendIcon(trend),
                      size: 8,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(String trend) {
    if (trend.startsWith('+')) return Icons.trending_up;
    if (trend.startsWith('-')) return Icons.trending_down;
    return Icons.trending_flat;
  }
}

