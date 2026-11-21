import '../domain/clothing_analysis_service.dart';

/// Test-only sample provider. Its values are not AI predictions.
class DevelopmentClothingAnalysisService implements ClothingAnalysisService {
  const DevelopmentClothingAnalysisService({required this.suggestion});

  final ClothingAnalysisSuggestion suggestion;

  @override
  bool get isDevelopmentStub => true;

  @override
  Future<ClothingAnalysisSuggestion> analyze(String imagePath) async =>
      suggestion;
}
