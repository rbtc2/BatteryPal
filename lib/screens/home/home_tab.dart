import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/home_lifecycle_manager.dart';
import '../../services/settings_service.dart';
import '../../models/app_models.dart';
import '../../widgets/home/battery_status_card.dart';
import '../../widgets/home/realtime_charging_monitor.dart';

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
  // 싱글톤 생명주기 관리 서비스 사용
  final HomeLifecycleManager _lifecycleManager = HomeLifecycleManager();
  
  // 설정 서비스
  late final SettingsService _settingsService;
  
  // 탭 고유 ID (콜백 관리용)
  static const String _tabId = 'home_tab';
  
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
    _settingsService = SettingsService();
    // 설정 초기화 및 로드
    _settingsService.initialize().then((_) {
      // SettingsService를 BatteryService에 연결
      _lifecycleManager.setSettingsService(_settingsService);
    });
    _initializeLifecycleManager();
  }

  /// 생명주기 관리자 초기화 (싱글톤 + 탭별 콜백)
  Future<void> _initializeLifecycleManager() async {
    debugPrint('홈 탭: 생명주기 관리자 초기화 시작');
    
    // 탭별 콜백 등록
    _lifecycleManager.registerTabCallbacks(
      _tabId,
      onBatteryInfoUpdated: (batteryInfo) {
        if (mounted) {
          setState(() {
            _batteryInfo = batteryInfo;
          });
          debugPrint('홈 탭: 배터리 정보 업데이트 - ${batteryInfo.formattedLevel}');
        }
      },
      onChargingCurrentChanged: () {
        debugPrint('홈 탭: 충전 전류 변화 감지');
        // 필요시 추가 처리
      },
      onAppPaused: () {
        debugPrint('홈 탭: 앱이 백그라운드로 이동');
      },
      onAppResumed: () {
        debugPrint('홈 탭: 앱이 포그라운드로 복귀');
      },
    );
    
    // 싱글톤이므로 이미 초기화되었을 수 있음 - 확인 후 필요시만 초기화
    if (_lifecycleManager.currentBatteryInfo == null) {
      await _lifecycleManager.initialize();
    }
    
    // 즉시 캐시된 정보 또는 현재 정보 설정
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
    
    // 탭 복귀 시 즉시 복원 + 비동기 업데이트
    debugPrint('홈 탭: didChangeDependencies - 탭 복귀 감지');
    
    // 1. 즉시 캐시된 정보 복원 (UI 즉시 업데이트)
    final cachedInfo = _lifecycleManager.getCachedBatteryInfo();
    if (cachedInfo != null && mounted) {
        setState(() {
        _batteryInfo = cachedInfo;
      });
      debugPrint('홈 탭: 캐시된 정보로 즉시 복원 - ${cachedInfo.formattedLevel}');
    }
    
    // 2. 비동기로 최신 정보 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _lifecycleManager.handleTabReturn();
    });
  }

  @override
  void dispose() {
    debugPrint('홈 탭: dispose 시작');
    
    // 탭별 콜백만 해제 (싱글톤은 유지)
    _lifecycleManager.unregisterTabCallbacks(_tabId);
    
    // 설정 서비스 해제
    _settingsService.dispose();
    
    debugPrint('홈 탭: dispose 완료 (싱글톤 유지)');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 섹션 1: 배터리 상태 (상단 고정)
            BatteryStatusCard(
              batteryInfo: _batteryInfo,
              settingsService: _settingsService,
            ),
            
            const SizedBox(height: 16),
            
            // 섹션 2: 실시간 충전 모니터 (하단 확장)
            Expanded(
              child: SingleChildScrollView(
                child: RealtimeChargingMonitor(
                  batteryInfo: _batteryInfo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
