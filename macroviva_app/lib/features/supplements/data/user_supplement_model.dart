import '../../../core/models/macronutrients_model.dart';

class UserSupplementModel {
  const UserSupplementModel({
    required this.id,
    required this.userId,
    required this.supplementId,
    required this.checkInDate,
    required this.servings,
    required this.macronutrientImpact,
  });

  factory UserSupplementModel.fromJson(Map<String, dynamic> json) {
    return UserSupplementModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      supplementId: json['supplementId'] as String? ?? '',
      checkInDate: json['checkInDate'] as String? ?? '',
      servings: _decimal(json['servings']),
      macronutrientImpact: MacronutrientsModel.fromJson(
        json['macronutrientImpact'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String userId;
  final String supplementId;
  final String checkInDate;
  final double servings;
  final MacronutrientsModel macronutrientImpact;

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
