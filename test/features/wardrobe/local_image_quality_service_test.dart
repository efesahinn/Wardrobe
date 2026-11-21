import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/features/wardrobe/data/local_image_quality_service.dart';

Future<Uint8List> createPng(
  int width,
  int height,
  void Function(ui.Canvas canvas, ui.Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final size = ui.Size(width.toDouble(), height.toDouble());
  paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void fill(ui.Canvas canvas, ui.Size size, int color) {
  canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = ui.Color(color));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LocalImageQualityService();

  test('detects insufficient image resolution', () async {
    final bytes = await createPng(
      240,
      320,
      (canvas, size) => fill(canvas, size, 0xFF808080),
    );

    final report = await service.inspectBytes(bytes);

    expect(report.width, 240);
    expect(report.height, 320);
    expect(report.issues, contains(ImageQualityIssue.insufficientResolution));
  });

  test('detects very dark and overexposed images', () async {
    final dark = await createPng(
      800,
      800,
      (canvas, size) => fill(canvas, size, 0xFF101010),
    );
    final bright = await createPng(
      800,
      800,
      (canvas, size) => fill(canvas, size, 0xFFFFFFFF),
    );

    expect(
      (await service.inspectBytes(dark)).issues,
      contains(ImageQualityIssue.tooDark),
    );
    expect(
      (await service.inspectBytes(bright)).issues,
      contains(ImageQualityIssue.overexposed),
    );
  });

  test('uses a best-effort sharpness heuristic', () async {
    final smooth = await createPng(
      800,
      800,
      (canvas, size) => fill(canvas, size, 0xFF808080),
    );
    final sharp = await createPng(800, 800, (canvas, size) {
      const square = 20.0;
      for (var y = 0.0; y < size.height; y += square) {
        for (var x = 0.0; x < size.width; x += square) {
          final dark = ((x / square).floor() + (y / square).floor()).isEven;
          canvas.drawRect(
            ui.Rect.fromLTWH(x, y, square, square),
            ui.Paint()..color = ui.Color(dark ? 0xFF202020 : 0xFFE0E0E0),
          );
        }
      }
    });

    expect(
      (await service.inspectBytes(smooth)).issues,
      contains(ImageQualityIssue.potentiallyBlurry),
    );
    expect(
      (await service.inspectBytes(sharp)).issues,
      isNot(contains(ImageQualityIssue.potentiallyBlurry)),
    );
  });

  test('does not mark a valid white-background photo as overexposed', () async {
    final bytes = await createPng(800, 800, (canvas, size) {
      fill(canvas, size, 0xFFFFFFFF);
      canvas.drawRect(
        const ui.Rect.fromLTWH(180, 100, 440, 600),
        ui.Paint()..color = const ui.Color(0xFF2457A7),
      );
      canvas.drawLine(
        const ui.Offset(180, 100),
        const ui.Offset(620, 700),
        ui.Paint()
          ..color = const ui.Color(0xFF102040)
          ..strokeWidth = 12,
      );
    });

    final report = await service.inspectBytes(bytes);

    expect(report.issues, isNot(contains(ImageQualityIssue.overexposed)));
  });
}
