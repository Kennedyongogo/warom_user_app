import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EdamsNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const EdamsNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shared bottom navigation for guest and signed-in shells.
class EdamsBottomNav extends StatelessWidget {
  static const Color green = Color(0xFF2E7D32);
  static const Color greenSoft = Color(0xFFE8F5E9);
  static const Color inkMuted = Color(0xFF6B7280);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<EdamsNavItem> items;

  const EdamsBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final index = currentIndex.clamp(0, items.length - 1);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset > 0 ? bottomInset : 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == index;
              return Expanded(
                child: _NavTile(
                  item: item,
                  selected: selected,
                  compact: items.length >= 5,
                  onTap: () {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final EdamsNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? EdamsBottomNav.green : EdamsBottomNav.inkMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: EdamsBottomNav.green.withValues(alpha: 0.08),
      highlightColor: EdamsBottomNav.green.withValues(alpha: 0.04),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 6 : 8,
          horizontal: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? (compact ? 12 : 14) : 10,
                vertical: selected ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: selected ? EdamsBottomNav.greenSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: compact ? 22 : 24,
                color: color,
              ),
            ),
            SizedBox(height: compact ? 3 : 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: selected ? 0.1 : 0,
                height: 1.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
