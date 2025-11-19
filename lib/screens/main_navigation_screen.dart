import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home_tab.dart';
import 'analysis/analysis_tab.dart';
import 'settings/settings_tab.dart';
import '../services/battery_optimization_helper.dart';

/// 메인 네비게이션 화면
/// Phase 8에서 실제 구현
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  
  // Pro 모드 상태 관리 (실제 결제 시스템과 연동 예정)
  // ignore: prefer_final_fields
  bool _isProUser = false;
  
  // 분석 탭의 초기 탭 인덱스
  int _analysisTabInitialIndex = 0;
  
  // 배터리 최적화 예외 요청 표시 여부 (중복 방지)
  bool _hasShownBatteryOptimizationPrompt = false;

  // 3개 탭 페이지들 (Pro 상태 전달)
  List<Widget> get _pages => [
    HomeTab(
      isProUser: _isProUser,
      onProToggle: _handleProUpgrade,
    ),
    AnalysisTab(
      isProUser: _isProUser,
      onProToggle: _handleProUpgrade,
      initialTabIndex: _analysisTabInitialIndex,
    ),
    SettingsTab(isProUser: _isProUser, onProToggle: _handleProUpgrade),
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 앱 초기 실행 시 배터리 최적화 예외 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestBatteryOptimization();
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
    
    // 앱이 포그라운드로 돌아올 때 배터리 최적화 상태 재확인
    if (state == AppLifecycleState.resumed) {
      // 사용자가 설정에서 변경했을 수 있으므로 다시 확인
      _checkBatteryOptimizationOnResume();
    }
  }
  
  /// 앱 초기 실행 여부 확인
  Future<bool> _isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      
      if (isFirstLaunch) {
        // 첫 실행 플래그를 false로 설정
        await prefs.setBool('is_first_launch', false);
      }
      
      return isFirstLaunch;
    } catch (e) {
      debugPrint('앱 초기 실행 확인 실패: $e');
      return false;
    }
  }
  
  /// 배터리 최적화 예외 확인 및 요청 (앱 초기 실행 시)
  Future<void> _checkAndRequestBatteryOptimization() async {
    // 이미 표시했으면 다시 표시하지 않음
    if (_hasShownBatteryOptimizationPrompt) {
      return;
    }
    
    try {
      // 앱이 완전히 로드될 때까지 약간 대기
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // 앱 초기 실행 여부 확인
      final isFirstLaunch = await _isFirstLaunch();
      
      // 초기 실행이 아니면 배터리 최적화 예외가 설정되어 있는지만 확인
      if (!isFirstLaunch) {
        final isIgnoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
        if (isIgnoring) {
          debugPrint('배터리 최적화 예외가 이미 설정되어 있습니다');
        }
        return;
      }
      
      // 초기 실행이면 배터리 최적화 예외 요청
      if (!mounted) return;
      
      final isIgnoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
      if (!isIgnoring) {
        // 배터리 최적화 예외가 설정되지 않았으면 다이얼로그 표시
        _hasShownBatteryOptimizationPrompt = true;
        await BatteryOptimizationHelper.requestBatteryOptimizationException(context);
      }
    } catch (e) {
      debugPrint('배터리 최적화 예외 확인 및 요청 실패: $e');
    }
  }
  
  /// 앱 포그라운드 복귀 시 배터리 최적화 상태 재확인
  Future<void> _checkBatteryOptimizationOnResume() async {
    try {
      // 사용자가 설정에서 변경했을 수 있으므로 확인
      final isIgnoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
      
      if (isIgnoring) {
        debugPrint('배터리 최적화 예외가 설정되어 있습니다');
        // 설정되어 있으면 플래그 리셋 (다음 초기 실행 시 다시 표시할 수 있도록)
        _hasShownBatteryOptimizationPrompt = false;
      }
    } catch (e) {
      debugPrint('배터리 최적화 상태 재확인 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // 분석 탭을 직접 선택할 때는 기본 탭(배터리 탭)으로 리셋
            if (index == 1) {
              _analysisTabInitialIndex = 0;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  // Pro 업그레이드 처리 (실제 결제 시스템과 연동 예정)
  void _handleProUpgrade() {
    // 실제 결제 시스템과 연동 예정 - 인앱 결제, 구독 관리 등
    // 현재는 개발용으로 간단한 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 업그레이드'),
        content: const Text('Pro 기능을 사용하려면 업그레이드가 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 실제 결제 프로세스 시작 예정 - Google Play Billing, App Store Connect 등
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }
}
