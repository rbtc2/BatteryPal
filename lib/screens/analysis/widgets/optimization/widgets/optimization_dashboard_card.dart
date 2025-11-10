import 'package:flutter/material.dart';
import '../models/optimization_models.dart';
import '../utils/optimization_formatters.dart';

/// 섹션 1: 최적화 현황 대시보드
class OptimizationDashboardCard extends StatelessWidget {
  const OptimizationDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터
    final stats = OptimizationStats(
      lastOptimizedAt: DateTime.now().subtract(const Duration(hours: 2)),
      todayOptimizationCount: 3,
      todayTotalSaved: const Duration(hours: 2, minutes: 15),
      appsKilled: 12,
      memoryMB: 234,
      cacheMB: 512,
      servicesStopped: 5,
    );

    final lastOptimizedText = formatTimeAgo(stats.lastOptimizedAt);
    final todaySavedText = formatDuration(stats.todayTotalSaved);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!,
            Colors.teal[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '최적화 현황',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 요약 정보
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.access_time,
                    label: '마지막 최적화',
                    value: lastOptimizedText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.refresh,
                    label: '오늘 횟수',
                    value: '${stats.todayOptimizationCount}회',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.battery_std,
                    label: '오늘 절약',
                    value: todaySavedText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 4가지 핵심 지표
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.apps,
                    value: '${stats.appsKilled}개',
                    label: '종료된 앱',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.memory,
                    value: '${stats.memoryMB}MB',
                    label: '확보한 메모리',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.cleaning_services,
                    value: '${stats.cacheMB}MB',
                    label: '정리된 캐시',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    icon: Icons.settings_power,
                    value: '${stats.servicesStopped}개',
                    label: '중지된 서비스',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 프로그레스 바 (오늘 목표 대비)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘 목표 진행률',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

