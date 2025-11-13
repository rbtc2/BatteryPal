import 'dart:async';
import 'package:flutter/material.dart';
import 'battery_drain/widgets/drain_stats_card.dart';
import 'battery_drain/widgets/drain_hourly_chart.dart';
import 'battery_drain/widgets/drain_period_list.dart';

/// 배터리 소모 분석 탭 - 리팩토링된 모듈화된 구조
/// 
/// 주요 기능:
/// 1. DrainStatsCard: 소모 통계 카드
/// 2. DrainHourlyChart: 시간대별 소모 그래프
/// 3. DrainPeriodList: 소모 구간 리스트
/// 
/// 애니메이션:
/// - 페이지 로드 시 순차적 슬라이드 애니메이션
/// - 각 섹션별 독립적인 타이밍으로 부드러운 전환
/// 
/// Pro 기능:
/// - 상세 분석 다이얼로그
/// - AI 소모 패턴 예측
/// - 실시간 최적화 제안

/// 배터리 소모 분석 탭 - 스켈레톤 UI 구현
class BatteryDrainTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;
  final TabController? tabController; // TabController 추가
  final int tabIndex; // 이 탭의 인덱스

  const BatteryDrainTab({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
    this.tabController,
    required this.tabIndex,
  });

  @override
  State<BatteryDrainTab> createState() => _BatteryDrainTabState();
}

class _BatteryDrainTabState extends State<BatteryDrainTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Pull-to-Refresh를 위한 GlobalKey
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  
  // 실시간 업데이트 관련
  Timer? _updateTimer; // 실시간 업데이트 타이머
  bool _isTabVisible = false; // 탭 가시성 상태
  
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
    
    // TabController 리스너 추가
    if (widget.tabController != null) {
      widget.tabController!.addListener(_onTabControllerChanged);
      // 초기 상태 확인
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTabVisibility();
      });
    }
  }
  
  /// TabController 변경 감지
  void _onTabControllerChanged() {
    if (!widget.tabController!.indexIsChanging) {
      _checkTabVisibility();
    }
  }
  
  /// 탭 가시성 확인 및 업데이트 제어
  void _checkTabVisibility() {
    final isVisible = widget.tabController?.index == widget.tabIndex;
    
    if (isVisible != _isTabVisible) {
      setState(() {
        _isTabVisible = isVisible;
      });
      
      if (isVisible) {
        // 탭이 보일 때: 실시간 업데이트 시작
        _startRealtimeUpdate();
      } else {
        // 탭이 안 보일 때: 실시간 업데이트 중지
        _stopRealtimeUpdate();
      }
    }
  }
  
  /// 실시간 업데이트 시작 (탭이 보일 때만)
  void _startRealtimeUpdate() {
    _stopRealtimeUpdate(); // 기존 타이머 정리
    
    debugPrint('소모 탭 실시간 업데이트 시작');
    
    // 30초마다 업데이트 (오늘 탭일 때만)
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || !_isTabVisible) {
        timer.cancel();
        return;
      }
      
      // DrainStatsCard의 refresh 호출
      _refreshStatsCard();
    });
  }
  
  /// 실시간 업데이트 중지 (탭이 안 보일 때)
  void _stopRealtimeUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    debugPrint('소모 탭 실시간 업데이트 중지');
  }
  
  /// DrainStatsCard 새로고침
  void _refreshStatsCard() {
    final statsState = _statsKey.currentState;
    if (statsState != null) {
      try {
        final refreshMethod = (statsState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          refreshMethod();
        }
      } catch (e) {
        debugPrint('DrainStatsCard 자동 새로고침 실패: $e');
      }
    }
  }

  @override
  void dispose() {
    // TabController 리스너 제거
    if (widget.tabController != null) {
      widget.tabController!.removeListener(_onTabControllerChanged);
    }
    
    // 타이머 정리
    _stopRealtimeUpdate();
    
    _animationController.dispose();
    super.dispose();
  }

  /// Pull-to-Refresh 콜백
  /// 모든 데이터를 새로고침합니다.
  Future<void> _onRefresh() async {
    // 각 위젯의 State에 접근하여 refresh 메서드 호출 (동적 호출)
    final statsState = _statsKey.currentState;
    final chartState = _chartKey.currentState;
    final listState = _listKey.currentState;
    
    final futures = <Future>[];
    
    // DrainStatsCard의 refresh 메서드 호출
    if (statsState != null) {
      try {
        final refreshMethod = (statsState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          futures.add(refreshMethod());
        }
      } catch (e) {
        debugPrint('DrainStatsCard refresh 호출 실패: $e');
      }
    }
    
    // DrainHourlyChart의 refresh 메서드 호출
    if (chartState != null) {
      try {
        final refreshMethod = (chartState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          futures.add(refreshMethod());
        }
      } catch (e) {
        debugPrint('DrainHourlyChart refresh 호출 실패: $e');
      }
    }
    
    // DrainPeriodList의 refresh 메서드 호출
    if (listState != null) {
      try {
        final refreshMethod = (listState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          futures.add(refreshMethod());
        }
      } catch (e) {
        debugPrint('DrainPeriodList refresh 호출 실패: $e');
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
              // 섹션 1: 소모 통계 카드
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                )),
                child: DrainStatsCard(
                  key: _statsKey,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 섹션 2: 시간대별 소모 그래프
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                )),
                child: DrainHourlyChart(
                  key: _chartKey,
                  isProUser: widget.isProUser,
                  onProUpgrade: widget.onProUpgrade,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 섹션 3: 소모 구간 리스트
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                )),
                child: DrainPeriodList(
                  key: _listKey,
                ),
              ),
              
              // 하단 여백
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

