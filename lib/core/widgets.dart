import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/prefs.dart';
import '../data/profile.dart';
import '../data/providers.dart';
import 'format.dart';
import 'l10n.dart';
import 'period.dart';
import 'theme.dart';

/// AppBar transparan dengan judul rata kiri, sesuai desain.
PreferredSizeWidget pageAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: title,
    actions: actions,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}

/// Gaya field input yang seragam.
InputDecoration appInput(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? prefixIcon,
  String? prefixText,
  String? helper,
  Widget? suffixIcon,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    helperText: helper,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: scheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
}

/// Nama kategori yang ikut diterjemahkan (untuk kategori bawaan).
String categoryName(BuildContext context, Category? c) =>
    context.tr(c?.name ?? 'Uncategorized');

/// Warna progres anggaran: hijau, kuning mendekati batas, merah jika lewat.
Color budgetColor(double ratio, ColorScheme scheme) {
  if (ratio > 1) return AppColors.expense;
  if (ratio >= 0.8) return AppColors.warning;
  return scheme.primary;
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Kartu hijau tua untuk saldo, total anggaran, dan sorotan lain.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.deepForest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
  });

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        color: color ?? scheme.primary,
        backgroundColor: backgroundColor ?? scheme.outlineVariant,
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: fg),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: scheme.primary,
      backgroundColor: scheme.surface,
      side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Pemilih periode "‹ April 2025 ›" (bulan) atau "‹ 21 Apr – 27 Apr 2025 ›" (minggu).
class PeriodSwitcher extends ConsumerWidget {
  const PeriodSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final notifier = ref.read(selectedAnchorProvider.notifier);
    final style = compact
        ? Theme.of(context).textTheme.labelLarge
        : Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.tr('Previous period'),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () => notifier.step(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: Text(
            period.label(),
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: context.tr('Next period'),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () => notifier.step(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Pilihan Monthly / Weekly.
class PeriodTypeToggle extends ConsumerWidget {
  const PeriodTypeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
    return SegmentedButton<PeriodType>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: PeriodType.monthly,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(context.tr('Monthly')),
        ),
        ButtonSegment(
          value: PeriodType.weekly,
          icon: const Icon(Icons.view_week_outlined, size: 18),
          label: Text(context.tr('Weekly')),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) =>
          ref.read(appPrefsProvider.notifier).setPeriodType(s.first),
    );
  }
}

/// Foto profil bulat; jika belum ada, tampil inisial nickname.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 48, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final photo = ref.watch(profileProvider.select((s) => s.photo));
    final name = ref.watch(displayNameProvider) ?? '?';
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null
          ? Text(
              (name.isEmpty ? '?' : String.fromCharCode(name.runes.first)).toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            )
          : null,
    );
    return onTap == null
        ? avatar
        : InkWell(customBorder: const CircleBorder(), onTap: onTap, child: avatar);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Dialog input nominal. Mengembalikan null jika dibatalkan.
Future<int?> showAmountDialog(
  BuildContext context, {
  required String title,
  int? initial,
  String? helper,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _AmountDialog(title: title, initial: initial, helper: helper),
  );
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, this.initial, this.helper});

  final String title;
  final int? initial;
  final String? helper;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: formatThousands(widget.initial ?? 0));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: amountFormatters(),
        decoration: appInput(context, prefixText: 'Rp ', helper: widget.helper),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, parseAmount(_controller.text)),
          child: Text(context.tr('Save')),
        ),
      ],
    );
  }
}
