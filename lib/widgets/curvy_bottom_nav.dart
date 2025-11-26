import 'package:flutter/material.dart';

class CurvyNavItem {
  final IconData icon;
  final String label;
  const CurvyNavItem({required this.icon, required this.label});
}

class CurvyBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<CurvyNavItem> items;
  final ValueChanged<int> onSelected;
  const CurvyBottomNav({super.key, required this.currentIndex, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surface;
    final bar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: _NavPills(currentIndex: currentIndex, items: items, onSelected: onSelected),
    );
    return SafeArea(top: false, child: bar);
  }
}

class _NavPills extends StatelessWidget {
  final int currentIndex;
  final List<CurvyNavItem> items;
  final ValueChanged<int> onSelected;
  const _NavPills({required this.currentIndex, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Flexible(
              flex: i == currentIndex ? 2 : 1,
              child: _Pill(
                selected: i == currentIndex,
                item: items[i],
                onTap: () => onSelected(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final bool selected;
  final CurvyNavItem item;
  final VoidCallback onTap;
  const _Pill({required this.selected, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = selected ? cs.primary : Colors.transparent;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 48,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(999),
        border: selected ? Border.all(color: Colors.white, width: 1.4) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: selected ? fg : cs.primary, size: 22),
              const SizedBox(width: 8),
              if (selected)
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
