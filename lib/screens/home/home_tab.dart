import 'package:flutter/material.dart';

/// 홈 탭 화면
/// Phase 5에서 실제 구현 예정
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BatteryPal'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Home Tab - Phase 5에서 구현 예정',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
