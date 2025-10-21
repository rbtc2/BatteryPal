import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/general_settings_tab.dart';
import '../../widgets/settings/battery_settings_tab.dart';

/// 설정 탭 화면
/// 일반 설정과 배터리 설정을 탭으로 분리
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
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
  }

  @override
  void dispose() {
    _settingsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.settings),
                text: '일반',
              ),
              Tab(
                icon: Icon(Icons.battery_std),
                text: '배터리',
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            GeneralSettingsTab(
              settingsService: _settingsService,
              isProUser: widget.isProUser,
              onProToggle: widget.onProToggle,
            ),
            BatterySettingsTab(
              settingsService: _settingsService,
              isProUser: widget.isProUser,
              onProToggle: widget.onProToggle,
            ),
          ],
        ),
      ),
    );
  }
}
