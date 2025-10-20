// BatteryPal 앱의 기본 위젯 테스트
//
// 이 테스트는 앱이 올바르게 빌드되고 주요 UI 요소들이 표시되는지 확인합니다.
// flutter_test 패키지의 WidgetTester 유틸리티를 사용하여 위젯과 상호작용할 수 있습니다.

import 'package:flutter_test/flutter_test.dart';

import 'package:batterypal/app/battery_pal_app.dart';

void main() {
  testWidgets('BatteryPal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BatteryPalApp());

    // Phase 1: 기본 구조만 테스트 (Phase 5-8에서 상세 테스트 추가 예정)
    // Verify that bottom navigation is present.
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('분석'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    
    // Verify that temporary content is displayed
    expect(find.text('Home Tab - Phase 5에서 구현'), findsOneWidget);
  });
}
