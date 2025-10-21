import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/battery_service.dart';
import '../../models/app_models.dart';
import '../../widgets/home/battery_status_card.dart';
import '../../widgets/home/battery_boost_button.dart';
import '../../widgets/home/usage_limit_card.dart';
import '../../widgets/home/charging_analysis_card.dart';
import '../../utils/app_utils.dart';

/// 홈 탭 화면
/// Phase 5에서 실제 구현
class HomeTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;

  const HomeTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 배터리 서비스
  final BatteryService _batteryService = BatteryService();
  
  // 스켈레톤용 더미 데이터
  int remainingHours = 4;
  int remainingMinutes = 30;
  int batteryTemp = 32;
  int dailyUsage = 2;
  int dailyLimit = 3;
  
  // 실제 배터리 정보
  BatteryInfo? _batteryInfo;
  bool _isRefreshing = false;
  
  // 주기적 새로고침 타이머
  Timer? _periodicRefreshTimer;
  
  // 주기적 새로고침 간격 (초)
  static const int _refreshIntervalSeconds = 30;
  
  // 충전 전류 변화 감지를 위한 이전 값
  int _previousChargingCurrent = -1;
  
  // 배터리 정보 스트림 구독 관리
  StreamSubscription<BatteryInfo>? _batteryInfoSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBatteryService();
    _setupAppLifecycleListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 탭 복귀 시 배터리 정보 즉시 새로고침
    debugPrint('홈 탭: didChangeDependencies - 탭 복귀 감지');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 스트림 구독이 없다면 재생성
      if (_batteryInfoSubscription == null) {
        debugPrint('홈 탭: 스트림 구독이 없음, 재생성 시도');
        _setupBatteryInfoStream();
      }
      
      _refreshBatteryInfoIfNeeded();
      
      // 현재 배터리 정보가 있다면 즉시 UI 업데이트
      final currentInfo = _batteryService.currentBatteryInfo;
      if (currentInfo != null && mounted) {
        setState(() {
          _batteryInfo = currentInfo;
        });
        debugPrint('홈 탭: 탭 복귀 시 기존 배터리 정보 복원 - ${currentInfo.formattedLevel}');
      }
    });
  }

  /// 필요시 배터리 정보 새로고침 (탭 복귀 시 강화)
  void _refreshBatteryInfoIfNeeded() {
    if (_batteryInfo == null) {
      debugPrint('홈 탭: 배터리 정보가 없음, 강제 새로고침 시도');
      _batteryService.refreshBatteryInfo();
    } else {
      // 탭 복귀 시에는 항상 최신 정보로 새로고침
      debugPrint('홈 탭: 탭 복귀 시 최신 정보 새로고침');
      _batteryService.refreshBatteryInfo();
    }
  }
  
  /// 배터리 정보 스트림 구독 설정
  void _setupBatteryInfoStream() {
    debugPrint('홈 탭: 배터리 정보 스트림 구독 설정');
    
    // 기존 구독 정리
    _batteryInfoSubscription?.cancel();
    
    // 새로운 스트림 구독 생성
    _batteryInfoSubscription = _batteryService.batteryInfoStream.listen((batteryInfo) {
      debugPrint('홈 탭: 배터리 정보 수신 - ${batteryInfo.toString()}');
      
      // 충전 전류 변화 감지
      if (_batteryInfo != null && batteryInfo.isCharging) {
        final currentChargingCurrent = batteryInfo.chargingCurrent;
        if (_previousChargingCurrent != currentChargingCurrent && currentChargingCurrent >= 0) {
          debugPrint('홈 탭: 충전 전류 변화 감지 - ${_previousChargingCurrent}mA → ${currentChargingCurrent}mA');
          _previousChargingCurrent = currentChargingCurrent;
        }
      }
      
      if (mounted) {
        setState(() {
          _batteryInfo = batteryInfo;
        });
        debugPrint('홈 탭: UI 업데이트 완료 - 배터리 레벨: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('홈 탭: 위젯이 마운트되지 않음, UI 업데이트 건너뜀');
      }
    });
    
    debugPrint('홈 탭: 배터리 정보 스트림 구독 설정 완료');
  }

  @override
  void dispose() {
    debugPrint('홈 탭: dispose 시작');
    
    // 스트림 구독 정리
    _batteryInfoSubscription?.cancel();
    _batteryInfoSubscription = null;
    
    // 주기적 새로고침만 중지 (배터리 절약)
    _stopPeriodicRefresh();
    
    // 배터리 서비스는 전역 싱글톤이므로 dispose하지 않음
    // 탭 전환 시에도 서비스가 계속 작동하도록 유지
    // _batteryService.stopMonitoring(); // 제거
    // _batteryService.dispose(); // 제거
    
    debugPrint('홈 탭: dispose 완료 (배터리 서비스 유지)');
    super.dispose();
  }

  /// 배터리 서비스 초기화
  Future<void> _initializeBatteryService() async {
    debugPrint('홈 탭: 배터리 서비스 초기화 시작');
    
    try {
      // 기존 배터리 정보 초기화
      if (mounted) {
        setState(() {
          _batteryInfo = null;
        });
      }
      
      // 배터리 서비스 상태 초기화 (앱 시작 시)
      await _batteryService.resetService();
      
      // 배터리 모니터링 시작
      await _batteryService.startMonitoring();
      debugPrint('홈 탭: 배터리 모니터링 시작 완료');
      
      // 현재 배터리 정보 즉시 가져오기 (강제 새로고침)
      await _batteryService.refreshBatteryInfo();
      final currentBatteryInfo = _batteryService.currentBatteryInfo;
      
      if (currentBatteryInfo != null && mounted) {
        debugPrint('홈 탭: 현재 배터리 정보 설정 - ${currentBatteryInfo.toString()}');
        setState(() {
          _batteryInfo = currentBatteryInfo;
        });
        debugPrint('홈 탭: 초기 배터리 정보 UI 업데이트 완료 - 배터리 레벨: ${currentBatteryInfo.formattedLevel}');
      }
      
      // 배터리 정보 스트림 구독 설정
      _setupBatteryInfoStream();
      
      // 주기적 새로고침 시작
      _startPeriodicRefresh();
      
    } catch (e, stackTrace) {
      debugPrint('홈 탭: 배터리 서비스 초기화 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 초기화 실패 시에도 최소한의 정보라도 표시
      if (mounted) {
        setState(() {
          _batteryInfo = null;
        });
      }
    }
  }
  
  /// 주기적 새로고침 시작
  void _startPeriodicRefresh() {
    debugPrint('홈 탭: 주기적 새로고침 시작 ($_refreshIntervalSeconds초 간격)');
    
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (timer) {
        if (mounted && !_isRefreshing) {
          debugPrint('홈 탭: 주기적 새로고침 실행');
          _batteryService.refreshBatteryInfo();
        }
      },
    );
  }
  
  /// 주기적 새로고침 중지
  void _stopPeriodicRefresh() {
    debugPrint('홈 탭: 주기적 새로고침 중지');
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
  }
  
  /// 앱 생명주기 리스너 설정
  void _setupAppLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      debugPrint('홈 탭: 앱 생명주기 변화 - $message');
      
      switch (message) {
        case 'AppLifecycleState.paused':
        case 'AppLifecycleState.inactive':
          debugPrint('홈 탭: 앱이 백그라운드로 이동, 모니터링 최적화');
          _optimizeForBackground();
          break;
        case 'AppLifecycleState.resumed':
          debugPrint('홈 탭: 앱이 포그라운드로 복귀, 모니터링 재시작');
          _optimizeForForeground();
          break;
      }
      return null;
    });
  }
  
  /// 백그라운드 최적화
  void _optimizeForBackground() {
    // 주기적 새로고침 중지 (배터리 절약)
    _stopPeriodicRefresh();
    debugPrint('홈 탭: 백그라운드 최적화 완료');
  }
  
  /// 포그라운드 최적화 (탭 복귀 시 강화)
  void _optimizeForForeground() {
    // 주기적 새로고침 재시작
    _startPeriodicRefresh();
    
    // 스트림 구독 재생성 (필요시)
    if (_batteryInfoSubscription == null) {
      debugPrint('홈 탭: 포그라운드 복귀 - 스트림 구독 재생성');
      _setupBatteryInfoStream();
    }
    
    // 탭 복귀 시 항상 배터리 정보 새로고침
    debugPrint('홈 탭: 포그라운드 복귀 - 배터리 정보 강제 새로고침');
    _batteryService.refreshBatteryInfo();
    
    // 현재 정보가 있다면 즉시 UI 업데이트
    final currentInfo = _batteryService.currentBatteryInfo;
    if (currentInfo != null && mounted) {
      setState(() {
        _batteryInfo = currentInfo;
      });
      debugPrint('홈 탭: 포그라운드 복귀 시 배터리 정보 복원 - ${currentInfo.formattedLevel}');
    }
    
    debugPrint('홈 탭: 포그라운드 최적화 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BatteryPal'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 배터리 새로고침 버튼 (로딩 상태/중복 클릭 방지)
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    
                    // context를 미리 저장하여 비동기 작업 후에도 안전하게 사용
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    try {
                      debugPrint('홈 탭: 수동 새로고침 시작');
                      
                      // 강제 새로고침 실행
                      await _batteryService.refreshBatteryInfo();
                      
                      // 즉시 현재 정보 반영 (스트림 업데이트 전 폴백)
                      final latest = _batteryService.currentBatteryInfo;
                      if (mounted && latest != null) {
                        setState(() {
                          _batteryInfo = latest;
                        });
                        debugPrint('홈 탭: 수동 새로고침 완료 - ${latest.formattedLevel}');
                      }
                      
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('배터리 정보를 새로고침했습니다 (${latest?.formattedLevel ?? '--.-%'})'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('홈 탭: 수동 새로고침 실패: $e');
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('새로고침 실패: $e'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    }
                  },
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '배터리 정보 새로고침',
          ),
          // Pro 배지
          if (!widget.isProUser)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⚡ Pro',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 배터리 상태 카드
            BatteryStatusCard(batteryInfo: _batteryInfo),
            const SizedBox(height: 24),
            
            // 🔥 충전 중일 때만 표시되는 충전 분석 카드 (Phase 1: 스켈레톤)
            if (_batteryInfo != null && _batteryInfo!.isCharging) ...[
              ChargingAnalysisCard(batteryInfo: _batteryInfo),
              const SizedBox(height: 24),
            ],
            
            // 배터리 부스트 버튼
            BatteryBoostButton(
              onOptimize: () {
                // Phase 5에서 실제 최적화 기능 구현 예정
                SnackBarUtils.showSuccess(context, '배터리 최적화가 완료되었습니다!');
              },
            ),
            const SizedBox(height: 24),
            
            // 사용 제한 표시 (무료 사용자용)
            if (!widget.isProUser) 
              UsageLimitCard(
                dailyUsage: dailyUsage,
                dailyLimit: dailyLimit,
                onUpgrade: widget.onProToggle,
              ),
          ],
        ),
      ),
    );
  }





}
