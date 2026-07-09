import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macroviva_app/app/macroviva_app.dart';
import 'package:macroviva_app/features/meals/application/meals_providers.dart';
import 'package:macroviva_app/features/meals/data/meal_model.dart';

void main() {
  testWidgets('renders dashboard as initial page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayMealsProvider.overrideWith((ref) async => const <MealModel>[]),
        ],
        child: const MacroVivaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MacroViva'), findsOneWidget);
    expect(find.text('API local'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Calorias'), findsOneWidget);
  });
}
