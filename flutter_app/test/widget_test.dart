import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiogenie/main.dart';

void main() {
  testWidgets('JioGenieApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JioGenieApp());
    expect(find.text('JioGenie'), findsWidgets);
  });

  testWidgets('JioGenieApp renders cleanly in mobile ratio 390x844 without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const JioGenieApp());
    await tester.pumpAndSettle();

    expect(find.text('JioGenie'), findsWidgets);
    expect(find.text('How can JioGenie help you?'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('JioGenieApp renders cleanly in compact mobile 360x640 without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const JioGenieApp());
    await tester.pumpAndSettle();

    expect(find.text('JioGenie'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
