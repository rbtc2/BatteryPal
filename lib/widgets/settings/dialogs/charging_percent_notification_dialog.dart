import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import 'add_custom_percent_dialog.dart';

/// 충전 퍼센트 알림 설정 다이얼로그
/// 2025년 최신 스타일 적용
class ChargingPercentNotificationDialog extends StatelessWidget {
  final SettingsService settingsService;

  const ChargingPercentNotificationDialog({
    super.key,
    required this.settingsService,
  });

  static void show(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => ChargingPercentNotificationDialog(
        settingsService: settingsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 (그라데이션 배경)
              _buildHeader(context),
              
              // 스크롤 가능한 콘텐츠
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(context, setState),
                ),
              ),
              
              // 하단 액션 버튼
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 헤더 (그라데이션 배경 + 큰 아이콘)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.battery_std,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 퍼센트 알림',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '설정한 퍼센트 도달 시 알림 받기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 콘텐츠
  Widget _buildContent(BuildContext context, StateSetter setState) {
    final isEnabled = settingsService.appSettings.chargingPercentNotificationEnabled;
    final selectedThresholds = settingsService.appSettings.chargingPercentThresholds;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 토글 (큰 카드 형태)
        _buildMainToggleCard(context, setState, isEnabled),
        
        if (isEnabled) ...[
          const SizedBox(height: 24),
          
          // 선택된 퍼센트 요약 (상단에 표시)
          if (selectedThresholds.isNotEmpty)
            _buildSelectedPercentSummary(context, setState, selectedThresholds),
          
          if (selectedThresholds.isNotEmpty) const SizedBox(height: 24),
          
          // 퍼센트 선택 그리드
          _buildPercentGrid(context, setState),
          
          const SizedBox(height: 24),
          
          // 충전 타입 필터
          _buildChargingTypeFilter(context, setState),
        ],
      ],
    );
  }

  /// 메인 토글 카드
  Widget _buildMainToggleCard(
    BuildContext context,
    StateSetter setState,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active,
              size: 28,
              color: isEnabled
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '충전 퍼센트 알림 활성화',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '설정한 퍼센트 도달 시 알림 받기',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              settingsService.updateChargingPercentNotification(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// 선택된 퍼센트 요약
  Widget _buildSelectedPercentSummary(
    BuildContext context,
    StateSetter setState,
    List<double> selectedThresholds,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '선택된 퍼센트 (${selectedThresholds.length}개)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedThresholds.map((percent) {
              return Chip(
                label: Text('${percent.toInt()}%'),
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onDeleted: () {
                  settingsService.removeChargingPercentThreshold(percent);
                  setState(() {});
                },
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 퍼센트 선택 그리드
  Widget _buildPercentGrid(BuildContext context, StateSetter setState) {
    final defaultPercents = [70.0, 80.0, 90.0, 100.0];
    final selectedThresholds = settingsService.appSettings.chargingPercentThresholds;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_charging_full,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                '알림 받을 퍼센트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: defaultPercents.map((percent) {
              final isSelected = selectedThresholds.contains(percent);
              return _buildPercentCard(context, setState, percent, isSelected);
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 커스텀 퍼센트 추가 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AddCustomPercentDialog.show(
                context,
                settingsService,
                () => setState(() {}),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('커스텀 퍼센트 추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 퍼센트 카드
  Widget _buildPercentCard(
    BuildContext context,
    StateSetter setState,
    double percent,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSelected) {
            settingsService.removeChargingPercentThreshold(percent);
          } else {
            settingsService.addChargingPercentThreshold(percent);
          }
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.battery_std,
                size: 28,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                '${percent.toInt()}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 충전 타입 필터
  Widget _buildChargingTypeFilter(
    BuildContext context,
    StateSetter setState,
  ) {
    final isFastSelected = settingsService.appSettings.chargingPercentNotifyOnFastCharging;
    final isNormalSelected = settingsService.appSettings.chargingPercentNotifyOnNormalCharging;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                '충전 타입 필터 (선택사항)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '특정 충전 타입에서만 알림 받기',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilterChip(
                avatar: Icon(
                  Icons.bolt,
                  size: 18,
                  color: isFastSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: const Text('고속 충전'),
                selected: isFastSelected,
                onSelected: (selected) {
                  settingsService.updateChargingPercentNotifyOnFastCharging(selected);
                  setState(() {});
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isFastSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              FilterChip(
                avatar: Icon(
                  Icons.usb,
                  size: 18,
                  color: isNormalSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                label: const Text('일반 충전'),
                selected: isNormalSelected,
                onSelected: (selected) {
                  settingsService.updateChargingPercentNotifyOnNormalCharging(selected);
                  setState(() {});
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isNormalSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 하단 액션 버튼
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '완료',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
