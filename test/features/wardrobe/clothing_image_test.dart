import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/core/theme/app_theme.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/data/local_image_quality_service.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_detail_screen.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/screens/clothing_form_screen.dart';
import 'package:wardrobe_plus/features/wardrobe/presentation/widgets/clothing_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory fixtures;
  final photos = <String, (File, Size)>{};

  setUpAll(() async {
    fixtures = await Directory.systemTemp.createTemp('wardrobe-image-test-');
    for (final dimensions in {
      'portrait': const Size(100, 240),
      'landscape': const Size(240, 100),
      'square': const Size(160, 160),
    }.entries) {
      final size = dimensions.value;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue);
      // Distinct top and bottom edges represent content that cover would crop.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, 10),
        Paint()..color = Colors.red,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - 10, size.width, 10),
        Paint()..color = Colors.green,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${fixtures.path}/${dimensions.key}.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      photos[dimensions.key] = (file, size);
      image.dispose();
      picture.dispose();
    }
  });

  tearDownAll(() async => fixtures.delete(recursive: true));

  for (final viewport in [const Size(320, 480), const Size(740, 360)]) {
    for (final shape in ['portrait', 'landscape', 'square']) {
      for (final screen in ['Details', 'Add', 'Edit']) {
        testWidgets('$screen contains complete $shape photo at $viewport', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport;
          addTearDown(tester.view.reset);
          final (file, originalSize) = photos[shape]!;
          await tester.pumpWidget(const MaterialApp(home: Scaffold()));
          await tester.runAsync(
            () => precacheImage(
              FileImage(file),
              tester.element(find.byType(Scaffold)),
            ),
          );
          final repository = InMemoryWardrobeRepository();
          final item = await repository.create(
            name: 'Test photo',
            category: ClothingCategory.tops,
            color: 'Blue',
            season: ClothingSeason.summer,
            imageReference: file.path,
          );
          final Widget page = screen == 'Details'
              ? ClothingDetailScreen(item: item, repository: repository)
              : ClothingFormScreen(
                  repository: repository,
                  item: screen == 'Edit' ? item : null,
                  pickImage: () async => file.path,
                  checkImageQuality: (_) async => ImageQualityReport(
                    width: originalSize.width.toInt(),
                    height: originalSize.height.toInt(),
                    issues: const [],
                  ),
                );
          await tester.pumpWidget(MaterialApp(theme: appTheme, home: page));
          await tester.pumpAndSettle();
          final frame = find.byType(ClothingImage);
          final frameSize = tester.getSize(frame);
          final scroll = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          final extent = scroll.maxScrollExtent;

          if (screen == 'Add') {
            await tester.tap(
              find.widgetWithText(OutlinedButton, 'Choose gallery image'),
            );
            await tester.pumpAndSettle();
          }
          final raw = find.descendant(
            of: frame,
            matching: find.byType(RawImage),
          );
          final rendered = tester.renderObject<RenderImage>(raw);
          expect(rendered.image, isNotNull);
          expect(
            Size(
              rendered.image!.width.toDouble(),
              rendered.image!.height.toDouble(),
            ),
            originalSize,
          );
          expect(rendered.fit, BoxFit.contain);
          final fitted = applyBoxFit(
            rendered.fit!,
            originalSize,
            rendered.size,
          );
          expect(
            fitted.source,
            originalSize,
            reason: 'No source pixels are cropped',
          );
          expect(
            fitted.destination.width / fitted.destination.height,
            closeTo(originalSize.width / originalSize.height, 0.0001),
          );
          expect(fitted.destination.width, lessThanOrEqualTo(frameSize.width));
          expect(
            fitted.destination.height,
            lessThanOrEqualTo(frameSize.height),
          );
          expect(
            tester.getSize(frame),
            frameSize,
            reason: 'Loading a photo must not move the form or actions',
          );
          // Add reveals Remove image; decoding itself must not alter the frame.
          if (screen != 'Add') expect(scroll.maxScrollExtent, extent);
          final background = tester.widget<ColoredBox>(
            find.descendant(of: frame, matching: find.byType(ColoredBox)),
          );
          expect(background.color, Colors.grey.shade200);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Missing and unreadable photos retain the placeholder', (
    tester,
  ) async {
    for (final path in [null, '/nonexistent/clothing.jpg']) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: ClothingImage(reference: path, label: 'Clothing photo'),
          ),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
