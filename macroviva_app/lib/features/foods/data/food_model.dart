import '../../../core/models/macronutrients_model.dart';

class FoodModel {
  const FoodModel({
    required this.id,
    required this.name,
    required this.locale,
    required this.category,
    required this.nutritionPer100g,
    required this.isSupplement,
    required this.portions,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Alimento sem nome',
      locale: _asText(json['locale']),
      category: _asText(json['category']),
      nutritionPer100g: MacronutrientsModel.fromJson(
        json['nutritionPer100g'] as Map<String, dynamic>?,
      ),
      isSupplement: json['isSupplement'] as bool? ?? false,
      portions: _portionsFromJson(json['portions']),
    );
  }

  final String id;
  final String name;
  final String locale;
  final String category;
  final MacronutrientsModel nutritionPer100g;
  final bool isSupplement;
  final List<FoodPortionModel> portions;

  static String _asText(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  static List<FoodPortionModel> _portionsFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(FoodPortionModel.fromJson)
        .toList();
  }
}

class FoodPortionModel {
  const FoodPortionModel({
    required this.id,
    required this.name,
    required this.label,
    required this.grams,
    required this.macronutrients,
  });

  factory FoodPortionModel.fromJson(Map<String, dynamic> json) {
    return FoodPortionModel(
      id: FoodModel._asText(json['id']),
      name: FoodModel._asText(json['name']),
      label: FoodModel._asText(json['label']),
      grams: _decimal(json['grams']),
      macronutrients: MacronutrientsModel.fromJson(
        json['macronutrients'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String name;
  final String label;
  final double grams;
  final MacronutrientsModel macronutrients;

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

class FoodSearchResponse {
  const FoodSearchResponse({required this.foods});

  factory FoodSearchResponse.fromJson(Map<String, dynamic> json) {
    final items = json['foods'];

    if (items is! List) {
      return const FoodSearchResponse(foods: []);
    }

    return FoodSearchResponse(
      foods: items
          .whereType<Map<String, dynamic>>()
          .map(FoodModel.fromJson)
          .toList(),
    );
  }

  final List<FoodModel> foods;
}
