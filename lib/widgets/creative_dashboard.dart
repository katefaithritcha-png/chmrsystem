import 'package:flutter/material.dart';

class CreativeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final List<Widget>? trailing;
  const CreativeHeader({super.key, required this.title, required this.subtitle, this.leadingIcon = Icons.health_and_safety, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(leadingIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            ...trailing!,
          ],
        ],
      ),
    );
  }
}

class CreativeKpiCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const CreativeKpiCard({super.key, required this.icon, required this.label, required this.value, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (iconColor ?? cs.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black45),
        ],
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: card);
  }
}

class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const ActionPill({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.onSecondaryContainer, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: cs.onSecondaryContainer)),
        ],
      ),
    );
    return onTap == null ? child : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: child);
  }
}
