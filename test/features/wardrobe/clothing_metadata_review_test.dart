import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/features/wardrobe/data/development_clothing_analysis_service.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/data/local_image_quality_service.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_analysis_service.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_form_screen.dart';

Future<void> choose(WidgetTester tester, String label, String option) async {
  final field = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField &&
        widget.decoration.labelText == label,
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> confirmMetadata(WidgetTester tester) async {
  final button = find.text('Confirm metadata');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  Future<ImageQualityReport> cleanPhoto(String path) async =>
      ImageQualityReport(width: 1200, height: 1200, issues: const []);

  testWidgets('development stub suggestions are labeled, editable, and saved', (
    tester,
  ) async {
    final repository = InMemoryWardrobeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ClothingFormScreen(
          repository: repository,
          pickImage: () async => '/stub-photo.jpg',
          checkImageQuality: cleanPhoto,
          analysisService: const DevelopmentClothingAnalysisService(
            suggestion: ClothingAnalysisSuggestion(
              category: ClothingCategory.tops,
              subcategory: 'T-shirt',
              color: 'Blue',
              style: 'Casual',
              season: ClothingSeason.summer,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose gallery image'));
    await tester.pumpAndSettle();

    expect(find.text('Review clothing metadata'), findsOneWidget);
    expect(
      find.text(
        'Development stub: these are sample test values, not real AI predictions.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'T-shirt'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Blue'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Casual'), findsOneWidget);
    expect(find.text('Size (optional)'), findsNothing);

    await enter(tester, 'Color', 'Navy');
    await enter(tester, 'Style (optional)', 'Smart casual');
    await confirmMetadata(tester);

    expect(find.text('Add clothing'), findsOneWidget);
    expect(find.text('Size (optional)'), findsOneWidget);
    await enter(tester, 'Name', 'Navy shirt');
    await choose(tester, 'Size (optional)', 'M');
    final save = find.text('Save clothing');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final item = (await repository.getAll()).single;
    expect(item.category, ClothingCategory.tops);
    expect(item.subcategory, 'T-shirt');
    expect(item.color, 'Navy');
    expect(item.style, 'Smart casual');
    expect(item.season, ClothingSeason.summer);
    expect(item.size, 'M');
    expect(item.imageReference, '/stub-photo.jpg');
  });

  testWidgets('unavailable analysis keeps the complete manual path usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ClothingFormScreen(
          repository: InMemoryWardrobeRepository(),
          pickImage: () async => '/manual-photo.jpg',
          checkImageQuality: cleanPhoto,
        ),
      ),
    );

    await tester.tap(find.text('Choose gallery image'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Automated analysis is unavailable. Enter the metadata manually to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Remove image'), findsNothing);

    await choose(tester, 'Category', 'Outerwear');
    await enter(tester, 'Subcategory (optional)', 'Rain jacket');
    await enter(tester, 'Color', 'Olive');
    await enter(tester, 'Style (optional)', 'Outdoor');
    await choose(tester, 'Season', 'Autumn');
    await confirmMetadata(tester);

    expect(find.text('Remove image'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Rain jacket'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Olive'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Outdoor'), findsOneWidget);
  });
}
