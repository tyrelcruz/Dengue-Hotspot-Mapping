import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
        ),
        hintText: 'Search for latest reports...',
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none),
      ),
    );
  }
}
