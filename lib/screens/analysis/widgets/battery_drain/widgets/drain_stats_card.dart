import 'package:flutter/material.dart';
import '../../charging_patterns/widgets/stat_card.dart';
import '../../../../../services/discharge_current_calculator.dart';
import '../../../../../services/screen_time_service.dart';

/// 소모 통계 카드 - 배터리 소모량 통계를 표시하는 위젯
/// 
/// 날짜별 소모 통계를 표시합니다.
/// - 총 소모량, 소모 전류
/// - 평균 속도, 최대 속도
/// - 화면 켜짐 시간, 1% 평균 시간
class DrainStatsCard extends StatefulWidget {
  final ValueChanged<DateTime>? onDateChanged; // 날짜 변경 콜백
  
  const DrainStatsCard({
    super.key,
    this.onDateChanged,
  });

  @override
  State<DrainStatsCard> createState() => _DrainStatsCardState();
}

class _DrainStatsCardState extends State<DrainStatsCard> with WidgetsBindingObserver {
  /// 선택된 날짜 탭 (0: 오늘, 1: 어제, 2: 2일 전, 3: 커스텀)
  int _selectedDateTab = 0;
  
  /// 수동으로 선택한 날짜 (커스텀 탭일 때 사용)
  DateTime? _selectedDate;
  
  // 소모 전류 관련 상태
  int? _dischargeCurrent; // mAh
  bool _isLoadingDischargeCurrent = false;
  bool _hasLoaded = false;
  
  // 화면 켜짐 시간 관련 상태
  double? _screenOnTime; // 시간 단위
  bool _isLoadingScreenTime = false;
  bool _hasUsageStatsPermission = false;
  
  final DischargeCurrentCalculator _calculator = DischargeCurrentCalculator();
  final ScreenTimeService _screenTimeService = ScreenTimeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 탭 진입 시 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 초기 날짜 콜백 호출
      final targetDate = _getTargetDate();
      widget.onDateChanged?.call(targetDate);
      
      _calculateDischargeCurrent();
      _checkUsageStatsPermission(); // 권한 확인
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포그라운드로 돌아올 때 권한 상태 다시 확인
    if (state == AppLifecycleState.resumed) {
      _checkUsageStatsPermission();
    }
  }

  /// Pull-to-Refresh를 위한 public 메서드
  Future<void> refresh() async {
    await _calculateDischargeCurrent(forceRefresh: true);
    if (_hasUsageStatsPermission) {
      await _loadScreenOnTime(forceRefresh: true);
    }
  }
  
  /// 현재 선택된 날짜 가져오기 (public 메서드)
  /// 다른 위젯에서 날짜를 가져올 수 있도록 제공
  DateTime getTargetDate() {
    return _getTargetDate();
  }
  
  /// 날짜 변경 시 재계산
  void _onDateChanged() {
    setState(() {
      _hasLoaded = false; // 날짜 변경 시 리셋
    });
    
    // 날짜 변경 콜백 호출
    final targetDate = _getTargetDate();
    widget.onDateChanged?.call(targetDate);
    
    _calculateDischargeCurrent(forceRefresh: true);
    if (_hasUsageStatsPermission) {
      _loadScreenOnTime(forceRefresh: true);
    }
  }
  
  /// 방전 전류 계산
  Future<void> _calculateDischargeCurrent({bool forceRefresh = false}) async {
    if (_isLoadingDischargeCurrent && !forceRefresh) {
      return; // 이미 로딩 중이면 중복 호출 방지
    }
    
    if (!forceRefresh && _hasLoaded) {
      return; // 이미 로드되었으면 건너뜀 (탭 진입 시에만)
    }
    
    setState(() {
      _isLoadingDischargeCurrent = true;
    });
    
    try {
      final targetDate = _getTargetDate();
      final dischargeCurrent = await _calculator.calculateDischargeCurrentForDate(targetDate);
      
      if (mounted) {
        setState(() {
          _dischargeCurrent = dischargeCurrent >= 0 ? dischargeCurrent : null;
          _isLoadingDischargeCurrent = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('방전 전류 계산 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingDischargeCurrent = false;
        });
      }
    }
  }
  
  /// 선택된 날짜 가져오기
  DateTime _getTargetDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedDate != null) {
      return _selectedDate!;
    }
    
    switch (_selectedDateTab) {
      case 0: // 오늘
        return today;
      case 1: // 어제
        return today.subtract(const Duration(days: 1));
      case 2: // 2일 전
        return today.subtract(const Duration(days: 2));
      default:
        return today;
    }
  }

  /// 표시할 날짜 가져오기 (달력 표시용)
  DateTime _getDisplayDate() {
    // 커스텀 날짜가 선택되어 있으면 그 날짜 반환
    if (_selectedDate != null) {
      return _selectedDate!;
    }
    
    // 탭이 선택되어 있으면 해당 날짜 반환
    return _getTargetDate();
  }

  /// 날짜를 표시 형식으로 변환 (YYYY.MM.DD)
  String _formatDisplayDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 소모 전류 표시 텍스트
  String _getDischargeCurrentText() {
    if (_isLoadingDischargeCurrent) {
      return '계산 중...';
    }
    
    if (_dischargeCurrent == null) {
      return '--';
    }
    
    if (_dischargeCurrent! < 0) {
      return '알 수 없음';
    }
    
    return _dischargeCurrent!.toString();
  }
  
  /// 소모 전류 서브 텍스트
  String _getDischargeCurrentSubText() {
    if (_isLoadingDischargeCurrent) {
      return '계산 중...';
    }
    
    if (_dischargeCurrent == null || _dischargeCurrent! < 0) {
      return '알 수 없음';
    }
    
    return '총 소모량';
  }

  /// Usage Stats 권한 확인 및 화면 켜짐 시간 로드
  Future<void> _checkUsageStatsPermission() async {
    final hasPermission = await _screenTimeService.hasUsageStatsPermission();
    setState(() {
      _hasUsageStatsPermission = hasPermission;
    });
    
    if (hasPermission) {
      await _loadScreenOnTime();
    }
  }

  /// 화면 켜짐 시간 로드
  Future<void> _loadScreenOnTime({bool forceRefresh = false}) async {
    if (_isLoadingScreenTime && !forceRefresh) {
      return;
    }
    
    setState(() {
      _isLoadingScreenTime = true;
    });
    
    try {
      final targetDate = _getTargetDate();
      final screenOnTime = await _screenTimeService.getScreenOnTimeForDate(targetDate);
      
      if (mounted) {
        setState(() {
          _screenOnTime = screenOnTime;
          _isLoadingScreenTime = false;
        });
      }
    } catch (e) {
      debugPrint('화면 켜짐 시간 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingScreenTime = false;
        });
      }
    }
  }

  /// 화면 켜짐 시간 표시 텍스트 (전체 문자열, 숫자 강조용)
  String _getScreenOnTimeText() {
    if (!_hasUsageStatsPermission) {
      return '권한 필요';
    }
    
    if (_isLoadingScreenTime) {
      return '계산 중...';
    }
    
    if (_screenOnTime == null) {
      return '--';
    }
    
    // 숫자 강조를 위해 전체 문자열 반환
    return _formatScreenOnTimeFullText(_screenOnTime!);
  }

  /// 화면 켜짐 시간의 전체 텍스트 반환 (예: "1시간 7분")
  String _formatScreenOnTimeFullText(double hours) {
    final totalMinutes = (hours * 60).round();
    final displayHours = totalMinutes ~/ 60;
    final displayMinutes = totalMinutes % 60;
    
    final List<String> parts = [];
    
    if (displayHours > 0) {
      parts.add('$displayHours시간');
      if (displayMinutes > 0) {
        parts.add('$displayMinutes분');
      }
    } else if (displayMinutes > 0) {
      parts.add('$displayMinutes분');
    } else {
      return '0분';
    }
    
    return parts.join(' ');
  }

  /// 화면 켜짐 서브 텍스트
  String _getScreenOnTimeSubText() {
    if (!_hasUsageStatsPermission) {
      return '설정에서 허용';
    }
    
    if (_isLoadingScreenTime || _screenOnTime == null) {
      return '알 수 없음';
    }
    
    return '오늘 사용 시간';
  }

  /// Usage Stats 권한 요청 다이얼로그
  Future<void> _showUsageStatsPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용 통계 권한 필요'),
        content: const Text(
          '화면 켜짐 시간을 추적하려면 사용 통계 접근 권한이 필요합니다.\n\n'
          '설정 화면에서 "Batterypal" 앱을 찾아 사용 통계 접근을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _screenTimeService.openUsageStatsSettings();
      // 설정에서 돌아왔을 때 권한 다시 확인
      Future.delayed(const Duration(seconds: 1), () {
        _checkUsageStatsPermission();
      });
    }
  }
  
  /// 날짜 선택 다이얼로그 표시
  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 7)); // 7일 전
    final lastDate = today; // 오늘
    
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
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      setState(() {
        _selectedDate = selectedDateOnly;
        _selectedDateTab = 3; // 커스텀 탭으로 변경
      });
      // 날짜 변경 시 재계산
      _onDateChanged();
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '소모 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // 날짜 선택 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDateTab(context, '오늘', 0),
                const SizedBox(width: 8),
                _buildDateTab(context, '어제', 1),
                const SizedBox(width: 8),
                _buildDateTab(context, '2일 전', 2),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await _showDatePicker(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _formatDisplayDate(_getDisplayDate()),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 통계 카드 그리드 (2x3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 총 소모량
                StatCard(
                  title: '총 소모량',
                  mainValue: '--',
                  unit: '%',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.orange,
                  icon: Icons.battery_std,
                ),
                
                // 소모 전류
                StatCard(
                  title: '소모 전류',
                  mainValue: _getDischargeCurrentText(),
                  unit: 'mAh',
                  subValue: _getDischargeCurrentSubText(),
                  trend: '--',
                  trendColor: Colors.red,
                  icon: Icons.bolt,
                ),
                
                // 평균 속도
                StatCard(
                  title: '평균 속도',
                  mainValue: '--',
                  unit: '%/h',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.blue,
                  icon: Icons.trending_down,
                ),
                
                // 최대 속도
                StatCard(
                  title: '최대 속도',
                  mainValue: '--',
                  unit: '%/h',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.purple,
                  icon: Icons.speed,
                ),
                
                // 화면 켜짐
                GestureDetector(
                  onTap: !_hasUsageStatsPermission 
                      ? () async {
                          // 권한 요청 다이얼로그 표시
                          await _showUsageStatsPermissionDialog(context);
                        }
                      : null,
                  child: StatCard(
                    title: '화면 켜짐',
                    mainValue: _getScreenOnTimeText(),
                    unit: '', // 숫자 강조 모드에서는 빈 문자열
                    subValue: _getScreenOnTimeSubText(),
                    trend: '--',
                    trendColor: Colors.green,
                    icon: Icons.phone_android,
                    highlightNumbers: true, // 숫자만 크게 표시
                  ),
                ),
                
                // 1% 소모 평균 시간
                StatCard(
                  title: '1% 소모 평균 시간',
                  mainValue: '--',
                  unit: '분',
                  subValue: '알 수 없음',
                  trend: '--',
                  trendColor: Colors.teal,
                  icon: Icons.timer,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 날짜 탭 버튼 빌드
  Widget _buildDateTab(BuildContext context, String label, int index) {
    final isSelected = _selectedDateTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDateTab = index;
          if (index != 3) {
            _selectedDate = null; // 탭 선택 시 커스텀 날짜 초기화
          }
        });
        // 날짜 변경 시 재계산
        _onDateChanged();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}

