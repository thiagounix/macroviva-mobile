import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.primary = false,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool primary;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = primary ? Colors.white : colorScheme.onSurface;

    return Material(
      color: primary ? color : color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: primary
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 180;
            final iconBadge = Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary ? Colors.white : color),
            );
            final copy = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.18)
                          : color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: textTheme.labelSmall?.copyWith(
                        color: primary ? Colors.white : color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.78)
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: badge != null ? 3 : (compact ? 1 : 2),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );

            return Padding(
              padding: EdgeInsets.all(primary ? 14 : 12),
              child: compact
                  ? Row(
                      children: [
                        iconBadge,
                        const SizedBox(width: 12),
                        Expanded(child: copy),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [iconBadge, const SizedBox(height: 12), copy],
                    ),
            );
          },
        ),
      ),
    );
  }
}
