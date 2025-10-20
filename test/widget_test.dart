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

    // Phase 5: HomeTab 실제 구현 완료로 테스트 업데이트
    // Verify that bottom navigation is present.
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('분석'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    
    // Verify that HomeTab content is displayed (Phase 5 완료)
    expect(find.text('BatteryPal'), findsOneWidget); // AppBar title
    expect(find.text('현재 배터리'), findsOneWidget); // Battery status card
    expect(find.text('⚡ 배터리 부스트'), findsOneWidget); // Battery boost button
    
    // Verify that navigation works
    await tester.tap(find.text('분석'));
    await tester.pump();
    // Analysis tab should be accessible
    
    await tester.tap(find.text('설정'));
    await tester.pump();
    // Settings tab should be accessible
    
    // Return to home tab
    await tester.tap(find.text('홈'));
    await tester.pump();
    expect(find.text('BatteryPal'), findsOneWidget); // Back to home
  });
}
