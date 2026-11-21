import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/core/theme/app_theme.dart';
import 'package:wardrobe_plus/app.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/gallery_image_picker.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/wardrobe_screen.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_detail_screen.dart';

Future<void> start(
  WidgetTester tester,
  InMemoryWardrobeRepository repository, {
  PickClothingImage? picker,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: SafeArea(
          child: WardrobeScreen(
            repository: repository,
            pickImage: picker ?? () async => null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      160,
      scrollable: find.byType(Scrollable).last,
    );
  }
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      160,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String label, String option) async {
  final field = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField &&
        widget.decoration.labelText == label,
  );
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      160,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tapText(tester, option);
}

void smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 480);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets(
    'Details swipes expose information and actions on a small screen',
    (tester) async {
      smallScreen(tester);
      final repository = InMemoryWardrobeRepository.seeded();
      final item = (await repository.getAll()).first;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: ClothingDetailScreen(item: item, repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.descendant(
        of: find.byType(ClothingDetailScreen),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.pixels, 0);
      expect(position.maxScrollExtent, greaterThan(0));
      expect(find.text('Delete clothing').hitTestable(), findsNothing);

      // Start the gesture on the clothing image, rather than using ensureVisible.
      await tester.dragFrom(const Offset(160, 220), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(find.text('Category: Tops').hitTestable(), findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Color: White').hitTestable(), findsOneWidget);
      expect(find.text('Season: All seasons').hitTestable(), findsOneWidget);
      expect(find.text('Size: Not specified'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Edit clothing'),
        160,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit clothing').hitTestable(), findsOneWidget);
      expect(find.text('Delete clothing').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Edit clothing'));
      await tester.pumpAndSettle();
      expect(find.text('Edit clothing'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete clothing'));
      await tester.pumpAndSettle();
      expect(find.text('Delete clothing?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repository.getAll()).length, 3);

      await tester.drag(scrollable, const Offset(0, 800));
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
      expect(
        find.bySemanticsLabel('Photo of White cotton shirt'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Wardrobe filter and data survive tab switches in the app shell',
    (tester) async {
      await tester.pumpWidget(const WardrobeApp());
      await tester.pumpAndSettle();
      Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );
      await tester.tap(tab('Wardrobe'));
      await tester.pumpAndSettle();
      await choose(tester, 'Filter by category', 'Tops');
      await tapText(tester, 'White cotton shirt');
      await tapText(tester, 'Edit clothing');
      await enter(tester, 'Name', 'Edited sample shirt');
      await tapText(tester, 'Save clothing');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Wardrobe'));
      await tester.pumpAndSettle();
      expect(find.text('Edited sample shirt'), findsOneWidget);
      expect(find.text('Indigo jeans'), findsNothing);
      await choose(tester, 'Filter by category', 'All');
      expect(find.text('Indigo jeans'), findsOneWidget);
    },
  );
  testWidgets('Browse sample grid, filter, show no matches, and restore All', (
    tester,
  ) async {
    final repo = InMemoryWardrobeRepository.seeded();
    await start(tester, repo);
    expect(find.text('White cotton shirt'), findsOneWidget);
    await choose(tester, 'Filter by category', 'Bottoms');
    expect(find.text('Indigo jeans'), findsOneWidget);
    expect(find.text('White cotton shirt'), findsNothing);
    await choose(tester, 'Filter by category', 'Dresses');
    expect(find.text('No matching clothing'), findsOneWidget);
    await choose(tester, 'Filter by category', 'All');
    expect(find.text('White cotton shirt'), findsOneWidget);
  });

  testWidgets('Validate empty and whitespace fields without creating an item', (
    tester,
  ) async {
    smallScreen(tester);
    final repo = InMemoryWardrobeRepository();
    await start(tester, repo);
    await tapText(tester, 'Add clothing');
    await enter(tester, 'Name', '   ');
    await enter(tester, 'Color', '   ');
    await tapText(tester, 'Save clothing');
    expect(find.text('Enter a clothing name.'), findsOneWidget);
    expect(find.text('Enter a color.'), findsOneWidget);
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(find.text('Choose a season.'), findsOneWidget);
    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('Add clothing with gallery selection and view details', (
    tester,
  ) async {
    final repo = InMemoryWardrobeRepository();
    var picks = 0;
    await start(
      tester,
      repo,
      picker: () async {
        picks++;
        return '/missing-image.jpg';
      },
    );
    await tapText(tester, 'Add clothing');
    await tapText(tester, 'Choose gallery image');
    expect(picks, 1);
    expect(find.text('Remove image'), findsOneWidget);
    await enter(tester, 'Name', 'Blue linen shirt');
    await choose(tester, 'Category', 'Tops');
    await enter(tester, 'Subcategory (optional)', 'Linen shirt');
    await enter(tester, 'Style (optional)', 'Smart casual');
    await choose(tester, 'Size (optional)', 'M');
    await enter(tester, 'Color', 'Blue');
    await choose(tester, 'Season', 'Summer');
    await tapText(tester, 'Save clothing');
    expect(find.text('Blue linen shirt'), findsOneWidget);
    expect((await repo.getAll()).single.imageReference, '/missing-image.jpg');
    await tapText(tester, 'Blue linen shirt');
    expect(find.text('Clothing details'), findsOneWidget);
    expect(find.text('Category: Tops'), findsOneWidget);
    expect(find.text('Subcategory: Linen shirt'), findsOneWidget);
    expect(find.text('Style: Smart casual'), findsOneWidget);
    expect(find.text('Size: M'), findsOneWidget);
    expect(find.text('Color: Blue'), findsOneWidget);
    expect(find.text('Season: Summer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Edit displays repository-normalized metadata and refreshes detail',
    (tester) async {
      final repo = InMemoryWardrobeRepository();
      final original = await repo.create(
        name: 'Old shirt',
        category: ClothingCategory.tops,
        color: 'White',
        season: ClothingSeason.spring,
        size: 'S',
        subcategory: 'T-shirt',
        style: 'Casual',
        imageReference: '/missing.jpg',
      );
      await start(tester, repo);
      await tapText(tester, 'Old shirt');
      await tapText(tester, 'Edit clothing');
      expect(find.widgetWithText(TextFormField, 'Old shirt'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'T-shirt'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Casual'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      await tapText(tester, 'Remove image');
      await enter(tester, 'Name', 'Updated jacket');
      await choose(tester, 'Category', 'Outerwear');
      await enter(tester, 'Subcategory (optional)', '  Rain jacket  ');
      await enter(tester, 'Style (optional)', '  Outdoor  ');
      await enter(tester, 'Size (optional)', '  Regular  ');
      await enter(tester, 'Color', 'Olive');
      await choose(tester, 'Season', 'Winter');
      await tapText(tester, 'Save clothing');
      expect(find.text('Updated jacket'), findsOneWidget);
      expect(find.text('Category: Outerwear'), findsOneWidget);
      expect(find.text('Subcategory: Rain jacket'), findsOneWidget);
      expect(find.text('Style: Outdoor'), findsOneWidget);
      expect(find.text('Size: Regular'), findsOneWidget);
      expect(find.text('Color: Olive'), findsOneWidget);
      expect(find.text('Season: Winter'), findsOneWidget);
      final stored = (await repo.getById(original.id))!;
      expect(stored.subcategory, 'Rain jacket');
      expect(stored.style, 'Outdoor');
      expect(stored.size, 'Regular');
      expect(stored.imageReference, isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Updated jacket'), findsOneWidget);
      expect(find.text('Old shirt'), findsNothing);
    },
  );

  testWidgets('Bottom size validation accepts numeric and W/L formats', (
    tester,
  ) async {
    final repo = InMemoryWardrobeRepository();
    await start(tester, repo);
    await tapText(tester, 'Add clothing');
    await enter(tester, 'Name', 'Black trousers');
    await choose(tester, 'Category', 'Bottoms');
    await enter(tester, 'Size (optional)', 'Medium');
    await enter(tester, 'Color', 'Black');
    await choose(tester, 'Season', 'All seasons');
    await tapText(tester, 'Save clothing');
    expect(
      find.text('Use a number or W/L size, such as 32 or W32/L34.'),
      findsOneWidget,
    );
    expect(await repo.getAll(), isEmpty);

    await enter(tester, 'Size (optional)', 'W32/L34');
    await tapText(tester, 'Save clothing');
    expect((await repo.getAll()).single.size, 'W32/L34');
    expect(find.text('Black trousers'), findsOneWidget);
  });

  testWidgets('Delete requires confirmation and refreshes the empty list', (
    tester,
  ) async {
    final repo = InMemoryWardrobeRepository();
    await repo.create(
      name: 'Shirt',
      category: ClothingCategory.tops,
      color: 'White',
      season: ClothingSeason.summer,
    );
    await start(tester, repo);
    await tapText(tester, 'Shirt');
    await tapText(tester, 'Delete clothing');
    await tapText(tester, 'Cancel');
    expect((await repo.getAll()).length, 1);
    expect(find.text('Clothing details'), findsOneWidget);
    await tapText(tester, 'Delete clothing');
    await tapText(tester, 'Delete');
    expect(await repo.getAll(), isEmpty);
    await tester.scrollUntilVisible(
      find.text('Your wardrobe is empty'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Your wardrobe is empty'), findsOneWidget);
  });

  testWidgets('Gallery cancellation and leaving a form do not change storage', (
    tester,
  ) async {
    final repo = InMemoryWardrobeRepository.seeded();
    await start(tester, repo);
    await tapText(tester, 'Add clothing');
    await tapText(tester, 'Choose gallery image');
    expect(find.text('Remove image'), findsNothing);
    await enter(tester, 'Name', 'Unsaved shirt');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect((await repo.getAll()).length, 3);
    expect(find.text('Unsaved shirt'), findsNothing);
  });

  testWidgets('Gallery failure displays actionable feedback', (tester) async {
    await start(
      tester,
      InMemoryWardrobeRepository(),
      picker: () async => throw Exception('Gallery unavailable'),
    );
    await tapText(tester, 'Add clothing');
    await tapText(tester, 'Choose gallery image');
    expect(
      find.text(
        'Could not open the gallery. Check photo access and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Choose gallery image'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CRUD layouts support a small screen with large text', (
    tester,
  ) async {
    smallScreen(tester);
    await start(tester, InMemoryWardrobeRepository.seeded());
    await tapText(tester, 'White cotton shirt');
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Edit clothing');
    await enter(tester, 'Name', 'Large text shirt');
    await choose(tester, 'Season', 'Winter');
    await tapText(tester, 'Save clothing');
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Delete clothing');
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Cancel');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
