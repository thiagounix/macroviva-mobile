import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../application/foods_providers.dart';
import '../data/food_model.dart';
import 'widgets/food_portion_chips.dart';

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentos'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(foodsProvider(_searchQuery)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Busque na base nutricional',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Veja calorias, proteína, carboidratos e gorduras por 100g.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              labelText: 'Buscar alimento',
                              hintText: 'Ex.: arroz, frango, banana',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              setState(() => _searchQuery = value.trim());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _FoodBaseNote(
                    isSearching: _searchQuery.trim().isNotEmpty,
                    onClear: _searchQuery.trim().isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                  ),
                ),
                Expanded(
                  child: foods.when(
                    loading: () => const AppLoadingView(
                      message: 'Carregando alimentos...',
                    ),
                    error: (error, stackTrace) => AppErrorView(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(foodsProvider(_searchQuery)),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const _EmptyFoods();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(foodsProvider(_searchQuery));
                          await ref.read(foodsProvider(_searchQuery).future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemBuilder: (context, index) {
                            return _FoodTile(food: items[index]);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemCount: items.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food});

  final FoodModel food;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.rice_bowl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (food.category.isNotEmpty) Text(food.category),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroChip(
                  label:
                      '${food.nutritionPer100g.calories.toStringAsFixed(0)} kcal',
                ),
                _MacroChip(
                  label:
                      'P ${food.nutritionPer100g.proteinGrams.toStringAsFixed(1)}g',
                ),
                _MacroChip(
                  label:
                      'C ${food.nutritionPer100g.carbohydrateGrams.toStringAsFixed(1)}g',
                ),
                _MacroChip(
                  label:
                      'G ${food.nutritionPer100g.fatGrams.toStringAsFixed(1)}g',
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final badges = _badgesFor(food);
                if (badges.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges
                        .map((badge) => _FoodBadge(label: badge.label))
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Valores por 100g',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (food.portions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Porções rápidas',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              FoodPortionChips(portions: food.portions, enabled: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoodBaseNote extends StatelessWidget {
  const _FoodBaseNote({required this.isSearching, required this.onClear});

  final bool isSearching;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSearching
                  ? 'Filtro ativo. Registre, revise e ajuste com base nos alimentos encontrados.'
                  : 'Acompanhe tendências, não perfeição. Use a base para registrar refeições simples.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onClear, child: const Text('Limpar')),
          ],
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _FoodBadge extends StatelessWidget {
  const _FoodBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check_circle_outline, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.72),
    );
  }
}

class _FoodBadgeData {
  const _FoodBadgeData(this.label);

  final String label;
}

List<_FoodBadgeData> _badgesFor(FoodModel food) {
  final category = food.category.toLowerCase();
  final name = food.name.toLowerCase();
  final nutrition = food.nutritionPer100g;
  final badges = <_FoodBadgeData>[];

  if (food.isSupplement) {
    badges.add(const _FoodBadgeData('Suplemento'));
  }

  if (nutrition.proteinGrams >= 15) {
    badges.add(const _FoodBadgeData('Rico em proteína'));
  }

  if (nutrition.carbohydrateGrams >= 20) {
    badges.add(const _FoodBadgeData('Fonte de carboidrato'));
  }

  if (category.contains('fruta') ||
      category.contains('fruit') ||
      name.contains('banana') ||
      name.contains('maçã') ||
      name.contains('maca')) {
    badges.add(const _FoodBadgeData('Fruta'));
  }

  return badges.take(2).toList();
}

class _EmptyFoods extends StatelessWidget {
  const _EmptyFoods();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off),
                SizedBox(height: 12),
                Text('Nenhum alimento encontrado.'),
                SizedBox(height: 4),
                Text(
                  'Tente outro termo ou volte para registrar uma refeição com a base disponível.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
