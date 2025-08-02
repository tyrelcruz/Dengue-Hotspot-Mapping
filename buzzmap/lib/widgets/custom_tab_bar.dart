import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomTabBar({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 2.0 : 1.0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Chip(
            visualDensity: VisualDensity(
                horizontal: isTablet ? 2 : 0, vertical: isTablet ? -2 : -4),
            padding: EdgeInsets.symmetric(
                vertical: isTablet ? 6 : 2, horizontal: isTablet ? 12 : 8),
            backgroundColor: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            label: Center(
              child: Text(
                widget.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 14 : 11,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              side: BorderSide(color: theme.colorScheme.surface),
            ),
          ),
        ),
      ),
    );
  }
}
