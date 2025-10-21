import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/home_lifecycle_manager.dart';
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
  // 생명주기 관리 서비스
  final HomeLifecycleManager _lifecycleManager = HomeLifecycleManager();
  
  // 스켈레톤용 더미 데이터
  int remainingHours = 4;
  int remainingMinutes = 30;
  int batteryTemp = 32;
  int dailyUsage = 2;
  int dailyLimit = 3;
  
  // 실제 배터리 정보
  BatteryInfo? _batteryInfo;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeLifecycleManager();
  }

  /// 생명주기 관리자 초기화
  Future<void> _initializeLifecycleManager() async {
    debugPrint('홈 탭: 생명주기 관리자 초기화 시작');
    
    // 콜백 함수 설정
    _lifecycleManager.onBatteryInfoUpdated = (batteryInfo) {
      if (mounted) {
        setState(() {
          _batteryInfo = batteryInfo;
        });
        debugPrint('홈 탭: 배터리 정보 업데이트 - ${batteryInfo.formattedLevel}');
      }
    };
    
    _lifecycleManager.onChargingCurrentChanged = () {
      debugPrint('홈 탭: 충전 전류 변화 감지');
      // 필요시 추가 처리
    };
    
    _lifecycleManager.onAppPaused = () {
      debugPrint('홈 탭: 앱이 백그라운드로 이동');
    };
    
    _lifecycleManager.onAppResumed = () {
      debugPrint('홈 탭: 앱이 포그라운드로 복귀');
    };
    
    // 생명주기 관리자 초기화
    await _lifecycleManager.initialize();
    
    // 초기 배터리 정보 설정
    final currentInfo = _lifecycleManager.currentBatteryInfo;
    if (currentInfo != null && mounted) {
      setState(() {
        _batteryInfo = currentInfo;
      });
      debugPrint('홈 탭: 초기 배터리 정보 설정 - ${currentInfo.formattedLevel}');
    }
    
    debugPrint('홈 탭: 생명주기 관리자 초기화 완료');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 탭 복귀 시 배터리 정보 즉시 새로고침
    debugPrint('홈 탭: didChangeDependencies - 탭 복귀 감지');
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _lifecycleManager.handleTabReturn();
      
      // 현재 배터리 정보가 있다면 즉시 UI 업데이트
      final currentInfo = _lifecycleManager.currentBatteryInfo;
      if (currentInfo != null && mounted) {
        setState(() {
          _batteryInfo = currentInfo;
        });
        debugPrint('홈 탭: 탭 복귀 시 기존 배터리 정보 복원 - ${currentInfo.formattedLevel}');
      }
    });
  }

  @override
  void dispose() {
    debugPrint('홈 탭: dispose 시작');
    
    // 생명주기 관리자 정리
    _lifecycleManager.dispose();
    
    debugPrint('홈 탭: dispose 완료');
    super.dispose();
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
                      
                      // 생명주기 관리자를 통한 새로고침
                      await _lifecycleManager.refreshBatteryInfo();
                      
                      // 즉시 현재 정보 반영
                      final latest = _lifecycleManager.currentBatteryInfo;
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
