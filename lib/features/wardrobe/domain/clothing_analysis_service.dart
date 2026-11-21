import 'clothing_item.dart';

class ClothingAnalysisSuggestion {
  const ClothingAnalysisSuggestion({
    this.category,
    this.subcategory,
    this.color,
    this.style,
    this.season,
  });

  final ClothingCategory? category;
  final String? subcategory;
  final String? color;
  final String? style;
  final ClothingSeason? season;
}

abstract interface class ClothingAnalysisService {
  bool get isDevelopmentStub;

  Future<ClothingAnalysisSuggestion?> analyze(String imagePath);
}

class UnavailableClothingAnalysisService implements ClothingAnalysisService {
  const UnavailableClothingAnalysisService();

  @override
  bool get isDevelopmentStub => false;

  @override
  Future<ClothingAnalysisSuggestion?> analyze(String imagePath) async => null;
}
