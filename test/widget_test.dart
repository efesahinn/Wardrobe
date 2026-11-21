import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/app.dart';
import 'package:wardrobe_plus/features/home/presentation/screens/home_screen.dart';
import 'package:wardrobe_plus/features/outfit_recommendations/presentation/screens/outfits_screen.dart';

Finder tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> selectTab(WidgetTester tester, String label) async {
  await tester.tap(tab(label));
  await tester.pumpAndSettle();
}

Future<void> openAction(WidgetTester tester, String label) async {
  final action = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void configureViewport(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('Starts on Home and switches between four labeled tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const WardrobeApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Your wardrobe starts here'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Wardrobe+',
    );
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).useMaterial3,
      isTrue,
    );

    final destinations = {
      'Wardrobe': 'Your digital wardrobe',
      'Outfits': 'Outfit inspiration',
      'Profile': 'Your profile',
      'Home': 'Your wardrobe starts here',
    };
    for (final destination in destinations.entries) {
      await selectTab(tester, destination.key);
      expect(find.text(destination.value), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(destination.key),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Switching tabs retains mounted state and scroll position', (
    tester,
  ) async {
    configureViewport(tester, const Size(320, 480), 2);
    await tester.pumpWidget(const WardrobeApp());
    await tester.pumpAndSettle();
    await selectTab(tester, 'Outfits');

    final scrollable = find.descendant(
      of: find.byType(OutfitsScreen),
      matching: find.byType(Scrollable),
    );
    final state = tester.state<ScrollableState>(scrollable);
    await tester.drag(scrollable, const Offset(0, -180));
    await tester.pumpAndSettle();
    final offset = state.position.pixels;
    expect(offset, greaterThan(0));

    await selectTab(tester, 'Wardrobe');
    expect(find.text('Outfit inspiration'), findsNothing);
    await selectTab(tester, 'Outfits');

    expect(tester.state<ScrollableState>(scrollable), same(state));
    expect(state.position.pixels, closeTo(offset, 0.1));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Secondary placeholders return to their originating tab', (
    tester,
  ) async {
    await tester.pumpWidget(const WardrobeApp());
    await tester.pumpAndSettle();

    await selectTab(tester, 'Outfits');
    await openAction(tester, 'Favorites');
    expect(find.text('Your favorite outfits'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Outfit inspiration'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await selectTab(tester, 'Profile');
    await openAction(tester, 'Wear History');
    expect(find.text('What you wore'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [
    (size: const Size(320, 480), scale: 2.0),
    (size: const Size(320, 480), scale: 3.0),
    (size: const Size(568, 320), scale: 2.0),
    (size: const Size(1024, 768), scale: 2.0),
  ]) {
    testWidgets('All routes fit ${viewport.size} at ${viewport.scale}x text', (
      tester,
    ) async {
      configureViewport(tester, viewport.size, viewport.scale);
      await tester.pumpWidget(const WardrobeApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in ['Wardrobe', 'Outfits', 'Profile', 'Home']) {
        await selectTab(tester, label);
        expect(tester.takeException(), isNull);
        if (label == 'Outfits' || label == 'Profile') {
          await openAction(
            tester,
            label == 'Outfits' ? 'Favorites' : 'Wear History',
          );
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets('Navigation controls have accessible labels and touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const WardrobeApp());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('Home')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Wardrobe')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Outfits')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Profile')), findsWidgets);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      for (final label in ['Outfits', 'Profile']) {
        await selectTab(tester, label);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
    } finally {
      semantics.dispose();
    }
  });
}
