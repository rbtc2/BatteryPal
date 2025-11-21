import 'package:flutter/material.dart';
import '../../../../models/charging_graph_theme.dart';
import '../../../../utils/charging_graph_theme_colors.dart';
import '../../../../utils/graph_preview_data_generator.dart';
import '../../../home/components/charging_graph_factory.dart';

/// 테마 미리보기 카드
/// 각 테마의 그래프를 미리보기로 표시하는 위젯
class ThemePreviewCard extends StatefulWidget {
  final ChargingGraphTheme theme;
  final double animationValue;

  const ThemePreviewCard({
    super.key,
    required this.theme,
    this.animationValue = 0.0,
  });

  @override
  State<ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<ThemePreviewCard> {
  @override
  Widget build(BuildContext context) {
    // 테마별 색상 스키마 가져오기
    final backgroundColor = ChargingGraphThemeColors.getBackgroundColor(widget.theme);
    final backgroundGradient = ChargingGraphThemeColors.getBackgroundGradient(widget.theme);
    final borderColor = ChargingGraphThemeColors.getBorderColor(widget.theme);

    // 테마별 샘플 데이터 생성
    final sampleData = GraphPreviewDataGenerator.generateThemeSpecificData(
      themeName: widget.theme.name,
      pointCount: 50, // 미리보기용 데이터 포인트 수
      animationValue: widget.animationValue,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        color: backgroundGradient == null ? backgroundColor : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 테마 이름
          Text(
            widget.theme.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 테마 설명
          Text(
            widget.theme.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 그래프 미리보기
          SizedBox(
            height: 200,
            child: ChargingGraphFactory.createGraph(
              theme: widget.theme,
              dataPoints: sampleData,
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}

