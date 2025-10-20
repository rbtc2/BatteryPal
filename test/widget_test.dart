// BatteryPal 앱의 기본 위젯 테스트
//
// 이 테스트는 앱이 올바르게 빌드되고 주요 UI 요소들이 표시되는지 확인합니다.
// flutter_test 패키지의 WidgetTester 유틸리티를 사용하여 위젯과 상호작용할 수 있습니다.

import 'package:flutter_test/flutter_test.dart';

import 'package:batterypal/main.dart';

void main() {
  testWidgets('BatteryPal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BatteryPalApp());

    // Verify that the app title is displayed.
    expect(find.text('BatteryPal'), findsOneWidget);

    // Verify that the home tab is displayed by default.
    expect(find.text('현재 배터리'), findsOneWidget);
    expect(find.text('⚡ 배터리 부스트'), findsOneWidget);

    // Verify that bottom navigation is present.
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('분석'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
