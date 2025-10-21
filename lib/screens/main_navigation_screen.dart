import 'package:flutter/material.dart';
import 'home/home_tab.dart';
import 'analysis/analysis_tab.dart';
import 'settings/settings_tab.dart';

/// 메인 네비게이션 화면
/// Phase 8에서 실제 구현
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // Pro 모드 상태 관리 (실제 결제 시스템과 연동 예정)
  // ignore: prefer_final_fields
  bool _isProUser = false;

  // 3개 탭 페이지들 (Pro 상태 전달)
  List<Widget> get _pages => [
    HomeTab(isProUser: _isProUser, onProToggle: _handleProUpgrade),
    AnalysisTab(isProUser: _isProUser, onProToggle: _handleProUpgrade),
    SettingsTab(isProUser: _isProUser, onProToggle: _handleProUpgrade),
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
