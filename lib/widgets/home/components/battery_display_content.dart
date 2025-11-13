import 'package:flutter/material.dart';
import '../models/battery_display_models.dart';

/// 배터리 표시 내용 위젯
/// 게이지 중앙에 표시되는 동적 정보
class BatteryDisplayContent extends StatelessWidget {
  final DisplayInfo displayInfo;
  final AnimationController cycleController;

  const BatteryDisplayContent({
    super.key,
    required this.displayInfo,
    required this.cycleController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cycleController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    displayInfo.value,
                    key: ValueKey(displayInfo.title),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: displayInfo.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    displayInfo.title,
                    key: ValueKey(displayInfo.title),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (displayInfo.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      displayInfo.subtitle,
                      key: ValueKey(displayInfo.subtitle),
                      style: TextStyle(
                        fontSize: 10,
                        color: displayInfo.color.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        );
      },
    );
  }
}

