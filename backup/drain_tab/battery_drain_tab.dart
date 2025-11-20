import 'package:flutter/material.dart';
import 'widgets/battery_drain/widgets/drain_stats_card.dart';
import 'widgets/battery_drain/widgets/drain_hourly_chart.dart';
import 'widgets/battery_drain/widgets/drain_period_list.dart';

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
  
  // 탭 가시성 상태
  bool _isTabVisible = false;
  // 1분 타이머 제거됨 - 탭 전환 시에만 새로고침하도록 변경
  
  // 날짜 상태 관리 (DrainHourlyChart에 전달용)
  DateTime? _currentTargetDate;
  
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
        _updateTargetDate(); // 초기 날짜 설정
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
        // 탭이 보일 때: 한 번만 새로고침 (이벤트 기반으로 전환)
        _refreshStatsCard();
      }
      // 탭이 안 보일 때는 아무 작업도 하지 않음 (메모리 절약)
    }
  }
  
  // 1분 타이머 기반 실시간 업데이트 제거됨
  // 탭이 보일 때 한 번만 새로고침하며, 사용자가 Pull-to-Refresh로 수동 새로고침 가능
  
  /// DrainStatsCard 새로고침
  void _refreshStatsCard() {
    final statsState = _statsKey.currentState;
    if (statsState != null) {
      try {
        final refreshMethod = (statsState as dynamic).refresh;
        if (refreshMethod != null && refreshMethod is Function) {
          refreshMethod();
        }
        
        // 날짜 업데이트
        _updateTargetDate();
      } catch (e) {
        debugPrint('DrainStatsCard 자동 새로고침 실패: $e');
      }
    }
  }
  
  /// DrainStatsCard에서 현재 날짜 가져오기
  void _updateTargetDate() {
    final statsState = _statsKey.currentState;
    if (statsState != null) {
      try {
        final getTargetDateMethod = (statsState as dynamic).getTargetDate;
        if (getTargetDateMethod != null && getTargetDateMethod is Function) {
          final newDate = getTargetDateMethod() as DateTime;
          if (_currentTargetDate == null || 
              !_isSameDate(_currentTargetDate!, newDate)) {
            setState(() {
              _currentTargetDate = newDate;
            });
          }
        }
      } catch (e) {
        debugPrint('날짜 가져오기 실패: $e');
      }
    }
  }
  
  /// 두 날짜가 같은 날인지 확인
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  void dispose() {
    // TabController 리스너 제거
    if (widget.tabController != null) {
      widget.tabController!.removeListener(_onTabControllerChanged);
    }
    
    // 타이머 제거됨 (더 이상 사용하지 않음)
    
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
    
    // 날짜 업데이트
    _updateTargetDate();
    
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
                  onDateChanged: (date) {
                    // 날짜 변경 시 DrainHourlyChart에 전달
                    setState(() {
                      _currentTargetDate = date;
                    });
                  },
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
                  targetDate: _currentTargetDate,
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

