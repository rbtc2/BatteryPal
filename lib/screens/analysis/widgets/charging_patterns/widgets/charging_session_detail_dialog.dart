// 충전 세션 상세 정보 다이얼로그
// 세션의 모든 상세 정보를 표시하는 다이얼로그

import 'package:flutter/material.dart';
import '../models/charging_session_models.dart';
import '../utils/time_slot_utils.dart';

/// 충전 세션 상세 정보 다이얼로그
/// 
/// 세션의 모든 상세 정보를 표시하는 다이얼로그
/// - 기본 정보 (시간, 배터리 변화, 효율 등)
/// - 통계 정보 (평균/최대/최소 전류, 온도)
/// - 전류 변화 이력
/// - 시간대 정보
class ChargingSessionDetailDialog extends StatelessWidget {
  final ChargingSessionRecord session;

  const ChargingSessionDetailDialog({
    super.key,
    required this.session,
  });

  /// 다이얼로그 표시
  static void show(BuildContext context, ChargingSessionRecord session) {
    showDialog(
      context: context,
      builder: (context) => ChargingSessionDetailDialog(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = TimeSlotUtils.getTimeSlotColor(session.timeSlot);
    final efficiencyColor = TimeSlotUtils.getEfficiencyColor(session.efficiency);
    
    // 시간 포맷팅
    final startTimeStr = _formatDateTime(session.startTime);
    final endTimeStr = _formatDateTime(session.endTime);
    final duration = _formatDuration(session.duration);
    
    // 배터리 변화량
    final batteryChange = '${session.startBatteryLevel.toStringAsFixed(1)}% → ${session.endBatteryLevel.toStringAsFixed(1)}%';
    final batteryChangeValue = session.batteryChange.toStringAsFixed(1);
    
    // 효율 포맷팅
    final efficiency = '${session.efficiency.toStringAsFixed(1)}%';
    final efficiencyGrade = _getEfficiencyGrade(session.efficiency);
    
    // 전류 정보
    final avgCurrent = '${session.avgCurrent.toStringAsFixed(0)}mA';
    final maxCurrent = '${session.maxCurrent.toStringAsFixed(0)}mA';
    final minCurrent = '${session.minCurrent.toStringAsFixed(0)}mA';
    final currentSpeedType = _getCurrentSpeedType(session.avgCurrent);
    
    // 온도 정보
    final temperature = '${session.avgTemperature.toStringAsFixed(1)}°C';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TimeSlotUtils.getTimeSlotDescription(session.timeSlot),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // 내용 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보 섹션
                    _buildSectionTitle(context, '기본 정보'),
                    const SizedBox(height: 10),
                    _buildInfoGrid(context, [
                      _InfoItem('시작 시간', startTimeStr, Icons.access_time, Colors.blue),
                      _InfoItem('종료 시간', endTimeStr, Icons.access_time_filled, Colors.blue),
                      _InfoItem('충전 시간', duration, Icons.timer, Colors.purple),
                      _InfoItem('배터리 변화', batteryChange, Icons.battery_charging_full, Colors.green),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 통계 정보 섹션
                    _buildSectionTitle(context, '통계 정보'),
                    const SizedBox(height: 12),
                    _buildInfoGrid(context, [
                      _InfoItem('평균 전류', avgCurrent, Icons.speed, color),
                      _InfoItem('최대 전류', maxCurrent, Icons.trending_up, Colors.red),
                      _InfoItem('최소 전류', minCurrent, Icons.trending_down, Colors.blue),
                      _InfoItem('충전 속도', currentSpeedType, Icons.flash_on, color),
                    ]),
                    
                    const SizedBox(height: 12),
                    _buildInfoGrid(context, [
                      _InfoItem('평균 온도', temperature, Icons.thermostat, Colors.orange),
                      _InfoItem('효율', efficiency, Icons.star, efficiencyColor),
                      _InfoItem('효율 등급', efficiencyGrade, Icons.grade, efficiencyColor),
                      _InfoItem('배터리 변화량', '$batteryChangeValue%', Icons.battery_std, Colors.green),
                    ]),
                    
                    // 전류 변화 이력 섹션
                    if (session.speedChanges.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(context, '전류 변화 이력'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: session.speedChanges.asMap().entries.map((entry) {
                            final index = entry.key;
                            final change = entry.value;
                            final isLast = index == session.speedChanges.length - 1;
                            
                            return _buildTimelineItem(
                              context,
                              change: change,
                              color: color,
                              isLast: isLast,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // 추가 정보 섹션
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, '추가 정보'),
                    const SizedBox(height: 12),
                    _buildAdditionalInfo(context, session),
                  ],
                ),
              ),
            ),
            
            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, List<_InfoItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildInfoCard(context, item);
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, _InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: item.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required CurrentChangeEvent change,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타임라인 라인
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(change.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  change.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (change.previousCurrent != change.newCurrent) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${change.previousCurrent}mA → ${change.newCurrent}mA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, ChargingSessionRecord session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdditionalInfoRow(context, '세션 ID', '${session.id.substring(0, 8)}...'),
          const SizedBox(height: 8),
          _buildAdditionalInfoRow(context, '시간대', TimeSlotUtils.getTimeSlotName(session.timeSlot)),
          const SizedBox(height: 8),
          _buildAdditionalInfoRow(context, '시간대 범위', TimeSlotUtils.getTimeSlotRange(session.timeSlot)),
          const SizedBox(height: 8),
          _buildAdditionalInfoRow(
            context,
            '유효성',
            session.isValid ? '유효한 세션' : '유효하지 않은 세션',
          ),
          if (session.batteryCapacity != null) ...[
            const SizedBox(height: 8),
            _buildAdditionalInfoRow(context, '배터리 용량', '${session.batteryCapacity}mAh'),
          ],
          if (session.batteryVoltage != null) ...[
            const SizedBox(height: 8),
            _buildAdditionalInfoRow(context, '배터리 전압', '${session.batteryVoltage}mV'),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours시간 $minutes분 $seconds초';
    } else if (minutes > 0) {
      return '$minutes분 $seconds초';
    } else {
      return '$seconds초';
    }
  }

  String _getEfficiencyGrade(double efficiency) {
    if (efficiency >= 90.0) return '우수';
    if (efficiency >= 80.0) return '양호';
    if (efficiency >= 70.0) return '보통';
    return '낮음';
  }

  String _getCurrentSpeedType(double current) {
    if (current >= 3000) return '⚡ 초고속';
    if (current >= 1500) return '⚡ 급속';
    if (current >= 500) return '🟧 일반';
    return '🔵 저속';
  }
}

/// 정보 아이템 헬퍼 클래스
class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _InfoItem(this.label, this.value, this.icon, this.color);
}

