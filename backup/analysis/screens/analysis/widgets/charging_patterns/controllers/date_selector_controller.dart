import 'package:flutter/material.dart';

/// 날짜 선택 탭 타입
enum DateTab {
  today,
  yesterday,
  twoDaysAgo,
  custom,
}

/// 날짜 선택을 관리하는 컨트롤러
/// 
/// 날짜 선택 탭 관리, 날짜 선택 다이얼로그, 날짜 표시 텍스트 등을 담당합니다.
class DateSelectorController extends ChangeNotifier {
  /// 현재 선택된 탭
  DateTab _selectedTab = DateTab.today;
  
  /// 수동으로 선택한 날짜 (custom 탭일 때 사용)
  DateTime? _selectedDate;
  
  /// 날짜 변경 콜백
  Function(DateTime)? onDateChanged;
  
  /// 현재 선택된 탭 가져오기
  DateTab get selectedTab => _selectedTab;
  
  /// 현재 선택된 날짜 가져오기
  DateTime? get selectedDate => _selectedDate;
  
  /// 현재 선택한 날짜 가져오기 (계산된 날짜)
  DateTime getCurrentDate() {
    switch (_selectedTab) {
      case DateTab.today:
        return DateTime.now();
      case DateTab.yesterday:
        return DateTime.now().subtract(const Duration(days: 1));
      case DateTab.twoDaysAgo:
        return DateTime.now().subtract(const Duration(days: 2));
      case DateTab.custom:
        return _selectedDate ?? DateTime.now();
    }
  }
  
  /// 선택한 날짜의 표시 텍스트 가져오기
  String getDateDisplayText() {
    switch (_selectedTab) {
      case DateTab.today:
        return '오늘';
      case DateTab.yesterday:
        return '어제';
      case DateTab.twoDaysAgo:
        return '2일 전';
      case DateTab.custom:
        if (_selectedDate != null) {
          return '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}';
        }
        return '선택';
    }
  }
  
  /// 통계 카드의 날짜 단위 텍스트 가져오기
  String getDateUnitText() {
    switch (_selectedTab) {
      case DateTab.today:
        return '(오늘)';
      case DateTab.yesterday:
        return '(어제)';
      case DateTab.twoDaysAgo:
        return '(2일 전)';
      case DateTab.custom:
        if (_selectedDate != null) {
          return '(${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')})';
        }
        return '(선택)';
    }
  }
  
  /// 탭 이름을 DateTab으로 변환
  static DateTab tabFromString(String tab) {
    switch (tab) {
      case '오늘':
        return DateTab.today;
      case '어제':
        return DateTab.yesterday;
      case '2일 전':
        return DateTab.twoDaysAgo;
      case '선택':
        return DateTab.custom;
      default:
        return DateTab.today;
    }
  }
  
  /// DateTab을 탭 이름으로 변환
  static String tabToString(DateTab tab) {
    switch (tab) {
      case DateTab.today:
        return '오늘';
      case DateTab.yesterday:
        return '어제';
      case DateTab.twoDaysAgo:
        return '2일 전';
      case DateTab.custom:
        return '선택';
    }
  }
  
  /// 탭 선택
  /// 
  /// [tab]: 선택할 탭
  void selectTab(DateTab tab) {
    if (_selectedTab == tab) return;
    
    _selectedTab = tab;
    
    // 탭 변경 시 날짜 업데이트
    if (tab != DateTab.custom) {
      switch (tab) {
        case DateTab.yesterday:
          _selectedDate = DateTime.now().subtract(const Duration(days: 1));
          break;
        case DateTab.twoDaysAgo:
          _selectedDate = DateTime.now().subtract(const Duration(days: 2));
          break;
        case DateTab.today:
          _selectedDate = DateTime.now();
          break;
        case DateTab.custom:
          // custom은 변경하지 않음
          break;
      }
    }
    
    notifyListeners();
    onDateChanged?.call(getCurrentDate());
  }
  
  /// 날짜 선택 다이얼로그 표시
  /// 
  /// [context]: BuildContext
  /// [maxDaysBack]: 오늘로부터 몇 일 전까지 선택 가능한지 (기본 7일)
  /// 
  /// Returns: 선택된 날짜 또는 null
  Future<DateTime?> showDatePickerDialog(
    BuildContext context, {
    int maxDaysBack = 7,
  }) async {
    final now = DateTime.now();
    // 날짜만 비교하기 위해 시간 제거
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(Duration(days: maxDaysBack));
    final lastDate = today; // 오늘
    
    // 초기 날짜 설정 (선택된 날짜가 없으면 오늘)
    final initialDate = _selectedDate ?? today;
    
    // 날짜가 범위를 벗어나면 today로 설정
    final safeInitialDate = initialDate.isBefore(firstDate) || initialDate.isAfter(lastDate)
        ? today
        : initialDate;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '날짜 선택 (최근 $maxDaysBack일)',
      cancelText: '취소',
      confirmText: '확인',
      selectableDayPredicate: (date) {
        // 선택 가능한 날짜 범위 체크
        final dateOnly = DateTime(date.year, date.month, date.day);
        final daysDiff = today.difference(dateOnly).inDays;
        return daysDiff >= 0 && daysDiff <= maxDaysBack;
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
      
      // 선택한 날짜가 범위를 벗어나지 않는지 확인
      final daysDiff = today.difference(selectedDateOnly).inDays;
      if (daysDiff < 0 || daysDiff > maxDaysBack) {
        debugPrint('DateSelectorController: 선택한 날짜가 범위를 벗어남 - $selectedDateOnly');
        return null;
      }
      
      _selectedDate = selectedDateOnly;
      _selectedTab = DateTab.custom;
      
      notifyListeners();
      onDateChanged?.call(getCurrentDate());
      
      return selectedDateOnly;
    }
    
    return null;
  }
  
  /// 오늘 날짜로 초기화
  void resetToToday() {
    _selectedTab = DateTab.today;
    _selectedDate = DateTime.now();
    notifyListeners();
    onDateChanged?.call(getCurrentDate());
  }
  
  /// 오늘 탭인지 확인
  bool get isToday => _selectedTab == DateTab.today;
  
  /// 커스텀 날짜가 선택되었는지 확인
  bool get isCustom => _selectedTab == DateTab.custom;
}

