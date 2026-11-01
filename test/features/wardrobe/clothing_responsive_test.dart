import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/core/theme/app_theme.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_detail_screen.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_form_screen.dart';

void viewport(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
}

Finder input(String label) => label == 'Name' || label == 'Color'
    ? find.widgetWithText(TextFormField, label)
    : find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField &&
            widget.decoration.labelText == label,
      );
void main() {
  for (final config in [
    (size: const Size(412, 1000), scale: 1.0),
    (size: const Size(320, 480), scale: 2.0),
    (size: const Size(740, 360), scale: 1.5),
    (size: const Size(320, 640), scale: 3.0),
  ]) {
    testWidgets('Details fits ${config.size} at ${config.scale}x', (
      tester,
    ) async {
      viewport(tester, config.size, config.scale);
      final repository = InMemoryWardrobeRepository.seeded();
      final item = (await repository.getAll()).first;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: ClothingDetailScreen(item: item, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      if (config.size.height == 1000) {
        expect(position.maxScrollExtent, 0);
        expect(
          tester
              .getBottomRight(
                find.widgetWithText(OutlinedButton, 'Delete clothing'),
              )
              .dy,
          closeTo(config.size.height - 24 - 16, 1),
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(position.pixels, 0);
      } else {
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
      }
      for (final text in [
        'Category: Tops',
        'Color: White',
        'Season: All seasons',
        'Edit clothing',
        'Delete clothing',
      ]) {
        await reveal(tester, find.text(text));
      }
      expect(tester.takeException(), isNull);
    });

    for (final editing in [false, true]) {
      testWidgets(
        '${editing ? "Edit" : "Add"} fits ${config.size} at ${config.scale}x',
        (tester) async {
          viewport(tester, config.size, config.scale);
          final repository = InMemoryWardrobeRepository.seeded();
          final item = (await repository.getAll()).first;
          await tester.pumpWidget(
            MaterialApp(
              theme: appTheme,
              home: ClothingFormScreen(
                repository: repository,
                item: editing ? item : null,
                pickImage: () async => null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (editing) {
            expect(
              find.widgetWithText(TextFormField, item.name),
              findsOneWidget,
            );
            expect(
              find.widgetWithText(TextFormField, item.color),
              findsOneWidget,
            );
          }
          for (final label in [
            'Choose gallery image',
            'Name',
            'Category',
            'Color',
            'Season',
          ]) {
            await reveal(
              tester,
              label == 'Choose gallery image'
                  ? find.widgetWithText(OutlinedButton, label)
                  : input(label),
            );
          }
          final save = find.widgetWithText(FilledButton, 'Save clothing');
          await reveal(tester, save);
          if (config.size.height == 1000) {
            final position = tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            expect(position.maxScrollExtent, 0);
            expect(
              tester.getBottomRight(save).dy,
              closeTo(config.size.height - 24 - 16, 1),
            );
          }
          if (!editing) {
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(find.text('Enter a clothing name.'), findsOneWidget);
            expect(find.text('Enter a color.'), findsOneWidget);
            expect(find.text('Choose a category.'), findsOneWidget);
            expect(find.text('Choose a season.'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? "Edit" : "Add"} keeps focused field and Save above keyboard',
      (tester) async {
        viewport(tester, const Size(360, 640), 1.5);
        final repository = InMemoryWardrobeRepository.seeded();
        final item = (await repository.getAll()).first;
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ClothingFormScreen(
                          repository: repository,
                          item: editing ? item : null,
                          pickImage: () async => null,
                        ),
                      ),
                    ),
                    child: const Text('Open form'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open form'));
        await tester.pumpAndSettle();
        final name = find.widgetWithText(TextFormField, 'Name');
        await reveal(tester, name);
        await tester.enterText(name, 'Keyboard shirt');
        if (!editing) {
          for (final selection in [
            ('Category', 'Tops'),
            ('Season', 'Summer'),
          ]) {
            final field = find.text(selection.$1).last;
            await reveal(tester, field);
            await tester.tap(field);
            await tester.pumpAndSettle();
            await tester.tap(find.text(selection.$2).last);
            await tester.pumpAndSettle();
          }
        }
        final color = find.widgetWithText(TextFormField, 'Color');
        await reveal(tester, color);
        await tester.showKeyboard(color);
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        tester.view.padding = const FakeViewPadding(top: 24);
        await tester.pumpAndSettle();
        await tester.enterText(color, 'Blue');
        await reveal(tester, color);
        expect(tester.getBottomRight(color).dy, lessThanOrEqualTo(400));
        expect(tester.takeException(), isNull);

        final save = find.widgetWithText(FilledButton, 'Save clothing');
        await reveal(tester, save);
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(400));
        await tester.tap(save);
        await tester.pumpAndSettle();
        final saved = (await repository.getAll())
            .where((item) => item.name == 'Keyboard shirt')
            .single;
        expect(saved.color, 'Blue');
        expect((await repository.getAll()).length, editing ? 3 : 4);
        if (editing) expect(saved.id, item.id);
        expect(find.text('Open form'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
