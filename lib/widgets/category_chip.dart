import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ============================================================
// Ngam App — Category Chip Widget
// Reusable colored chip for task categories
// ============================================================

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
  });

  /// Get category-specific color
  Color _getCategoryColor() {
    switch (label) {
      case 'Food':
        return const Color(0xFFFF6B35);
      case 'Shopping':
        return const Color(0xFF4ECDC4);
      case 'Print':
        return const Color(0xFF45B7D1);
      case 'Heavy':
        return const Color(0xFFFF8C94);
      case 'Parcel':
        return const Color(0xFFA78BFA);
      case 'All':
        return AppTheme.primary;
      default:
        return Colors.grey;
    }
  }

  /// Get category icon
  String _getCategoryIcon() {
    switch (label) {
      case 'Food':
        return '🍔';
      case 'Shopping':
        return '🛒';
      case 'Print':
        return '🖨️';
      case 'Heavy':
        return '📦';
      case 'Parcel':
        return '📮';
      case 'All':
        return '✨';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).chipTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Text(_getCategoryIcon(), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? color
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
