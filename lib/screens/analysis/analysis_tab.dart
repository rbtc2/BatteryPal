import 'package:flutter/material.dart';

/// 분석 탭 화면
/// Phase 6에서 실제 구현 예정
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배터리 분석'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Analysis Tab - Phase 6에서 구현 예정',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
