import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/charging_chart_service.dart';
import '../models/charging_data_models.dart';
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
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadChartData();
    // 주기적으로 차트 데이터 새로고침 (오늘 탭일 때만, 30초마다)
    _startAutoRefresh();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
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
                Text('📊', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '충전 전류 패턴',
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
        _loadChartData();
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
