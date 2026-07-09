import '../../../core/models/macronutrients_model.dart';

class MealModel {
  const MealModel({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.occurredAt,
    required this.totalMacronutrients,
    required this.items,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return MealModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      mealType: json['mealType']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? ''),
      totalMacronutrients: MacronutrientsModel.fromJson(
        json['totalMacronutrients'] as Map<String, dynamic>?,
      ),
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(MealItemModel.fromJson)
                .toList()
          : const [],
    );
  }

  final String id;
  final String userId;
  final String mealType;
  final DateTime? occurredAt;
  final MacronutrientsModel totalMacronutrients;
  final List<MealItemModel> items;
}

class MealItemModel {
  const MealItemModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.macronutrients,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      id: json['id'] as String? ?? '',
      foodId: json['foodId'] as String? ?? '',
      foodName: json['foodName'] as String? ?? 'Item sem nome',
      grams: _decimal(json['grams']),
      macronutrients: MacronutrientsModel.fromJson(
        json['macronutrients'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String foodId;
  final String foodName;
  final double grams;
  final MacronutrientsModel macronutrients;

  static double _decimal(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
