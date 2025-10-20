import 'package:flutter/material.dart';

/// 메인 네비게이션 화면
/// 하단 탭 바와 Pro 모드 상태 관리를 담당
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
    // Phase 5에서 HomeTab import 예정
    const Center(child: Text('Home Tab - Phase 5에서 구현')),
    // Phase 6에서 AnalysisTab import 예정  
    const Center(child: Text('Analysis Tab - Phase 6에서 구현')),
    // Phase 7에서 SettingsTab import 예정
    const Center(child: Text('Settings Tab - Phase 7에서 구현')),
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
