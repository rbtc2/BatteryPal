import 'package:flutter/material.dart';
import 'optimization/widgets/optimization_dashboard_card.dart';
import 'optimization/widgets/auto_optimization_card.dart';
import 'optimization/widgets/manual_optimization_card.dart';
import 'optimization/widgets/optimization_tips_card.dart';

/// 최적화 탭 - 재설계된 UI/UX
/// 
/// 🎯 주요 기능:
/// 1. OptimizationDashboardCard: 최적화 현황 대시보드
/// 2. AutoOptimizationCard: 자동 최적화 항목 관리
/// 3. ManualOptimizationCard: 수동 설정 항목 관리
/// 4. OptimizationTipsCard: 맞춤 추천 및 팁
/// 
/// 📱 구현된 섹션:
/// - 최적화 현황: 마지막 최적화 시간, 오늘 통계, 4가지 핵심 지표
/// - 자동 최적화: 원클릭 최적화에 포함되는 항목들 (토글)
/// - 수동 설정: 시스템 설정 화면으로 이동하는 항목들
/// - 맞춤 추천: 배터리 소모 앱, 절약 팁, 통계
/// 
/// 🎨 디자인 특징:
/// - 그라데이션 배경 (초록→청록)
/// - 색상별 구분 (자동: 초록, 수동: 파랑)
/// - 직관적 인터랙션 (토글, 버튼)
/// - 다크모드 완벽 대응

/// 최적화 탭 - 메인 위젯
class OptimizationTab extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const OptimizationTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 섹션 1: 최적화 현황 대시보드
          const OptimizationDashboardCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 2: 자동 최적화 항목
          const AutoOptimizationCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 3: 수동 설정 항목
          const ManualOptimizationCard(),
          
          const SizedBox(height: 16),
          
          // 섹션 4: 최적화 팁 & 인사이트
          const OptimizationTipsCard(),
          
          // 하단 여백
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
