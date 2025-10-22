import 'package:flutter/material.dart';

/// 빠른 액션 카드 위젯
/// 배터리 부스트와 분석 바로가기를 통합한 카드
class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onBoost;
  final VoidCallback? onAnalysis;
  final bool isProUser;
  final int dailyUsage;
  final int dailyLimit;

  const QuickActionsCard({
    super.key,
    this.onBoost,
    this.onAnalysis,
    required this.isProUser,
    this.dailyUsage = 0,
    this.dailyLimit = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  '빠른 액션',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 2개 액션 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.rocket_launch,
                    title: '부스트',
                    subtitle: '원클릭 최적화',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: onBoost,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.analytics,
                    title: '분석',
                    subtitle: '상세보기',
                    color: Colors.purple,
                    onTap: onAnalysis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 사용 제한 정보 (무료 사용자)
          if (!isProUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '오늘 $dailyUsage/$dailyLimit회 사용 (무료)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
