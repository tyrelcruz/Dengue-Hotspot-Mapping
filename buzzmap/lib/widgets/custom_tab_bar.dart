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

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Chip(
            visualDensity: VisualDensity(horizontal: 0, vertical: -4),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
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
                  fontSize: 11,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.surface),
            ),
          ),
        ),
      ),
    );
  }
}
