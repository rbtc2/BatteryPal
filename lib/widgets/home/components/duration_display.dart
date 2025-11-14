import 'package:flutter/material.dart';
import '../utils/charging_format_utils.dart';

/// 지속 시간 표시 위젯
/// 충전 세션의 경과 시간을 표시하는 위젯
class DurationDisplay extends StatelessWidget {
  final Duration? elapsedDuration;

  const DurationDisplay({
    super.key,
    required this.elapsedDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (elapsedDuration == null) {
      // 세션 시작 시간이 없으면 표시하지 않음
      return const SizedBox.shrink();
    }

    final durationText = ChargingFormatUtils.formatDuration(elapsedDuration!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          Icons.access_time,
          color: Colors.green.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            durationText,
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

