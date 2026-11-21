import 'clothing_item.dart';

enum ClothingSizeInputType { alpha, bottoms, euShoes, freeText }

extension ClothingCategorySizeInput on ClothingCategory {
  ClothingSizeInputType get sizeInputType => switch (this) {
    ClothingCategory.tops => ClothingSizeInputType.alpha,
    ClothingCategory.bottoms => ClothingSizeInputType.bottoms,
    ClothingCategory.shoes => ClothingSizeInputType.euShoes,
    _ => ClothingSizeInputType.freeText,
  };
}

abstract final class ClothingMetadataRules {
  static const topSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const maxSizeLength = 20;
  static const maxOptionalTextLength = 40;

  static final _numericBottomSize = RegExp(r'^\d{1,3}$');
  static final _waistLengthSize = RegExp(
    r'^(?:W\s*)?\d{1,3}\s*[/x-]\s*(?:L\s*)?\d{1,3}$',
    caseSensitive: false,
  );

  static String? normalizedOptionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? normalizedSize(ClothingCategory category, String? value) {
    final normalized = normalizedOptionalText(value);
    if (normalized == null) return null;
    return switch (category.sizeInputType) {
      ClothingSizeInputType.alpha => normalized.toUpperCase(),
      ClothingSizeInputType.bottoms => normalized.toUpperCase().replaceAll(
        RegExp(r'\s+'),
        '',
      ),
      ClothingSizeInputType.euShoes ||
      ClothingSizeInputType.freeText => normalized,
    };
  }

  static String? validateOptionalText(String? value, String fieldName) {
    final normalized = normalizedOptionalText(value);
    if (normalized != null && normalized.length > maxOptionalTextLength) {
      return '$fieldName must be $maxOptionalTextLength characters or fewer.';
    }
    return null;
  }

  static String? validateSize(ClothingCategory category, String? value) {
    final normalized = normalizedSize(category, value);
    if (normalized == null) return null;
    if (normalized.length > maxSizeLength) {
      return 'Size must be $maxSizeLength characters or fewer.';
    }
    if (category.sizeInputType == ClothingSizeInputType.euShoes) {
      final size = double.tryParse(normalized);
      if (size == null) {
        return 'Enter a numeric EU shoe size, such as 42 or 42.5.';
      }
      if (size < 20 || size > 55) {
        return 'Enter an EU shoe size from 20 to 55.';
      }
      return null;
    }
    return switch (category.sizeInputType) {
      ClothingSizeInputType.alpha when !topSizes.contains(normalized) =>
        'Choose XS, S, M, L, XL, or XXL.',
      ClothingSizeInputType.bottoms
          when !_numericBottomSize.hasMatch(normalized) &&
              !_waistLengthSize.hasMatch(normalized) =>
        'Use a number or W/L size, such as 32 or W32/L34.',
      _ => null,
    };
  }
}
