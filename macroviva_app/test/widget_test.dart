import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macroviva_app/app/macroviva_app.dart';
import 'package:macroviva_app/core/config/app_config.dart';
import 'package:macroviva_app/core/http/api_client_provider.dart';
import 'package:macroviva_app/features/meals/application/meals_providers.dart';
import 'package:macroviva_app/features/meals/data/meal_model.dart';

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    bool showDebugTools = false,
    bool enableMockPhotoAnalysis = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayMealsProvider.overrideWith((ref) async => const <MealModel>[]),
          appConfigProvider.overrideWithValue(
            AppConfig(
              apiBaseUrl: 'http://localhost:5169',
              showDebugToolsEnabled: showDebugTools,
              mockPhotoAnalysisEnabled: enableMockPhotoAnalysis,
            ),
          ),
        ],
        child: const MacroVivaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the beta dashboard without development tools', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('MacroViva'), findsOneWidget);
    expect(find.text('Olá!'), findsOneWidget);
    expect(find.textContaining('Thiago'), findsNothing);
    expect(find.text('Calorias'), findsOneWidget);
    expect(find.text('Ações rápidas'), findsOneWidget);
    expect(find.text('Foto da refeição'), findsNothing);
    expect(find.text('API local'), findsNothing);
    expect(find.text('Testar conexão'), findsNothing);
    expect(find.text('Macros do dia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the mock photo action only when enabled', (tester) async {
    await pumpDashboard(tester, enableMockPhotoAnalysis: true);

    expect(find.text('Foto da refeição'), findsOneWidget);
    expect(find.text('Simulação'), findsOneWidget);
    expect(
      find.text('Fluxo de demonstração — IA real ainda não está ativa'),
      findsOneWidget,
    );
    expect(find.text('API local'), findsNothing);
  });

  testWidgets('shows development tools only when enabled', (tester) async {
    await pumpDashboard(tester, showDebugTools: true);

    expect(find.text('API local'), findsOneWidget);
    expect(find.text('http://localhost:5169'), findsOneWidget);
    expect(find.text('Testar conexão'), findsOneWidget);
  });

  testWidgets('renders the beta dashboard at target viewport widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in <double>[390, 768, 1280, 1440]) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;

      await pumpDashboard(tester, enableMockPhotoAnalysis: true);

      expect(tester.takeException(), isNull, reason: 'viewport width: $width');
    }
  });
}
