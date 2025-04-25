import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isRequired;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final List<String>? choices; // Optional list of choices for dropdown
  final bool isDate;
  final bool isTime;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isRequired = false,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.choices,
    this.isDate = false,
    this.isTime = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && widget.controller != null) {
      setState(() {
        widget.controller!.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && widget.controller != null) {
      setState(() {
        widget.controller!.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build the label with an optional red asterisk
    Widget? buildLabel() {
      if (widget.isRequired) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.hintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Inter-Regular',
                  color: colorScheme.primary,
                ),
              ),
              TextSpan(
                text: ' *',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      } else {
        return Text(
          widget.hintText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
          ),
        );
      }
    }

    if (widget.choices != null) {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          DropdownButtonFormField<String>(
            isDense: true,
            menuMaxHeight:
                200, // Enables scrolling when items exceed the height
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Inter-Regular',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
            icon: const SizedBox.shrink(),
            value: widget.controller?.text.isNotEmpty == true
                ? widget.controller!.text
                : null,
            items: widget.choices!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (widget.controller != null) {
                widget.controller!.text = value ?? '';
              }
              if (widget.onChanged != null) {
                widget.onChanged!(value ?? '');
              }
            },
            decoration: InputDecoration(
              labelText: widget.hintText,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Inter-Regular',
                color: colorScheme.primary.withOpacity(0.5),
              ),
              fillColor: colorScheme.surface,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              constraints: const BoxConstraints(maxHeight: 35),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (widget.suffixIcon != null)
            Positioned(
              right: 10,
              child: IconTheme(
                data: IconThemeData(
                  color: colorScheme.primary,
                  size: 18,
                ),
                child: widget.suffixIcon!,
              ),
            ),
        ],
      );
    }

    return TextField(
      controller: widget.controller,
      onTap: widget.isDate
          ? () => _selectDate(context)
          : widget.isTime
              ? () => _selectTime(context)
              : null,
      readOnly: widget.isDate || widget.isTime,
      onChanged: widget.onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'Inter-Regular',
        color: colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: widget.hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Inter-Regular',
          color: colorScheme.primary.withOpacity(0.5),
        ),
        fillColor: colorScheme.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        constraints: const BoxConstraints(maxHeight: 35),
        suffixIcon: widget.suffixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: colorScheme.primary,
                  size: 18,
                ),
                child: widget.suffixIcon!,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
