import 'package:flutter/material.dart';

/// 설정 탭 화면
/// Phase 7에서 실제 구현 예정
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Settings Tab - Phase 7에서 구현 예정',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
