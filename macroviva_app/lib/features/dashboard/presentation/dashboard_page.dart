import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/http/api_client_provider.dart';
import '../../../core/models/macronutrients_model.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../meals/application/meals_providers.dart';
import '../../meals/data/meal_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final todayMeals = ref.watch(todayMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MacroViva'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(todayMealsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayMealsProvider);
            await ref.read(todayMealsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ApiStatusCard(baseUrl: config.apiBaseUrl),
              const SizedBox(height: 16),
              Text('Hoje', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              todayMeals.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: AppLoadingView(message: 'Carregando refeicoes...'),
                ),
                error: (error, stackTrace) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(todayMealsProvider),
                ),
                data: (meals) => _DashboardContent(meals: meals),
              ),
              const SizedBox(height: 16),
              _NavigationButton(
                icon: Icons.restaurant_menu,
                label: 'Alimentos',
                onPressed: () => context.go('/foods'),
              ),
              const SizedBox(height: 12),
              _NavigationButton(
                icon: Icons.add_circle_outline,
                label: 'Nova refeicao',
                onPressed: () => context.go('/meals/new'),
              ),
              const SizedBox(height: 12),
              _NavigationButton(
                icon: Icons.fitness_center,
                label: 'Suplementos',
                onPressed: () => context.go('/supplements'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.meals});

  final List<MealModel> meals;

  @override
  Widget build(BuildContext context) {
    final total = meals.fold<MacronutrientsModel>(
      MacronutrientsModel.zero,
      (current, meal) => current + meal.totalMacronutrients,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MacroSummary(total: total),
        const SizedBox(height: 16),
        if (meals.isEmpty)
          const _EmptyMeals()
        else
          ...meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MealTile(meal: meal),
            ),
          ),
      ],
    );
  }
}

class _ApiStatusCard extends ConsumerWidget {
  const _ApiStatusCard({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API local', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(baseUrl),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(apiClientProvider).get<void>('/health');
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Backend respondeu /health')),
                  );
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Falha ao chamar API: $error')),
                  );
                }
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Testar conexao'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.total});

  final MacronutrientsModel total;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _MetricTile(
          label: 'Calorias',
          value: '${total.calories.toStringAsFixed(0)} kcal',
        ),
        _MetricTile(
          label: 'Proteina',
          value: '${total.proteinGrams.toStringAsFixed(1)} g',
        ),
        _MetricTile(
          label: 'Carboidratos',
          value: '${total.carbohydrateGrams.toStringAsFixed(1)} g',
        ),
        _MetricTile(
          label: 'Gorduras',
          value: '${total.fatGrams.toStringAsFixed(1)} g',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final MealModel meal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant),
        title: Text(meal.mealType.isEmpty ? 'Refeicao' : meal.mealType),
        subtitle: Text(
          '${meal.items.length} itens - ${meal.totalMacronutrients.calories.toStringAsFixed(0)} kcal',
        ),
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nenhuma refeicao registrada hoje.'),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
