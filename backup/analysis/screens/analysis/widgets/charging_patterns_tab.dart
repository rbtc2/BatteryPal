import 'package:flutter/material.dart';
import 'charging_patterns/widgets/charging_current_chart.dart';
import 'charging_patterns/widgets/charging_stats_card.dart';
import 'charging_patterns/widgets/pro_exclusive_section.dart';

/// 충전 패턴 탭 - 리팩토링된 모듈화된 구조
/// 
/// 주요 기능:
/// 1. ChargingCurrentChart: fl_chart를 사용한 실시간 충전 전류 그래프
/// 2. ChargingStatsCard: 향상된 통계 및 세션 기록 카드
/// 3. Pro 사용자 전용 고급 분석 기능
/// 
/// 애니메이션:
/// - 페이지 로드 시 순차적 슬라이드 애니메이션
/// - 각 섹션별 독립적인 타이밍으로 부드러운 전환
/// 
/// Pro 기능:
/// - 상세 분석 다이얼로그
/// - AI 충전 패턴 예측
/// - 실시간 최적화 제안

/// 충전 패턴 탭 - 새로운 스켈레톤 UI 구현
class ChargingPatternsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const ChargingPatternsTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
  });

  @override
  State<ChargingPatternsTab> createState() => _ChargingPatternsTabState();
}

class _ChargingPatternsTabState extends State<ChargingPatternsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Pull-to-Refresh를 위한 GlobalKey
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Pull-to-Refresh 콜백
  /// 모든 데이터를 새로고침합니다.
  Future<void> _onRefresh() async {
    // 각 위젯의 State에 접근하여 refresh 메서드 호출 (동적 호출)
    final chartState = _chartKey.currentState;
    final statsState = _statsKey.currentState;
    
    final futures = <Future>[];
    
    // ChargingCurrentChart의 refresh 메서드 호출
    if (chartState != null) {
      try {
        final refreshMethod = (chartState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          futures.add(refreshMethod());
        }
      } catch (e) {
        debugPrint('ChargingCurrentChart refresh 호출 실패: $e');
      }
    }
    
    // ChargingStatsCard의 refresh 메서드 호출
    if (statsState != null) {
      try {
        final refreshMethod = (statsState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          futures.add(refreshMethod());
        }
      } catch (e) {
        debugPrint('ChargingStatsCard refresh 호출 실패: $e');
      }
    }
    
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 섹션 1: 충전 전류 그래프 (메인)
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                )),
                child: ChargingCurrentChart(
                  key: _chartKey,
                  isProUser: widget.isProUser,
                  onProUpgrade: widget.onProUpgrade,
                ),
              ),
              
              SizedBox(height: 16),
              
              // 섹션 2: 통계 + 세션 기록
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                )),
                child: ChargingStatsCard(
                  key: _statsKey,
                ),
              ),
              
              // Pro 사용자 전용 추가 섹션
              if (widget.isProUser) ...[
                SizedBox(height: 16),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                  )),
                  child: ProExclusiveSection(),
                ),
              ],
              
              // 하단 여백
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

}

