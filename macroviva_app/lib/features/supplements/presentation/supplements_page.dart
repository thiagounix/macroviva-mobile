import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../application/supplements_providers.dart';
import '../data/supplement_model.dart';

class SupplementsPage extends ConsumerWidget {
  const SupplementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplements = ref.watch(supplementsProvider);
    final checkInState = ref.watch(supplementCheckInControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suplementos'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(supplementsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: supplements.when(
          loading: () =>
              const AppLoadingView(message: 'Carregando suplementos...'),
          error: (error, stackTrace) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(supplementsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySupplements();
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supplementsProvider);
                await ref.read(supplementsProvider.future);
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _ProfessionalGuidanceCard();
                      }

                      final supplement = items[index - 1];
                      return _SupplementTile(
                        supplement: supplement,
                        isCheckingIn: checkInState.isLoading,
                        onCheckIn: () => _checkIn(context, ref, supplement),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: items.length + 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
    SupplementModel supplement,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(supplementCheckInControllerProvider.notifier)
          .checkIn(supplement.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Check-in registrado: ${supplement.name}')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha no check-in: $error')),
      );
    }
  }
}

class _ProfessionalGuidanceCard extends StatelessWidget {
  const _ProfessionalGuidanceCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orientação profissional',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use suplementos apenas com liberação de médico, nutricionista ou farmacêutico. O app registra check-ins e macros, mas não prescreve uso, dose ou horário.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplementTile extends StatelessWidget {
  const _SupplementTile({
    required this.supplement,
    required this.isCheckingIn,
    required this.onCheckIn,
  });

  final SupplementModel supplement;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final macros = supplement.macronutrientsPerServing;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: supplement.hasStimulantWarning
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  foregroundColor: supplement.hasStimulantWarning
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  child: Icon(
                    supplement.hasStimulantWarning
                        ? Icons.warning_amber_rounded
                        : Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplement.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${supplement.type} • ${macros.calories.toStringAsFixed(0)} kcal por porção',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Impacta macros: ${supplement.impactsMacronutrients ? 'sim' : 'não'}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Check-in',
                  onPressed: isCheckingIn ? null : onCheckIn,
                  icon: isCheckingIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                ),
              ],
            ),
            if (supplement.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(supplement.description, style: textTheme.bodyMedium),
            ],
            if (supplement.hasStimulantWarning) ...[
              const SizedBox(height: 12),
              _SafetyCallout(
                icon: Icons.warning_amber_rounded,
                text: 'Use somente se liberado por profissional de saúde.',
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
            ],
            if (supplement.requiresProfessionalGuidance ||
                supplement.safetyNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SafetyCallout(
                icon: Icons.medical_information_outlined,
                text: supplement.safetyNote.isNotEmpty
                    ? supplement.safetyNote
                    : 'Suplemento não substitui alimentação equilibrada nem orientação médica/nutricional.',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafetyCallout extends StatelessWidget {
  const _SafetyCallout({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: foregroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySupplements extends StatelessWidget {
  const _EmptySupplements();

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
                Icon(Icons.fitness_center),
                SizedBox(height: 12),
                Text('Nenhum suplemento encontrado.'),
                SizedBox(height: 4),
                Text(
                  'Verifique se o backend local está rodando com seed aplicado.',
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
