import 'package:flutter/material.dart';
import '../../services/battery_service.dart';
import '../../models/app_models.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/dialog_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeBatteryService();
  }

  @override
  void dispose() {
    _batteryService.stopMonitoring();
    super.dispose();
  }

  /// 배터리 서비스 초기화
  Future<void> _initializeBatteryService() async {
    // 배터리 정보 스트림 구독
    _batteryService.batteryInfoStream.listen((batteryInfo) {
      if (mounted) {
        setState(() {
          _batteryInfo = batteryInfo;
        });
      }
    });
    
    // 배터리 모니터링 시작
    await _batteryService.startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BatteryPal'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 배터리 새로고침 버튼
          IconButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _batteryService.refreshBatteryInfo();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('배터리 정보를 새로고침했습니다'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
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
            _buildBatteryStatusCard(),
            const SizedBox(height: 24),
            
            // 배터리 부스트 버튼
            _buildBatteryBoostButton(),
            const SizedBox(height: 24),
            
            // 사용 제한 표시 (무료 사용자용)
            if (!widget.isProUser) _buildUsageLimitCard(),
            
            const SizedBox(height: 24),
            
            // 즉시 효과 표시
            _buildImmediateEffectCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStatusCard() {
    return CustomCard(
      elevation: 4,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 배터리 레벨 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 배터리',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _batteryInfo?.formattedLevel ?? '--.-%',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _batteryInfo?.levelColor ?? Colors.grey,
                    ),
                  ),
                ],
              ),
              // 배터리 아이콘
              Icon(
                _batteryInfo?.levelIcon ?? Icons.battery_unknown,
                size: 48,
                color: _batteryInfo?.levelColor ?? Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 배터리 정보 (3개 항목)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoItem(
                label: '온도',
                value: _batteryInfo?.formattedTemperature ?? '--.-°C',
                valueColor: _batteryInfo?.temperatureColor,
              ),
              InfoItem(
                label: '전압',
                value: _batteryInfo?.formattedVoltage ?? '--mV',
                valueColor: _batteryInfo?.voltageColor,
              ),
              InfoItem(
                label: '건강도',
                value: _batteryInfo?.healthText ?? '알 수 없음',
                valueColor: _batteryInfo?.healthColor,
              ),
            ],
          ),
          
          // 충전 정보 섹션
          if (_batteryInfo != null && _batteryInfo!.isCharging) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _batteryInfo!.chargingStatusText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 마지막 업데이트 시간
          if (_batteryInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '마지막 업데이트: ${TimeUtils.formatRelativeTime(_batteryInfo!.timestamp)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryBoostButton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Phase 4의 다이얼로그 시스템 사용
            DialogUtils.showOptimizationDialog(
              context,
              onConfirm: () {
                // Phase 5에서 실제 최적화 기능 구현 예정
                SnackBarUtils.showSuccess(context, '배터리 최적화가 완료되었습니다!');
              },
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.flash_on,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚡ 배터리 부스트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '원클릭으로 즉시 최적화',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageLimitCard() {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '무료 버전 사용 제한',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '오늘 $dailyUsage/$dailyLimit회 사용',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Phase 4의 다이얼로그 시스템 사용
              DialogUtils.showProUpgradeSuccessDialog(
                context,
                onUpgrade: widget.onProToggle,
              );
            },
            child: const Text('Pro로 업그레이드'),
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateEffectCard() {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최적화 효과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              EffectItem(
                label: '절약된 전력',
                value: '150mW',
              ),
              EffectItem(
                label: '연장 시간',
                value: '+2시간 15분',
              ),
              EffectItem(
                label: '최적화된 앱',
                value: '5개',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
