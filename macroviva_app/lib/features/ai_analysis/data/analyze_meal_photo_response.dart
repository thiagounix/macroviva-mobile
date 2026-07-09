class AnalyzeMealPhotoResponse {
  const AnalyzeMealPhotoResponse({
    required this.analysisId,
    required this.fileReference,
    required this.items,
  });

  factory AnalyzeMealPhotoResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return AnalyzeMealPhotoResponse(
      analysisId: json['analysisId'] as String? ?? '',
      fileReference: json['fileReference'] as String? ?? '',
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(DetectedMealItemModel.fromJson)
                .toList()
          : const [],
    );
  }

  final String analysisId;
  final String fileReference;
  final List<DetectedMealItemModel> items;
}

class DetectedMealItemModel {
  const DetectedMealItemModel({
    required this.analysisItemId,
    required this.suggestedFoodName,
    required this.grams,
    required this.confidenceLevel,
    required this.confidenceScore,
    required this.suggestedFoodId,
  });

  factory DetectedMealItemModel.fromJson(Map<String, dynamic> json) {
    return DetectedMealItemModel(
      analysisItemId: json['analysisItemId'] as String? ?? '',
      suggestedFoodName:
          json['suggestedFoodName'] as String? ?? 'Item detectado',
      grams: _decimal(json['grams']),
      confidenceLevel: json['confidenceLevel']?.toString() ?? '',
      confidenceScore: _decimal(json['confidenceScore']),
      suggestedFoodId: json['suggestedFoodId'] as String?,
    );
  }

  final String analysisItemId;
  final String suggestedFoodName;
  final double grams;
  final String confidenceLevel;
  final double confidenceScore;
  final String? suggestedFoodId;

  static double _decimal(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
}
