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
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _DashboardHeader(),
                  const SizedBox(height: 16),
                  _QuickActions(
                    onFoods: () => context.go('/foods'),
                    onNewMeal: () => context.go('/meals/new'),
                    onPhoto: () => context.go('/meal-photo'),
                    onSupplements: () => context.go('/supplements'),
                  ),
                  const SizedBox(height: 20),
                  todayMeals.when(
                    loading: () => const SizedBox(
                      height: 220,
                      child: AppLoadingView(message: 'Carregando refeições...'),
                    ),
                    error: (error, stackTrace) => AppErrorView(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(todayMealsProvider),
                    ),
                    data: (meals) => _DashboardContent(meals: meals),
                  ),
                  const SizedBox(height: 20),
                  _ApiStatusCard(baseUrl: config.apiBaseUrl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoje',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe seus macros, registre refeições e revise sugestões antes de salvar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onFoods,
    required this.onNewMeal,
    required this.onPhoto,
    required this.onSupplements,
  });

  final VoidCallback onFoods;
  final VoidCallback onNewMeal;
  final VoidCallback onPhoto;
  final VoidCallback onSupplements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações rápidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 560;

            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.25 : 1.55,
              children: [
                _ActionCard(
                  icon: Icons.photo_camera_outlined,
                  label: 'Analisar foto',
                  onTap: onPhoto,
                ),
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Nova refeição',
                  onTap: onNewMeal,
                ),
                _ActionCard(
                  icon: Icons.restaurant_menu,
                  label: 'Alimentos',
                  onTap: onFoods,
                ),
                _ActionCard(
                  icon: Icons.fitness_center,
                  label: 'Suplementos',
                  onTap: onSupplements,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 20),
        Text(
          'Refeições de hoje',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
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
              label: const Text('Testar conexão'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;

        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.35 : 1.45,
          children: [
            _MetricTile(
              icon: Icons.local_fire_department_outlined,
              label: 'Calorias',
              value: '${total.calories.toStringAsFixed(0)} kcal',
            ),
            _MetricTile(
              icon: Icons.fitness_center,
              label: 'Proteína',
              value: '${total.proteinGrams.toStringAsFixed(1)} g',
            ),
            _MetricTile(
              icon: Icons.grain,
              label: 'Carboidratos',
              value: '${total.carbohydrateGrams.toStringAsFixed(1)} g',
            ),
            _MetricTile(
              icon: Icons.water_drop_outlined,
              label: 'Gorduras',
              value: '${total.fatGrams.toStringAsFixed(1)} g',
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: const Icon(Icons.restaurant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealType.isEmpty ? 'Refeição' : meal.mealType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${meal.items.length} itens • ${meal.totalMacronutrients.calories.toStringAsFixed(0)} kcal',
                  ),
                  if (meal.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meal.items
                          .take(2)
                          .map((item) => item.foodName)
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.restaurant_menu),
            SizedBox(height: 12),
            Text('Nenhuma refeição registrada hoje.'),
            SizedBox(height: 4),
            Text(
              'Comece adicionando uma refeição manual ou analisando uma foto.',
            ),
          ],
        ),
      ),
    );
  }
}
