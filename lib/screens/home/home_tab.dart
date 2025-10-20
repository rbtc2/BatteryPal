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
    debugPrint('홈 탭: 배터리 서비스 초기화 시작');
    
    // 배터리 정보 스트림 구독
    _batteryService.batteryInfoStream.listen((batteryInfo) {
      debugPrint('홈 탭: 배터리 정보 수신 - ${batteryInfo.toString()}');
      if (mounted) {
        setState(() {
          _batteryInfo = batteryInfo;
        });
        debugPrint('홈 탭: UI 업데이트 완료 - 배터리 레벨: ${batteryInfo.formattedLevel}');
      } else {
        debugPrint('홈 탭: 위젯이 마운트되지 않음, UI 업데이트 건너뜀');
      }
    });
    
    // 배터리 모니터링 시작
    await _batteryService.startMonitoring();
    debugPrint('홈 탭: 배터리 모니터링 시작 완료');
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
            
            // 🔥 충전 중일 때만 표시되는 충전 분석 카드 (Phase 1: 스켈레톤)
            if (_batteryInfo != null && _batteryInfo!.isCharging) ...[
              _buildChargingAnalysisCard(),
              const SizedBox(height: 24),
            ],
            
            // 배터리 부스트 버튼
            _buildBatteryBoostButton(),
            const SizedBox(height: 24),
            
            // 사용 제한 표시 (무료 사용자용)
            if (!widget.isProUser) _buildUsageLimitCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStatusCard() {
    debugPrint('홈 탭: 배터리 상태 카드 빌드 - _batteryInfo: ${_batteryInfo?.toString()}');
    
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

  /// 충전 분석 카드 (Phase 1: 스켈레톤 UI)
  Widget _buildChargingAnalysisCard() {
    return CustomCard(
      elevation: 6, // 다른 카드보다 높은 elevation으로 강조
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 충전 속도 분석
          _buildChargingHeader(),
          const SizedBox(height: 16),
          
          // 충전 속도 인디케이터 (큰 시각적 요소)
          _buildChargingSpeedIndicator(),
          const SizedBox(height: 16),
          
          // 충전 최적화 팁 (접을 수 있는 형태)
          _buildChargingOptimizationTips(),
        ],
      ),
    );
  }

  /// 충전 분석 헤더
  Widget _buildChargingHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.flash_on,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '충전 속도 분석',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // 실시간 업데이트 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '실시간',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 충전 속도 인디케이터 (Phase 1: 스켈레톤)
  Widget _buildChargingSpeedIndicator() {
    // Phase 1에서는 더미 데이터 사용
    final chargingSpeed = _getDummyChargingSpeed();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chargingSpeed.color.withValues(alpha: 0.1),
            chargingSpeed.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chargingSpeed.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 큰 아이콘
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: chargingSpeed.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              chargingSpeed.icon,
              color: chargingSpeed.color,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          
          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chargingSpeed.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: chargingSpeed.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chargingSpeed.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                // 충전 진행률 바 (Phase 1: 스켈레톤)
                _buildChargingProgressBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 충전 진행률 바 (Phase 1: 스켈레톤)
  Widget _buildChargingProgressBar() {
    final currentLevel = _batteryInfo?.level ?? 0.0;
    final progress = currentLevel / 100.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '충전 진행률',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${currentLevel.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 충전 최적화 팁 (Phase 1: 스켈레톤)
  Widget _buildChargingOptimizationTips() {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '충전 최적화 팁',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        ..._getDummyChargingTips().map((tip) => _buildTipItem(tip)),
      ],
    );
  }

  /// 팁 아이템 위젯
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 더미 충전 속도 정보 (Phase 1용)
  ChargingSpeedInfo _getDummyChargingSpeed() {
    // Phase 1에서는 더미 데이터 사용
    // Phase 2에서 실제 충전 전류 분석으로 교체 예정
    return ChargingSpeedInfo(
      label: '고속 충전',
      description: '1.5A 충전 중',
      color: Colors.orange,
      icon: Icons.electric_bolt,
      tips: [
        '80% 이상 충전 시 충전 속도가 감소합니다',
        '충전 완료 후 30분 이내에 분리 권장',
        '충전 중 고성능 작업은 피하세요',
      ],
    );
  }

  /// 더미 충전 팁 (Phase 1용)
  List<String> _getDummyChargingTips() {
    return [
      '80% 이상 충전 시 충전 속도가 감소합니다',
      '충전 완료 후 30분 이내에 분리 권장',
      '충전 중 고성능 작업은 피하세요',
      '배터리 온도가 높으면 충전 속도가 느려집니다',
    ];
  }
}
