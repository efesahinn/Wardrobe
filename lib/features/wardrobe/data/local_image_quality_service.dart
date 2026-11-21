import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

enum ImageQualityIssue {
  insufficientResolution,
  tooDark,
  overexposed,
  potentiallyBlurry,
}

extension ImageQualityIssueMessage on ImageQualityIssue {
  String get message => switch (this) {
    ImageQualityIssue.insufficientResolution =>
      'The photo resolution is low. A larger image will show more detail.',
    ImageQualityIssue.tooDark =>
      'The photo is very dark. Try brighter, even lighting.',
    ImageQualityIssue.overexposed =>
      'The photo may be overexposed. Reduce glare or direct light.',
    ImageQualityIssue.potentiallyBlurry =>
      'The photo may be blurry. Hold the camera steady and refocus.',
  };
}

class ImageQualityReport {
  ImageQualityReport({
    required this.width,
    required this.height,
    required Iterable<ImageQualityIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final int width;
  final int height;
  final List<ImageQualityIssue> issues;

  bool get hasWarnings => issues.isNotEmpty;
}

typedef CheckClothingImageQuality = Future<ImageQualityReport> Function(
  String path,
);

class LocalImageQualityService {
  const LocalImageQualityService({
    this.minimumWidth = 600,
    this.minimumHeight = 600,
    this.darkLuminanceThreshold = 45,
    this.overexposedLuminanceThreshold = 245,
    this.overexposedDeviationThreshold = 18,
    this.blurVarianceThreshold = 100,
  });

  final int minimumWidth;
  final int minimumHeight;
  final double darkLuminanceThreshold;
  final double overexposedLuminanceThreshold;
  final double overexposedDeviationThreshold;
  final double blurVarianceThreshold;

  Future<ImageQualityReport> inspectFile(String path) async =>
      inspectBytes(await File(path).readAsBytes());

  Future<ImageQualityReport> inspectBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (pixels == null) throw const FormatException('Unreadable image.');
        return _inspectPixels(
          pixels.buffer.asUint8List(),
          image.width,
          image.height,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  ImageQualityReport _inspectPixels(Uint8List rgba, int width, int height) {
    final issues = <ImageQualityIssue>[];
    if (width < minimumWidth || height < minimumHeight) {
      issues.add(ImageQualityIssue.insufficientResolution);
    }

    final step = math.max(1, math.sqrt((width * height) / 40000).floor());
    var sampleCount = 0;
    var luminanceSum = 0.0;
    var luminanceSquaredSum = 0.0;
    for (var y = 0; y < height; y += step) {
      for (var x = 0; x < width; x += step) {
        final luminance = _luminanceAt(rgba, width, x, y);
        sampleCount++;
        luminanceSum += luminance;
        luminanceSquaredSum += luminance * luminance;
      }
    }
    final mean = luminanceSum / sampleCount;
    final variance = math.max(
      0,
      (luminanceSquaredSum / sampleCount) - (mean * mean),
    );
    final deviation = math.sqrt(variance);
    if (mean < darkLuminanceThreshold) {
      issues.add(ImageQualityIssue.tooDark);
    } else if (mean > overexposedLuminanceThreshold &&
        deviation < overexposedDeviationThreshold) {
      issues.add(ImageQualityIssue.overexposed);
    }

    var laplacianCount = 0;
    var laplacianSum = 0.0;
    var laplacianSquaredSum = 0.0;
    for (var y = step; y < height - step; y += step) {
      for (var x = step; x < width - step; x += step) {
        final center = _luminanceAt(rgba, width, x, y);
        final laplacian =
            (4 * center) -
            _luminanceAt(rgba, width, x - step, y) -
            _luminanceAt(rgba, width, x + step, y) -
            _luminanceAt(rgba, width, x, y - step) -
            _luminanceAt(rgba, width, x, y + step);
        laplacianCount++;
        laplacianSum += laplacian;
        laplacianSquaredSum += laplacian * laplacian;
      }
    }
    if (laplacianCount > 0) {
      final laplacianMean = laplacianSum / laplacianCount;
      final laplacianVariance = math.max(
        0,
        (laplacianSquaredSum / laplacianCount) -
            (laplacianMean * laplacianMean),
      );
      if (laplacianVariance < blurVarianceThreshold) {
        issues.add(ImageQualityIssue.potentiallyBlurry);
      }
    }

    return ImageQualityReport(width: width, height: height, issues: issues);
  }

  double _luminanceAt(Uint8List rgba, int width, int x, int y) {
    final offset = ((y * width) + x) * 4;
    return ((299 * rgba[offset]) +
            (587 * rgba[offset + 1]) +
            (114 * rgba[offset + 2])) /
        1000;
  }
}

Future<ImageQualityReport> checkLocalImageQuality(String path) =>
    const LocalImageQualityService().inspectFile(path);
