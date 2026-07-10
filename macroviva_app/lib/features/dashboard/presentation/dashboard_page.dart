import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/http/api_client_provider.dart';
import '../../../core/models/macronutrients_model.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../meals/application/meals_providers.dart';
import '../../meals/data/meal_model.dart';
import 'dashboard_targets.dart';
import 'widgets/macro_progress_bar.dart';
import 'widgets/meal_period_card.dart';
import 'widgets/protein_progress_ring.dart';
import 'widgets/quick_action_card.dart';

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
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  todayMeals.when(
                    loading: () => const SizedBox(
                      height: 420,
                      child: AppLoadingView(message: 'Carregando refeições...'),
                    ),
                    error: (error, stackTrace) => AppErrorView(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(todayMealsProvider),
                    ),
                    data: (meals) => _DashboardContent(
                      meals: meals,
                      apiBaseUrl: config.apiBaseUrl,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.meals, required this.apiBaseUrl});

  final List<MealModel> meals;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final total = meals.fold<MacronutrientsModel>(
      MacronutrientsModel.zero,
      (current, meal) => current + meal.totalMacronutrients,
    );
    final proteinProgress =
        total.proteinGrams / DashboardTargets.proteinTargetGrams;
    final remainingProtein =
        DashboardTargets.proteinTargetGrams - total.proteinGrams;
    final periods = _groupMealsByPeriod(meals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPanel(
          total: total,
          meals: meals,
          proteinProgress: proteinProgress,
          remainingProtein: remainingProtein,
        ),
        const SizedBox(height: 16),
        _QuickActions(
          onPhoto: () => context.go('/meal-photo'),
          onNewMeal: () => context.go('/meals/new'),
          onSupplements: () => context.go('/supplements'),
        ),
        const SizedBox(height: 20),
        const _ProductStorySection(),
        const SizedBox(height: 20),
        _MacroSection(total: total),
        const SizedBox(height: 24),
        _MealFeed(periods: periods),
        const SizedBox(height: 20),
        _ApiStatusCard(baseUrl: apiBaseUrl),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.total,
    required this.meals,
    required this.proteinProgress,
    required this.remainingProtein,
  });

  final MacronutrientsModel total;
  final List<MealModel> meals;
  final double proteinProgress;
  final double remainingProtein;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progressText = meals.isEmpty
        ? 'Registre sua primeira refeição de hoje'
        : 'Hoje você já bateu ${(proteinProgress * 100).round()}% da sua proteína';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8FFF4), Color(0xFFFFF4DF), Color(0xFFF7F8F5)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;

            final intro = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, Thiago',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progressText,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _ProteinInsight(remainingProtein: remainingProtein),
                const SizedBox(height: 18),
                _AiNotice(),
              ],
            );

            final ring = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 260 : 240,
                minWidth: 210,
              ),
              child: ProteinProgressRing(
                consumed: total.proteinGrams,
                target: DashboardTargets.proteinTargetGrams,
              ),
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intro,
                  const SizedBox(height: 22),
                  Center(child: ring),
                  const SizedBox(height: 20),
                  _CaloriesCard(total: total),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: intro),
                const SizedBox(width: 24),
                ring,
                const SizedBox(width: 18),
                SizedBox(width: 180, child: _CaloriesCard(total: total)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProteinInsight extends StatelessWidget {
  const _ProteinInsight({required this.remainingProtein});

  final double remainingProtein;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = remainingProtein <= 0;
    final label = completed
        ? 'Meta de proteína concluída'
        : 'Faltam ${remainingProtein.ceil()}g de proteína';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF0F7B63).withValues(alpha: 0.12)
            : const Color(0xFFFFB84D).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.bolt,
            color: completed
                ? const Color(0xFF0F7B63)
                : const Color(0xFFB56B00),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: completed
                    ? const Color(0xFF0F7B63)
                    : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'A IA pode vir depois. O controle dos seus macros já começa agora.',
          ),
        ),
      ],
    );
  }
}

class _ProductStorySection extends StatelessWidget {
  const _ProductStorySection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final cards = const [
          _ProductStoryCard(
            icon: Icons.inventory_2_outlined,
            title: 'Base nutricional pronta para usar',
            body:
                'Adicione alimentos, ajuste gramas e veja proteína, calorias e macros sem depender de IA.',
            color: Color(0xFF0F7B63),
          ),
          _ProductStoryCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Proteína primeiro',
            body:
                'Acompanhe quanto falta para sua meta do dia e ajuste suas refeições com mais clareza.',
            color: Color(0xFF4D6BFF),
          ),
          _ProductStoryCard(
            icon: Icons.spa_outlined,
            title: 'Modo baixa fome',
            body:
                'Para fases de apetite reduzido, como pós-bariátrica ou acompanhamento médico para controle de peso, acompanhe proteína e macros com mais clareza.',
            footer:
                'Apoio informativo. Não substitui orientação médica ou nutricional.',
            color: Color(0xFFFF8A3D),
          ),
        ];

        if (!isWide) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ProductStoryCard extends StatelessWidget {
  const _ProductStoryCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? footer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.14),
              foregroundColor: color,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.total});

  final MacronutrientsModel total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total.calories / DashboardTargets.caloriesTarget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Calorias',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            total.calories.toStringAsFixed(0),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'de ${DashboardTargets.caloriesTarget.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              color: colorScheme.error,
              backgroundColor: colorScheme.error.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPhoto,
    required this.onNewMeal,
    required this.onSupplements,
  });

  final VoidCallback onPhoto;
  final VoidCallback onNewMeal;
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
            final isWide = constraints.maxWidth >= 700;

            return GridView.count(
              crossAxisCount: isWide ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.2 : 3.1,
              children: [
                QuickActionCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Foto da refeição',
                  subtitle: 'Análise rápida por imagem',
                  color: const Color(0xFF0F7B63),
                  primary: true,
                  onTap: onPhoto,
                ),
                QuickActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Adicionar manual',
                  subtitle: 'Controle fino quando precisar',
                  color: const Color(0xFF4D6BFF),
                  onTap: onNewMeal,
                ),
                QuickActionCard(
                  icon: Icons.fitness_center,
                  title: 'Suplemento',
                  subtitle: 'Check-in simples do dia',
                  color: const Color(0xFFFF8A3D),
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

class _MacroSection extends StatelessWidget {
  const _MacroSection({required this.total});

  final MacronutrientsModel total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Macros do dia', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final bars = [
              MacroProgressBar(
                label: 'Carboidratos',
                consumed: total.carbohydrateGrams,
                target: DashboardTargets.carbsTargetGrams,
                color: const Color(0xFF4D6BFF),
                icon: Icons.grain,
                helperText: 'Energia registrada no dia.',
              ),
              MacroProgressBar(
                label: 'Gorduras',
                consumed: total.fatGrams,
                target: DashboardTargets.fatsTargetGrams,
                color: const Color(0xFFFF8A3D),
                icon: Icons.water_drop_outlined,
                helperText: 'Completam o equilíbrio dos macros.',
              ),
            ];

            if (!isWide) {
              return Column(
                children: [bars.first, const SizedBox(height: 12), bars.last],
              );
            }

            return Row(
              children: [
                Expanded(child: bars.first),
                const SizedBox(width: 12),
                Expanded(child: bars.last),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MealFeed extends StatelessWidget {
  const _MealFeed({required this.periods});

  final List<_MealPeriod> periods;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu dia', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...periods.map(
          (period) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MealPeriodCard(
              title: period.title,
              icon: period.icon,
              meals: period.meals,
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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
    );
  }
}

List<_MealPeriod> _groupMealsByPeriod(List<MealModel> meals) {
  final breakfast = <MealModel>[];
  final lunch = <MealModel>[];
  final snack = <MealModel>[];
  final dinner = <MealModel>[];

  for (final meal in meals) {
    switch (_periodKeyFor(meal)) {
      case _PeriodKey.breakfast:
        breakfast.add(meal);
      case _PeriodKey.lunch:
        lunch.add(meal);
      case _PeriodKey.snack:
        snack.add(meal);
      case _PeriodKey.dinner:
        dinner.add(meal);
    }
  }

  return [
    _MealPeriod(
      title: 'Café da manhã',
      icon: Icons.wb_sunny_outlined,
      meals: breakfast,
    ),
    _MealPeriod(title: 'Almoço', icon: Icons.restaurant_menu, meals: lunch),
    _MealPeriod(
      title: 'Lanche',
      icon: Icons.bakery_dining_outlined,
      meals: snack,
    ),
    _MealPeriod(
      title: 'Jantar',
      icon: Icons.nightlight_outlined,
      meals: dinner,
    ),
  ];
}

_PeriodKey _periodKeyFor(MealModel meal) {
  final type = meal.mealType.toLowerCase();

  if (type.contains('breakfast') ||
      type.contains('café') ||
      type.contains('cafe')) {
    return _PeriodKey.breakfast;
  }

  if (type.contains('lunch') || type.contains('almoço')) {
    return _PeriodKey.lunch;
  }

  if (type.contains('snack') || type.contains('lanche')) {
    return _PeriodKey.snack;
  }

  if (type.contains('dinner') || type.contains('jantar')) {
    return _PeriodKey.dinner;
  }

  final hour = meal.occurredAt?.hour;
  if (hour == null) {
    return _PeriodKey.lunch;
  }

  if (hour < 11) {
    return _PeriodKey.breakfast;
  }

  if (hour < 15) {
    return _PeriodKey.lunch;
  }

  if (hour < 18) {
    return _PeriodKey.snack;
  }

  return _PeriodKey.dinner;
}

enum _PeriodKey { breakfast, lunch, snack, dinner }

class _MealPeriod {
  const _MealPeriod({
    required this.title,
    required this.icon,
    required this.meals,
  });

  final String title;
  final IconData icon;
  final List<MealModel> meals;
}
