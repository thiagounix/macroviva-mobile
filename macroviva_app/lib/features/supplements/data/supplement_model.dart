import '../../../core/models/macronutrients_model.dart';

class SupplementModel {
  const SupplementModel({
    required this.id,
    required this.name,
    required this.locale,
    required this.type,
    required this.macronutrientsPerServing,
    required this.impactsMacronutrients,
  });

  factory SupplementModel.fromJson(Map<String, dynamic> json) {
    return SupplementModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Suplemento sem nome',
      locale: json['locale']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      macronutrientsPerServing: MacronutrientsModel.fromJson(
        json['macronutrientsPerServing'] as Map<String, dynamic>?,
      ),
      impactsMacronutrients: json['impactsMacronutrients'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String locale;
  final String type;
  final MacronutrientsModel macronutrientsPerServing;
  final bool impactsMacronutrients;
}
