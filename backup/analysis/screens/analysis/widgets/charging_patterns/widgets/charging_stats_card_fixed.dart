import 'dart:async';
import 'package:flutter/material.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';
import '../utils/time_slot_utils.dart';
import '../controllers/date_selector_controller.dart';
import '../controllers/charging_session_data_loader.dart';
import '../controllers/charging_stats_controller.dart';
import 'stat_card.dart';
import 'active_charging_card.dart';
import 'date_selector_tabs.dart';
import 'charging_session_list_item.dart';
import 'charging_session_detail_dialog.dart';
import '../../../../../services/battery_service.dart';

/// 섹션 3: 통계 + 세션 기록 카드
/// 
/// 실제 충전 세션 데이터를 표시하는 카드
/// - 날짜별 통계 (평균 속도, 충전 횟수, 주 시간대)
/// - 날짜별 충전 세션 목록
class ChargingStatsCard extends StatefulWidget {
  const ChargingStatsCard({super.key});

  @override
  State<ChargingStatsCard> createState() => _ChargingStatsCardState();
}

class _ChargingStatsCardState extends State<ChargingStatsCard> {
  bool _isSessionsExpanded = false;
  
  final ChargingSessionService _sessionService = ChargingSessionService();
  final ChargingSessionStorage _storageService = ChargingSessionStorage();
  final BatteryService _batteryService = BatteryService();
  
  // 컨트롤러들
  late final DateSelectorController _dateController;
  late final ChargingSessionDataLoader _dataLoader;
  late final ChargingStatsController _statsController;
  
  @override
  void initState() {
    super.initState();
    // 날짜 선택 컨트롤러 초기화
    _dateController = DateSelectorController();
    
    // 데이터 로더 초기화
    _dataLoader = ChargingSessionDataLoader(
      sessionService: _sessionService,
      storageService: _storageService,
    );
    
    // 통계 컨트롤러 초기화
    _statsController = ChargingStatsController(
      sessionService: _sessionService,
      storageService: _storageService,
      batteryService: _batteryService,
      dateController: _dateController,
      dataLoader: _dataLoader,
    );
    _statsController.setIsMounted(() => mounted);
    _statsController.setOnStateChanged(() {
      if (mounted) {
        setState(() {});
      }
    });
    _statsController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      // 통계 컨트롤러 초기화 (내부에서 데이터 로더 초기화 및 데이터 로드 수행)
      await _statsController.initialize();
    } catch (e, stackTrace) {
      debugPrint('ChargingStatsCard 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }
  
  /// Pull-to-Refresh를 위한 public 메서드
  /// 현재 선택된 날짜의 세션 데이터를 강제로 새로고침합니다.
  Future<void> refresh() async {
    await _statsController.refresh();
  }
  
  @override
  void dispose() {
    // 통계 컨트롤러 정리 (내부에서 타이머 및 스트림 정리)
    _statsController.dispose();
    
    // 날짜 선택 컨트롤러 정리
    _dateController.dispose();
    
    // 데이터 로더 캐시 정리 (선택사항, 메모리 절약)
    // _dataLoader.clearCache();
    
    // 주의: ChargingSessionService는 싱글톤이므로 여기서 dispose하지 않음
    // 서비스는 앱 전체에서 사용되므로 위젯이 dispose되어도 유지됨
    super.dispose();
  }
  
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
                Text(
                  '충전 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 날짜 선택 영역
          DateSelectorTabs(controller: _dateController),
          
          SizedBox(height: 16),
          
          // 통계 카드 3개 (가로 배치)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StatCard(
                    title: '평균속도',
                    mainValue: _statsController.isLoading ? '...' : (_statsController.stats.avgCurrent > 0 ? _statsController.stats.avgCurrent.toStringAsFixed(0) : '0'),
                    unit: 'mA',
                    subValue: _statsController.stats.avgCurrent > 0 ? _getCurrentSpeedType(_statsController.stats.avgCurrent) : '데이터 없음',
                    trend: '', // 추후 주간 비교 데이터 추가 시 사용
                    trendColor: Colors.green,
                    icon: Icons.speed,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: '충전횟수',
                    mainValue: _statsController.isLoading ? '...' : '${_statsController.stats.sessionCount}회',
                    unit: _dateController.getDateUnitText(),
                    subValue: _statsController.stats.sessionCount > 0 ? '${_dateController.getDateDisplayText()} 기준' : '없음',
                    trend: '', // 추후 주간 비교 데이터 추가 시 사용
                    trendColor: Colors.blue,
                    icon: Icons.battery_charging_full,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: '주시간대',
                    mainValue: _statsController.isLoading ? '...' : _statsController.stats.mainTimeSlot,
                    unit: '',
                    subValue: _statsController.stats.mainTimeSlot != '-' && _statsController.stats.mainTimeSlotEnum != null 
                        ? TimeSlotUtils.getTimeSlotRange(_statsController.stats.mainTimeSlotEnum!) 
                        : '없음',
                    trend: '안정',
                    trendColor: Colors.blue,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // 세션 기록 펼치기 버튼
          InkWell(
            onTap: () {
              setState(() {
                _isSessionsExpanded = !_isSessionsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSessionsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '충전 세션 기록 (${_dateController.getDateDisplayText()}) ${_isSessionsExpanded ? '' : '보기'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!_isSessionsExpanded)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statsController.currentSessions.where((s) => s.validate()).length}건',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 세션 기록 리스트 (펼쳤을 때만 표시)
          if (_isSessionsExpanded) ...[
            // 진행 중인 충전 카드 (오늘 탭이고 진행 중인 세션이 있을 때만)
            if (_dateController.isToday && _sessionService.isSessionActive) ...[
              ActiveChargingCard(
                batteryService: _batteryService,
                sessionService: _sessionService,
              ),
              SizedBox(height: 12),
            ],
            if (_statsController.isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '${_dateController.getDateDisplayText()} 데이터 로딩 중...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_statsController.currentSessions.isEmpty)
              // 진행 중인 충전 카드가 표시될 때는 빈 상태 메시지 숨김
              if (_dateController.isToday && _sessionService.isSessionActive)
                const SizedBox.shrink()
              else
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.battery_charging_full,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '${_dateController.getDateDisplayText()} 충전 세션이 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '해당 날짜에 기록된 충전 세션이 없습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 헤더 (선택 사항)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${_dateController.getDateDisplayText()} - ${_statsController.currentSessions.where((s) => s.validate()).length}개 세션',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 세션 목록 (5분 이상인 세션만 표시)
                    ..._statsController.currentSessions.where((s) => s.validate()).map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChargingSessionListItem(
                          session: session,
                          onTap: () {
                            // 세션 상세 정보 다이얼로그 표시
                            ChargingSessionDetailDialog.show(context, session);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  /// 전류 속도 타입 반환
  String _getCurrentSpeedType(double current) {
    if (current >= 3000) return '⚡ 초고속';
    if (current >= 1500) return '⚡ 급속';
    if (current >= 500) return '🟧 일반';
    return '🔵 저속';
  }
}

