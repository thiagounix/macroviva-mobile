import 'package:flutter/material.dart';

class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.icon,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${consumed.toStringAsFixed(0)}g',
                style: textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meta ${target.toStringAsFixed(0)}g',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
