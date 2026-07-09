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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool primary;

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
        child: Padding(
          padding: EdgeInsets.all(primary ? 14 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary ? Colors.white : color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.78)
                      : colorScheme.onSurfaceVariant,
                ),
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
