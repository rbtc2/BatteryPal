import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../services/hourly_discharge_calculator.dart';

/// 시간대별 소모 그래프 - 시간대별 배터리 소모 패턴을 표시하는 위젯
/// 
/// fl_chart의 BarChart를 사용하여 시간대별 배터리 소모 그래프를 시각화합니다.
class DrainHourlyChart extends StatefulWidget {
  final bool isProUser;
  final VoidCallback? onProUpgrade;
  final DateTime? targetDate; // 선택된 날짜 (null이면 오늘)

  const DrainHourlyChart({
    super.key,
    required this.isProUser,
    this.onProUpgrade,
    this.targetDate,
  });

  @override
  State<DrainHourlyChart> createState() => _DrainHourlyChartState();
}

class _DrainHourlyChartState extends State<DrainHourlyChart> {
  /// 시간대별 소모량 데이터 (시간대 → 소모량 %)
  /// 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22 시간대 (12개)
  Map<int, double>? _hourlyDischargeData;
  
  /// 로딩 상태
  bool _isLoading = false;
  
  /// 에러 상태
  String? _errorMessage;
  
  /// 계산기 서비스
  final HourlyDischargeCalculator _calculator = HourlyDischargeCalculator();
  
  /// 이전 날짜 (날짜 변경 감지용)
  DateTime? _previousDate;

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHourlyDischargeData();
    });
  }

  @override
  void didUpdateWidget(DrainHourlyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 날짜가 변경되었으면 데이터 다시 로드
    final currentDate = _getTargetDate();
    final oldDate = oldWidget.targetDate ?? _getTodayDate();
    
    if (!_isSameDate(currentDate, oldDate)) {
      _loadHourlyDischargeData();
    }
  }

  /// 현재 대상 날짜 가져오기
  DateTime _getTargetDate() {
    return widget.targetDate ?? _getTodayDate();
  }

  /// 오늘 날짜 가져오기 (시간 제거)
  DateTime _getTodayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 두 날짜가 같은 날인지 확인
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 시간대별 소모 데이터 로드
  Future<void> _loadHourlyDischargeData() async {
    if (_isLoading) return;
    
    final targetDate = _getTargetDate();
    
    // 같은 날짜면 스킵
    if (_previousDate != null && _isSameDate(targetDate, _previousDate!)) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previousDate = targetDate;
    });
    
    try {
      debugPrint('시간대별 소모 데이터 로드 시작: ${targetDate.toString().split(' ')[0]}');
      
      final hourlyData = await _calculator.calculateHourlyDischargeForDate(targetDate);
      
      if (mounted) {
        setState(() {
          _hourlyDischargeData = hourlyData;
          _isLoading = false;
        });
        
        debugPrint('시간대별 소모 데이터 로드 완료: $hourlyData');
      }
    } catch (e, stackTrace) {
      debugPrint('시간대별 소모 데이터 로드 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      if (mounted) {
        setState(() {
          // 에러 타입에 따라 다른 메시지 표시
          if (e.toString().contains('database') || e.toString().contains('Database')) {
            _errorMessage = '데이터베이스 오류가 발생했습니다';
          } else if (e.toString().contains('network') || e.toString().contains('Network')) {
            _errorMessage = '네트워크 오류가 발생했습니다';
          } else {
            _errorMessage = '데이터를 불러올 수 없습니다';
          }
          _isLoading = false;
        });
      }
    }
  }

  /// Pull-to-Refresh를 위한 public 메서드
  Future<void> refresh() async {
    // 이전 날짜를 초기화하여 강제로 다시 로드
    _previousDate = null;
    await _loadHourlyDischargeData();
  }
  
  /// 시간대별 소모량 데이터를 리스트로 변환 (차트용)
  /// 시간대 순서대로 정렬: 0, 2, 4, ..., 22
  List<double> _getDischargeDataList() {
    if (_hourlyDischargeData == null || _hourlyDischargeData!.isEmpty) {
      return List.filled(12, 0.0);
    }
    
    final hourSlots = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];
    return hourSlots.map((hour) => _hourlyDischargeData![hour] ?? 0.0).toList();
  }
  
  /// 피크 시간대 정보 가져오기
  ({int hour, double discharge, double rate})? _getPeakHour() {
    if (_hourlyDischargeData == null || _hourlyDischargeData!.isEmpty) {
      return null;
    }
    
    return _calculator.getPeakHour(_hourlyDischargeData!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '시간대별 배터리 소모 그래프',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          
          // 차트 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 200,
              child: _isLoading
                  ? _buildLoadingIndicator(theme)
                  : _errorMessage != null
                      ? _buildErrorWidget(theme)
                      : _hourlyDischargeData == null || _hourlyDischargeData!.isEmpty
                          ? _buildEmptyDataWidget(theme)
                          : _buildChart(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 피크 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPeakInfo(theme),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 로딩 인디케이터 빌드
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '데이터 로딩 중...',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 위젯 빌드
  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: theme.colorScheme.error.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// 빈 데이터 위젯 빌드
  Widget _buildEmptyDataWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 32,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            '해당 날짜의 데이터가 없습니다',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 피크 정보 빌드
  Widget _buildPeakInfo(ThemeData theme) {
    final peak = _getPeakHour();
    
    if (peak == null) {
      return Text(
        '피크: -- (--% 소모, --%/h)',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }
    
    return Text(
      '피크: ${peak.hour}시 (${peak.discharge.toStringAsFixed(1)}% 소모, ${peak.rate.toStringAsFixed(1)}%/h)',
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  /// 차트 빌드
  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    
    // Pro 업그레이드 그라데이션 색상
    final gradientStartColor = isLightMode 
        ? Colors.green[400]!
        : theme.colorScheme.primary;
    final gradientEndColor = isLightMode
        ? Colors.teal[400]!
        : theme.colorScheme.primary.withValues(alpha: 0.8);
    
    // 실제 데이터 가져오기
    final dataList = _getDischargeDataList();
    
    // Y축 최대값 및 간격 계산
    final yAxisConfig = _calculateYAxisConfig(dataList);
    
    return BarChart(
      BarChartData(
        maxY: yAxisConfig.maxValue,
        minY: 0,
        barGroups: List.generate(12, (index) {
          final hour = index * 2; // 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
          final value = dataList[index];
          
          // 그라데이션 효과: 인덱스에 따라 색상 보간 (0 → 1)
          final t = index / 11; // 0.0 ~ 1.0
          final barColor = Color.lerp(gradientStartColor, gradientEndColor, t)!;
          
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final value = rod.toY;
              final nextHour = hour + 2;
              final hourRange = nextHour >= 24 
                  ? '$hour-24시' 
                  : '$hour-$nextHour시';
              
              // 소모 속도 계산 (2시간 구간이므로)
              final rate = value / 2.0;
              
              return BarTooltipItem(
                '$hourRange\n${value.toStringAsFixed(2)}% 소모\n${rate.toStringAsFixed(2)}%/h',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yAxisConfig.interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour >= 0 && hour <= 22 && hour % 2 == 0) {
                  return Text(
                    '$hour',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yAxisConfig.interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
    );
  }
  
  /// Y축 설정 계산 (최대값, 간격)
  /// 
  /// 데이터에 따라 적절한 Y축 최대값과 간격을 계산합니다.
  ({double maxValue, double interval}) _calculateYAxisConfig(List<double> dataList) {
    if (dataList.isEmpty) {
      return (maxValue: 2.0, interval: 0.5);
    }
    
    final maxDataValue = dataList.reduce((a, b) => a > b ? a : b);
    
    if (maxDataValue <= 0) {
      return (maxValue: 2.0, interval: 0.5);
    }
    
    // 최대값을 1.2배로 증가시키고 적절한 간격으로 반올림
    final rawMax = maxDataValue * 1.2;
    
    // 간격 계산: 최대값에 따라 적절한 간격 선택
    double interval;
    double maxValue;
    
    if (rawMax <= 1.0) {
      interval = 0.2;
      maxValue = (rawMax / interval).ceil() * interval;
    } else if (rawMax <= 5.0) {
      interval = 0.5;
      maxValue = (rawMax / interval).ceil() * interval;
    } else if (rawMax <= 10.0) {
      interval = 1.0;
      maxValue = (rawMax / interval).ceil() * interval;
    } else if (rawMax <= 20.0) {
      interval = 2.0;
      maxValue = (rawMax / interval).ceil() * interval;
    } else {
      interval = 5.0;
      maxValue = (rawMax / interval).ceil() * interval;
    }
    
    // 최소값 보장
    if (maxValue < 2.0) {
      maxValue = 2.0;
    }
    
    return (maxValue: maxValue, interval: interval);
  }
}

