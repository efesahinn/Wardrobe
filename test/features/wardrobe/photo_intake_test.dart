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

void main() {
  const analysisService = DevelopmentClothingAnalysisService(
    suggestion: ClothingAnalysisSuggestion(
      category: ClothingCategory.tops,
      color: 'Black',
      season: ClothingSeason.allSeasons,
    ),
  );

  testWidgets('warns about gallery quality and allows using photo anyway', (
    tester,
  ) async {
    final repository = InMemoryWardrobeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ClothingFormScreen(
          repository: repository,
          analysisService: analysisService,
          pickImage: () async => '/warning.jpg',
          checkImageQuality: (_) async => ImageQualityReport(
            width: 800,
            height: 800,
            issues: const [
              ImageQualityIssue.tooDark,
              ImageQualityIssue.potentiallyBlurry,
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose gallery image'));
    await tester.pumpAndSettle();
    expect(find.text('Check photo quality'), findsOneWidget);
    expect(find.text('Choose another'), findsOneWidget);
    expect(find.text('Use anyway'), findsOneWidget);
    expect(
      find.textContaining(ImageQualityIssue.tooDark.message),
      findsOneWidget,
    );

    await tester.tap(find.text('Use anyway'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm metadata'));
    await tester.tap(find.text('Confirm metadata'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-quality-warning')), findsOneWidget);
    expect(find.text('Remove image'), findsOneWidget);

    await enter(tester, 'Name', 'Dark shirt');
    await choose(tester, 'Category', 'Tops');
    await enter(tester, 'Color', 'Black');
    await choose(tester, 'Season', 'All seasons');
    await tester.ensureVisible(find.text('Save clothing'));
    await tester.tap(find.text('Save clothing'));
    await tester.pumpAndSettle();

    expect((await repository.getAll()).single.imageReference, '/warning.jpg');
  });

  testWidgets('camera warning supports retaking before accepting a photo', (
    tester,
  ) async {
    var cameraCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ClothingFormScreen(
          repository: InMemoryWardrobeRepository(),
          analysisService: analysisService,
          takePhoto: () async =>
              cameraCalls++ == 0 ? '/low-resolution.jpg' : '/good.jpg',
          checkImageQuality: (path) async => ImageQualityReport(
            width: path == '/good.jpg' ? 1200 : 240,
            height: path == '/good.jpg' ? 1200 : 320,
            issues: path == '/good.jpg'
                ? const []
                : const [ImageQualityIssue.insufficientResolution],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(find.text('Retake'), findsOneWidget);
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Confirm metadata'));
    await tester.tap(find.text('Confirm metadata'));
    await tester.pumpAndSettle();

    expect(cameraCalls, 2);
    expect(find.text('Check photo quality'), findsNothing);
    expect(find.text('Remove image'), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-quality-warning')), findsNothing);
  });
}
