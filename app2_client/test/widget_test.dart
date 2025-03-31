import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app2_client/widgets/custom_back_button.dart';

void main() {
  testWidgets('CustomBackButton displays correctly', (WidgetTester tester) async {
    // 테스트를 위해 MaterialApp과 Scaffold로 감싸서 위젯을 렌더링합니다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomBackButton(),
        ),
      ),
    );

    // CustomBackButton 위젯이 화면에 존재하는지 확인합니다.
    expect(find.byType(CustomBackButton), findsOneWidget);

    // 추가: 아이콘이 있는지 검사할 수 있습니다.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}