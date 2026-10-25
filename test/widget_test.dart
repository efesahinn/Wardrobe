import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/app.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/home_screen.dart';

void main() {
  testWidgets('App opens the wardrobe placeholder through its home route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WardrobeApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Wardrobe+'), findsOneWidget);
    expect(find.text('Your wardrobe starts here'), findsOneWidget);
    expect(
      find.text(
        'Wardrobe browsing, outfit recommendations, and Smart Quick Swap '
        'are coming soon.',
      ),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home supports a small screen and large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const WardrobeApp());
    await tester.pumpAndSettle();

    expect(find.text('Your wardrobe starts here'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
