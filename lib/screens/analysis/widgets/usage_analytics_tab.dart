import 'package:flutter/material.dart';
import '../../../models/app_usage_models.dart';
import 'weekly_calendar_card.dart';
import 'today_summary_card.dart';
import 'app_battery_usage_card.dart';

/// 사용 패턴 탭 - 완전히 새로 구현된 스켈레톤 UI
/// 
/// 🎯 주요 기능:
/// 1. TodaySummaryCard: 오늘의 스크린타임 대시보드 (큰 숫자 + 어제 대비)
/// 2. WeeklyCalendarCard: 주간 달력 + 통계 + 배터리 인사이트 (NEW!)
/// 3. AppBatteryUsageCard: 앱별 배터리 소모 분석 (메인)
/// 
/// 📱 구현된 섹션:
/// - 오늘의 대시보드: 큰 스크린타임 숫자, 어제 대비 변화량, 3개 메트릭 박스
/// - 주간 달력: 최근 7일 스크린타임 달력, 주간 통계, 배터리 관점 인사이트
/// - 앱별 소모: 5개 앱 + 기타 앱들의 배터리 소모 분석
/// 
/// 🎨 디자인 특징:
/// - 일관된 색상 시스템 (심각도별 색상)
/// - 반응형 레이아웃 (오버플로우 방지)
/// - 직관적 인터랙션 (펼치기/접기 기능)
/// - 다크모드/라이트모드 완벽 지원
/// 
/// ⚡ 성능 최적화:
/// - const 생성자 사용으로 불필요한 리빌드 방지
/// - 데이터 캐싱 (5분 유효기간)
/// - 텍스트 줄바꿈 방지로 레이아웃 안정성

/// 사용 패턴 탭 - 메인 위젯
class UsageAnalyticsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const UsageAnalyticsTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  State<UsageAnalyticsTab> createState() => _UsageAnalyticsTabState();
}

class _UsageAnalyticsTabState extends State<UsageAnalyticsTab> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<TodaySummaryCardState> _todaySummaryKey = GlobalKey<TodaySummaryCardState>();
  final GlobalKey<AppBatteryUsageCardState> _appUsageKey = GlobalKey<AppBatteryUsageCardState>();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // 항상 스크롤 가능하도록
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 섹션 1: 오늘의 요약
            TodaySummaryCard(
              key: _todaySummaryKey,
              onRefresh: _handleRefresh,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 2: 주간 달력 (NEW!)
            WeeklyCalendarCard(
              onRefresh: _handleRefresh,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 3: 앱별 배터리 소모 (메인)
            AppBatteryUsageCard(
              key: _appUsageKey,
              onRefresh: _handleRefresh,
            ),
            
            // 하단 여백
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 전체 새로고침 처리
  Future<void> _handleRefresh() async {
    try {
      // 캐시 클리어
      final appUsageManager = AppUsageManager();
      appUsageManager.clearCache();
      
      // 모든 카드 새로고침
      await Future.wait([
        _todaySummaryKey.currentState?.refresh() ?? Future.value(),
        _appUsageKey.currentState?.refresh() ?? Future.value(),
      ]);
    } catch (e) {
      debugPrint('전체 새로고침 실패: $e');
    }
  }
}
