import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// White rounded card with the app border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.leftAccent,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  /// Thick coloured edge on the left (used for the Advising card).
  final Color? leftAccent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    Widget content = Padding(padding: padding, child: child);
    if (leftAccent != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: leftAccent),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Material(
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// Label on the left, value on the right.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                color: valueColor ?? AppColors.text,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small number + caption tile used in summaries.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          if (icon != null) const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Coloured info/warning strip.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.color = AppColors.info,
    this.icon = Icons.info_outline,
    this.title,
    this.action,
  });

  final String message;
  final Color color;
  final IconData icon;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(title!,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  ),
                Text(message, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 44, this.light = false});

  final String initials;
  final double size;

  /// White circle with maroon text (for dark backgrounds).
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: light ? Colors.white : AppColors.tint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Horizontal row of selectable chips (semester / section pickers).
class ChoiceChipsRow<T> extends StatelessWidget {
  const ChoiceChipsRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.trailingOf,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final Widget? Function(T)? trailingOf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = values[i];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labelOf(value)),
                if (trailingOf?.call(value) != null) ...[
                  const SizedBox(width: 4),
                  trailingOf!(value)!,
                ],
              ],
            ),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.text,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}

/// Search field with the app styling.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.controller});

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}
