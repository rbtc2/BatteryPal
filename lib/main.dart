import 'package:flutter/material.dart';
import 'services/battery_service.dart';

void main() {
  runApp(const BatteryPalApp());
}

class BatteryPalApp extends StatelessWidget {
  const BatteryPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BatteryPal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // 배터리 테마 그린
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// Phase 1: 기본 네비게이션 구조 및 3탭 바 구현
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // Pro 모드 상태 관리 (Phase 5: 통합)
  bool _isProUser = false;

  // 3개 탭 페이지들 (Pro 상태 전달)
  List<Widget> get _pages => [
    HomeTab(isProUser: _isProUser, onProToggle: _toggleProMode),
    AnalysisTab(isProUser: _isProUser, onProToggle: _toggleProMode),
    SettingsTab(isProUser: _isProUser, onProToggle: _toggleProMode),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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
      // Phase 5: Pro 모드 토글 플로팅 액션 버튼 (개발용)
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleProMode,
        backgroundColor: _isProUser ? Colors.amber : Theme.of(context).colorScheme.primary,
        child: Icon(
          _isProUser ? Icons.star : Icons.star_border,
          color: _isProUser ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  // Phase 5: Pro 모드 토글 기능 (개발용)
  void _toggleProMode() {
    setState(() {
      _isProUser = !_isProUser;
    });
    
    // Pro 모드 변경 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isProUser ? 'Pro 모드 활성화!' : '무료 모드로 전환'),
        backgroundColor: _isProUser ? Colors.amber : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Phase 2: 홈 탭 스켈레톤 UI 구현
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
    return Card(
      elevation: 4,
      child: Padding(
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
                _buildInfoItem('온도', _batteryInfo?.formattedTemperature ?? '--.-°C', 
                    valueColor: _batteryInfo?.temperatureColor),
                _buildInfoItem('전압', _batteryInfo?.formattedVoltage ?? '--mV',
                    valueColor: _batteryInfo?.voltageColor),
                _buildInfoItem('건강도', _batteryInfo?.healthText ?? '알 수 없음',
                    valueColor: _batteryInfo?.healthColor),
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
                  '마지막 업데이트: ${_formatTime(_batteryInfo!.timestamp)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
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
            // Phase 5에서 실제 기능 구현 예정
            _showOptimizationDialog();
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
    return Card(
      elevation: 2,
      child: Padding(
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
                // Phase 5: Pro 업그레이드 다이얼로그
                _showProUpgradeDialog();
              },
              child: const Text('Pro로 업그레이드'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateEffectCard() {
    return Card(
      elevation: 2,
      child: Padding(
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
                _buildEffectItem('절약된 전력', '150mW'),
                _buildEffectItem('연장 시간', '+2시간 15분'),
                _buildEffectItem('최적화된 앱', '5개'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEffectItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 시간 포맷팅 메서드
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}초 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptimizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배터리 최적화'),
        content: const Text('Phase 5에서 실제 최적화 기능이 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 업그레이드'),
        content: const Text('Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onProToggle(); // Pro 모드 토글
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }
}

// Phase 3: 분석 탭 스켈레톤 UI 구현
class AnalysisTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;
  
  const AnalysisTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  // 스켈레톤용 더미 데이터
  List<Map<String, dynamic>> appUsageData = [
    {'name': 'YouTube', 'usage': 25, 'icon': Icons.play_circle},
    {'name': 'Instagram', 'usage': 18, 'icon': Icons.camera_alt},
    {'name': 'Chrome', 'usage': 15, 'icon': Icons.web},
    {'name': 'WhatsApp', 'usage': 12, 'icon': Icons.message},
    {'name': 'Spotify', 'usage': 8, 'icon': Icons.music_note},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배터리 분석'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (!widget.isProUser)
            TextButton(
              onPressed: () => _showProUpgradeDialog(),
              child: const Text('Pro로 업그레이드'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배터리 사용량 차트
            _buildBatteryChartCard(),
            const SizedBox(height: 24),
            
            // 배터리 상세 정보 섹션
            _buildBatteryDetailsCard(),
            const SizedBox(height: 24),
            
            // 배터리 성능 지표 섹션
            _buildBatteryPerformanceCard(),
            const SizedBox(height: 24),
            
            // 앱별 전력 소비
            _buildAppUsageCard(),
            const SizedBox(height: 24),
            
            // Pro 기능 미리보기
            if (!widget.isProUser) _buildProPreviewCard(),
            
            const SizedBox(height: 24),
            
            // 일일 요약
            _buildDailySummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryChartCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '24시간 배터리 사용량',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isProUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '무료: 최근 7일',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 차트 영역 (스켈레톤)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '배터리 사용량 차트',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phase 5에서 실제 차트 구현 예정',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '앱별 전력 소비',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isProUser)
                  TextButton(
                    onPressed: () => _showProUpgradeDialog(),
                    child: const Text('Pro로 전체 보기'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 앱 사용량 리스트 (무료: 상위 5개만)
            ...appUsageData.take(widget.isProUser ? appUsageData.length : 5).map((app) {
              return _buildAppUsageItem(app);
            }),
            
            // Pro 기능 안내
            if (!widget.isProUser)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pro로 모든 앱의 상세 분석을 확인하세요',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageItem(Map<String, dynamic> app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 앱 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              app['icon'],
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          
          // 앱 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${app['usage']}% 배터리 사용',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 사용량 바
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: app['usage'] / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getUsageColor(app['usage']),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProPreviewCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pro 기능 미리보기',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Pro 기능 목록
            _buildProFeatureItem('배터리 건강도 트렌드', Icons.trending_up),
            _buildProFeatureItem('충전 패턴 분석', Icons.battery_charging_full),
            _buildProFeatureItem('AI 인사이트', Icons.psychology),
            _buildProFeatureItem('상세 리포트', Icons.assessment),
            
            const SizedBox(height: 16),
            
            // 업그레이드 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showProUpgradeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Pro로 업그레이드',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProFeatureItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 요약',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('총 사용량', '78%'),
                _buildSummaryItem('절약된 전력', '120mW'),
                _buildSummaryItem('최적화 횟수', '3회'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getUsageColor(int usage) {
    if (usage > 20) return Colors.red;
    if (usage > 10) return Colors.orange;
    return Colors.green;
  }

  Widget _buildBatteryDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.battery_std,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '배터리 상세 정보',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 배터리 기술 정보
            _buildDetailRow('배터리 기술', 'Li-Ion'),
            _buildDetailRow('제조사', 'Samsung SDI'),
            _buildDetailRow('설계 용량', '4,500 mAh'),
            _buildDetailRow('현재 용량', '4,200 mAh (93%)'),
            _buildDetailRow('충전 사이클', '1,247회'),
            _buildDetailRow('마지막 교체', '2023년 3월'),
            
            const SizedBox(height: 16),
            
            // 배터리 상태 지표
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '배터리 상태 지표',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusIndicator('건강도', 85, Colors.green),
                  _buildStatusIndicator('성능', 78, Colors.orange),
                  _buildStatusIndicator('안전성', 92, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryPerformanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '배터리 성능 지표',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 성능 메트릭
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    '평균 사용 시간',
                    '18시간 32분',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    '충전 속도',
                    '45분',
                    Icons.flash_on,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    '방전 속도',
                    '2.3%/시간',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    '효율성',
                    '87%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 최적화 제안
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '최적화 제안',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionItem('화면 밝기를 70%로 낮추면 2시간 더 사용 가능'),
                  _buildSuggestionItem('백그라운드 앱을 정리하면 배터리 수명 15% 향상'),
                  _buildSuggestionItem('Wi-Fi 대신 모바일 데이터 사용 시 전력 소모 증가'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              suggestion,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 업그레이드'),
        content: const Text('Pro 모드로 업그레이드하시겠습니까?\n\n• 모든 앱 분석 보기\n• 배터리 건강도 트렌드\n• AI 인사이트\n• 상세 리포트'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onProToggle(); // Pro 모드 토글
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }
}

// Phase 4: 설정 탭 스켈레톤 UI 구현
class SettingsTab extends StatefulWidget {
  final bool isProUser;
  final VoidCallback onProToggle;
  
  const SettingsTab({
    super.key,
    required this.isProUser,
    required this.onProToggle,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // 스켈레톤용 더미 데이터
  bool notificationsEnabled = true;
  bool darkModeEnabled = true;
  String selectedLanguage = '한국어';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Pro 업그레이드 카드 (무료 사용자용)
            if (!widget.isProUser) _buildProUpgradeCard(),
            
            const SizedBox(height: 24),
            
            // 기본 설정
            _buildSettingsSection('기본 설정', [
              _buildSettingsItem(
                '알림 설정',
                Icons.notifications,
                notificationsEnabled ? '켜짐' : '꺼짐',
                () => _toggleNotifications(),
              ),
              _buildSettingsItem(
                '테마 설정',
                Icons.dark_mode,
                darkModeEnabled ? '다크 모드' : '라이트 모드',
                () => _toggleTheme(),
              ),
              _buildSettingsItem(
                '언어 설정',
                Icons.language,
                selectedLanguage,
                () => _showLanguageDialog(),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Pro 설정 (Pro 사용자용)
            if (widget.isProUser) _buildProSettingsSection(),
            
            const SizedBox(height: 24),
            
            // 앱 정보
            _buildSettingsSection('앱 정보', [
              _buildSettingsItem(
                '버전 정보',
                Icons.info,
                '1.0.0',
                () {},
              ),
              _buildSettingsItem(
                '라이선스',
                Icons.description,
                'MIT License',
                () {},
              ),
              _buildSettingsItem(
                '개발자 정보',
                Icons.person,
                'BatteryPal Team',
                () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Pro 구독 관리 (Pro 사용자용)
            if (widget.isProUser) _buildProSubscriptionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProUpgradeCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pro 업그레이드',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '무제한 배터리 부스트와 고급 분석 기능을 사용하세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showProUpgradeDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Pro로 업그레이드',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildProSettingsSection() {
    return _buildSettingsSection('Pro 설정', [
      _buildSettingsItem(
        '자동 최적화',
        Icons.auto_awesome,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '고급 알림',
        Icons.notifications_active,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '데이터 백업',
        Icons.cloud_sync,
        '켜짐',
        () {},
      ),
      _buildSettingsItem(
        '위젯 설정',
        Icons.widgets,
        '홈 화면 위젯',
        () {},
      ),
    ]);
  }

  Widget _buildProSubscriptionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pro 구독 관리',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '연간 구독 (2024.12.31까지)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '월 4,900원',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: () => _showSubscriptionDialog(),
                  child: const Text('관리'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });
  }

  void _toggleTheme() {
    setState(() {
      darkModeEnabled = !darkModeEnabled;
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: RadioGroup<String>(
          groupValue: selectedLanguage,
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('한국어'),
                leading: Radio<String>(
                  value: '한국어',
                ),
              ),
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'English',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 업그레이드'),
        content: const Text('Pro 모드로 업그레이드하시겠습니까?\n\n• 무제한 배터리 부스트\n• 고급 분석 기능\n• 자동 최적화\n• 우선 지원'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onProToggle(); // Pro 모드 토글
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구독 관리'),
        content: const Text('Phase 5에서 구독 관리 기능이 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
