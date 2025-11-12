import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/charging_chart_service.dart';
import '../models/charging_data_models.dart';
import '../models/charging_session_models.dart';
import '../services/charging_session_service.dart';
import '../services/charging_session_storage.dart';
import '../../../../../services/battery_history_database_service.dart';

/// 섹션 2: 충전 전류 그래프 (메인)
class ChargingCurrentChart extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;

  const ChargingCurrentChart({
    super.key,
    this.isProUser = false,
    this.onProUpgrade,
  });

  @override
  State<ChargingCurrentChart> createState() => _ChargingCurrentChartState();
}

class _ChargingCurrentChartState extends State<ChargingCurrentChart> {
  String _selectedTab = '오늘'; // '오늘', '어제', '2일 전'
  List<ChargingDataPoint> _chartData = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  
  final BatteryHistoryDatabaseService _databaseService = BatteryHistoryDatabaseService();
  final ChargingSessionService _sessionService = ChargingSessionService();
  final ChargingSessionStorage _storageService = ChargingSessionStorage();
  Timer? _refreshTimer;
  StreamSubscription<List<ChargingSessionRecord>>? _sessionsSubscription;
  
  // 통계 데이터
  double _totalCurrentMah = 0.0; // 총 충전 전류량 (mAh)
  Duration _totalChargingTime = Duration.zero; // 총 충전 시간
  double _avgChargingSpeed = 0.0; // 평균 충전 속도 (mA)
  
  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadChartData();
    // 주기적으로 차트 데이터 새로고침 (오늘 탭일 때만, 30초마다)
    _startAutoRefresh();
  }
  
  Future<void> _initializeService() async {
    try {
      await _sessionService.initialize();
      await _storageService.initialize();
      
      // 오늘 탭일 때만 세션 스트림 구독 (실시간 업데이트)
      _sessionsSubscription = _sessionService.sessionsStream.listen(
        (sessions) {
          // 오늘 탭일 때만 실시간 업데이트
          if (mounted && _selectedTab == '오늘') {
            _updateStatsFromSessions(sessions);
          }
        },
        onError: (error, stackTrace) {
          debugPrint('세션 스트림 오류: $error');
          debugPrint('스택 트레이스: $stackTrace');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('서비스 초기화 실패: $e');
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
  
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      // 오늘 탭일 때만 자동 새로고침 (수동 선택한 날짜는 자동 새로고침 안 함)
      if (_selectedTab == '오늘' && mounted) {
        _loadChartData();
      }
    });
  }

  /// Pull-to-Refresh를 위한 public 메서드
  /// 현재 선택된 날짜의 차트 데이터를 새로고침합니다.
  Future<void> refresh() async {
    await _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.initialize();
      
      DateTime targetDate;
      switch (_selectedTab) {
        case '어제':
          targetDate = DateTime.now().subtract(Duration(days: 1));
          break;
        case '2일 전':
          targetDate = DateTime.now().subtract(Duration(days: 2));
          break;
        case '선택':
          // 수동으로 선택한 날짜 사용
          targetDate = _selectedDate ?? DateTime.now();
          break;
        case '오늘':
        default:
          targetDate = DateTime.now();
          break;
      }
      
      // _selectedTab이 '선택'이 아닐 때만 _selectedDate 업데이트
      if (_selectedTab != '선택') {
        _selectedDate = targetDate;
      }
      
      // 데이터베이스에서 충전 전류 데이터 조회
      final dbData = await _databaseService.getChargingCurrentDataByDate(targetDate);
      
      // ChargingCurrentPoint 리스트로 변환
      final points = dbData.map((row) => ChargingCurrentPoint(
        timestamp: row['timestamp'] as DateTime,
        currentMa: row['currentMa'] as int,
      )).toList();
      
      // 차트 데이터로 변환
      final chartData = ChargingChartService.convertToChartData(
        points,
        targetDate: targetDate,
      );
      
      // 통계 데이터 계산 (모든 탭에 대해)
      await _calculateStats(targetDate);
      
      setState(() {
        _chartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('차트 데이터 로드 실패: $e');
      setState(() {
        _chartData = [];
        _isLoading = false;
      });
    }
  }
  
  /// 통계 데이터 계산 (날짜별)
  Future<void> _calculateStats(DateTime targetDate) async {
    try {
      // 오늘 날짜인지 확인
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final targetDateNormalized = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final isToday = targetDateNormalized.isAtSameMomentAs(todayNormalized);
      
      List<ChargingSessionRecord> sessions;
      
      if (isToday) {
        // 오늘은 실시간 세션 서비스 사용
        sessions = _sessionService.getTodaySessions();
      } else {
        // 과거 날짜는 스토리지에서 조회
        sessions = await _storageService.getSessionsByDate(targetDateNormalized);
      }
      
      // 세션 목록으로 통계 계산
      _updateStatsFromSessions(sessions);
    } catch (e) {
      debugPrint('통계 데이터 계산 실패: $e');
      if (mounted) {
        setState(() {
          _totalCurrentMah = 0.0;
          _totalChargingTime = Duration.zero;
          _avgChargingSpeed = 0.0;
        });
      }
    }
  }
  
  /// 세션 목록으로부터 통계 업데이트 (공통 로직)
  void _updateStatsFromSessions(List<ChargingSessionRecord> sessions) {
    if (!mounted) return;
    
    try {
      // 유의미한 세션만 필터링 (validate()로 검증)
      final validSessions = sessions.where((s) => s.validate()).toList();
      
      if (validSessions.isEmpty) {
        setState(() {
          _totalCurrentMah = 0.0;
          _totalChargingTime = Duration.zero;
          _avgChargingSpeed = 0.0;
        });
        return;
      }
      
      // 총 충전 전류량 계산 (mAh)
      // mAh = (평균 전류(mA) * 충전 시간(시간))
      double totalMah = 0.0;
      Duration totalTime = Duration.zero;
      double totalCurrent = 0.0;
      
      for (final session in validSessions) {
        // 각 세션의 전류량 = 평균 전류 * 시간(시간 단위)
        final hours = session.duration.inMinutes / 60.0;
        totalMah += session.avgCurrent * hours;
        totalTime += session.duration;
        totalCurrent += session.avgCurrent;
      }
      
      // 평균 충전 속도 (mA) - 모든 유의미한 세션의 평균 전류 평균
      final avgSpeed = totalCurrent / validSessions.length;
      
      setState(() {
        _totalCurrentMah = totalMah;
        _totalChargingTime = totalTime;
        _avgChargingSpeed = avgSpeed;
      });
      
      debugPrint('통계 업데이트 완료: ${totalMah.toStringAsFixed(0)}mAh, ${totalTime.inMinutes}분, ${avgSpeed.toStringAsFixed(0)}mA');
    } catch (e) {
      debugPrint('통계 업데이트 실패: $e');
      if (mounted) {
        setState(() {
          _totalCurrentMah = 0.0;
          _totalChargingTime = Duration.zero;
          _avgChargingSpeed = 0.0;
        });
      }
    }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '충전 현황',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isProUser)
                  // Pro 사용자: 상세 분석 버튼
                  TextButton(
                    onPressed: _showDetailedAnalysis,
                    child: Text(
                      '상세 분석',
                      style: TextStyle(fontSize: 13),
                      maxLines: 1,
                    ),
                  )
                else
                  // 무료 사용자: Pro 딱지
                  InkWell(
                    onTap: widget.onProUpgrade,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 탭 선택 + 날짜
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton('오늘'),
                SizedBox(width: 8),
                _buildTabButton('어제'),
                SizedBox(width: 8),
                _buildTabButton('2일 전'),
                Spacer(),
                InkWell(
                  onTap: _showDatePicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        SizedBox(width: 6),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}'
                              : DateTime.now().toString().split(' ')[0].replaceAll('-', '.'),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // 그래프 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 250,
              child: _buildChart(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // 범례
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('저속 (0-500mA)', Colors.blue[400]!),
                _buildLegendItem('일반 (500-1500mA)', Colors.orange[400]!),
                _buildLegendItem('급속 (1500mA+)', Colors.red[400]!),
              ],
            ),
          ),
          
          // 통계 정보 (모든 탭에서 표시)
          SizedBox(height: 20),
          _buildStatsSection(),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
        _loadChartData(); // 차트와 통계 모두 업데이트
        _startAutoRefresh(); // 탭 변경 시 자동 새로고침 재시작
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChart() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.battery_charging_full, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '충전 데이터가 없습니다',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return LineChart(
      ChargingChartService.createChartData(_chartData),
    );
  }
  
  /// 날짜 선택 다이얼로그 표시
  /// 오늘로부터 7일 전까지의 날짜만 선택 가능
  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    // 날짜만 비교하기 위해 시간 제거
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(Duration(days: 7)); // 7일 전
    final lastDate = today; // 오늘
    
    // 초기 날짜 설정 (선택된 날짜가 없으면 오늘)
    final initialDate = _selectedDate ?? today;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '날짜 선택 (최근 7일)',
      cancelText: '취소',
      confirmText: '확인',
      selectableDayPredicate: (date) {
        // 선택 가능한 날짜 범위 체크 (7일 전 ~ 오늘)
        final dateOnly = DateTime(date.year, date.month, date.day);
        final daysDiff = today.difference(dateOnly).inDays;
        return daysDiff >= 0 && daysDiff <= 7;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      // 날짜만 사용 (시간 제거)
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      setState(() {
        _selectedDate = selectedDateOnly;
        _selectedTab = '선택'; // 탭을 '선택'으로 변경하여 수동 선택임을 표시
      });
      _loadChartData();
    }
  }
  
  /// 통계 정보 섹션 빌드
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.battery_charging_full,
                iconColor: Colors.blue,
                value: _formatMah(_totalCurrentMah),
                label: '총 충전 전류량',
                unit: 'mAh',
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.access_time,
                iconColor: Colors.orange,
                value: _formatDuration(_totalChargingTime),
                label: '총 충전 시간',
                unit: '',
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.speed,
                iconColor: Colors.green,
                value: _formatSpeed(_avgChargingSpeed),
                label: '평균 충전 속도',
                unit: 'mA',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 통계 항목 빌드
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String unit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  /// mAh 포맷팅
  String _formatMah(double mah) {
    if (mah < 1) return '0';
    if (mah < 1000) {
      return mah.toStringAsFixed(0);
    }
    return '${(mah / 1000).toStringAsFixed(2)}k';
  }
  
  /// Duration 포맷팅
  String _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) return '0';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours시간 $minutes분';
      }
      return '$hours시간';
    }
    return '$minutes분';
  }
  
  /// 속도 포맷팅
  String _formatSpeed(double speed) {
    if (speed < 1) return '0';
    if (speed < 1000) {
      return speed.toStringAsFixed(0);
    }
    return '${(speed / 1000).toStringAsFixed(2)}k';
  }
  
  void _showDetailedAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.purple),
            SizedBox(width: 8),
            Text('상세 충전 분석'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 고급 분석 기능:'),
            SizedBox(height: 8),
            Text('• 시간대별 충전 효율 분석'),
            Text('• 온도 변화 패턴 추적'),
            Text('• 충전 속도 최적화 제안'),
            Text('• 배터리 수명 예측'),
            SizedBox(height: 16),
            Text('이 기능은 Pro 사용자 전용입니다.', 
                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
