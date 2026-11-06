/// Kumpulan komponen UI bersama (reusable widgets) yang dipakai di seluruh fitur,
/// seperti AppBar melengkung (`pageAppBar`), `AppCard`, `HeroCard`, `PeriodSwitcher`, dan `UserAvatar`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/prefs.dart';
import '../data/profile.dart';
import '../data/providers.dart';
import 'botanical_decorations.dart';
import 'format.dart';
import 'l10n.dart';
import 'period.dart';
import 'theme.dart';

/// AppBar dengan header hijau tua dan lembar berujung melengkung di bawahnya.
PreferredSizeWidget pageAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  Widget? bottom,
  double bottomHeight = 0,
}) {
  final colors = context.themeColors;
  final isCyber = colors.isCyberpunk;
  return AppBar(
    title: title,
    actions: actions,
    centerTitle: false,
    backgroundColor: colors.heroBackground,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
    flexibleSpace: isCyber
        ? null
        : const IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                isComplex: true,
                painter: BotanicalCanopyPainter(opacity: 0.10),
              ),
            ),
          ),
    bottom: _SheetEdge(childHeight: bottomHeight, child: bottom),
  );
}

/// Lengkungan atas lembar background di bawah header hijau.
class _SheetEdge extends StatelessWidget implements PreferredSizeWidget {
  const _SheetEdge({this.child, this.childHeight = 0});

  final Widget? child;
  final double childHeight;

  static const double edge = 24;

  @override
  Size get preferredSize => Size.fromHeight(childHeight + edge);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (child != null) SizedBox(height: childHeight, child: child),
        Container(
          height: edge,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      ],
    );
  }
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

/// Kartu kontainer standar dengan sudut membulat dan garis tepi halus sesuai tema.
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
    final isCyber = context.isCyberpunk;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCyber
              ? const Color(0xFF00F0FF).withValues(alpha: 0.28)
              : scheme.outlineVariant,
          width: 1.0,
        ),
        boxShadow: isCyber
            ? [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.10),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Kartu sorotan (HeroCard) untuk saldo, total anggaran, dan sorotan utama.
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
    final colors = context.themeColors;
    final isCyber = colors.isCyberpunk;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.heroBackground,
        gradient: isCyber
            ? const LinearGradient(
                colors: [Color(0xFF13172E), Color(0xFF101326), Color(0xFF1A102B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: isCyber
            ? Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.50),
                width: 1.4,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isCyber
                ? const Color(0xFF00F0FF).withValues(alpha: 0.30)
                : AppColors.deepForest.withValues(alpha: 0.25),
            blurRadius: isCyber ? 22 : 18,
            spreadRadius: isCyber ? -1 : 0,
            offset: const Offset(0, 6),
          ),
          if (isCyber)
            BoxShadow(
              color: const Color(0xFFFF2A6D).withValues(alpha: 0.16),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: ValueKey('heroCard_$isCyber'),
                  isComplex: true,
                  painter: isCyber
                      ? const CyberHeroCardPainter()
                      : const BotanicalHeroCardPainter(),
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lencana ikon persegi membulat dengan latar belakang berwarna transparan untuk kategori.
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
    final isCyber = context.isCyberpunk;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCyber ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: isCyber
            ? Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.2,
              )
            : null,
        boxShadow: isCyber
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Indikator bilah progres horizontal dengan ujung membulat (0.0 sampai 1.0).
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

/// Chip pilihan bergaya kapsul (stadium) untuk filter kategori, dompet, atau tipe transaksi.
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

/// Judul bagian (section) dengan opsi tombol aksi di sisi kanan.
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
  const PeriodSwitcher({super.key, this.compact = false, this.onDark = false});

  final bool compact;

  /// Teks dan ikon putih, untuk dipakai di atas header hijau.
  final bool onDark;

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
          color: onDark ? Colors.white : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: Text(
            period.label(),
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : null,
            ),
          ),
        ),
        IconButton(
          tooltip: context.tr('Next period'),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () => notifier.step(1),
          color: onDark ? Colors.white : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Pilihan Monthly / Weekly.
class PeriodTypeToggle extends ConsumerWidget {
  const PeriodTypeToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
    if (compact) {
      final isMonthly = type == PeriodType.monthly;
      final theme = Theme.of(context);
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final next = isMonthly ? PeriodType.weekly : PeriodType.monthly;
          ref.read(appPrefsProvider.notifier).setPeriodType(next);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.isCyberpunk
                  ? const Color(0xFF00F0FF).withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant,
            ),
            boxShadow: context.isCyberpunk
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMonthly ? Icons.calendar_month_outlined : Icons.view_week_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                context.tr(isMonthly ? 'Monthly' : 'Weekly'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
    final photoImage = ref.watch(profileProvider.select((s) => s.photoImage));
    final name = ref.watch(displayNameProvider) ?? '?';
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: photoImage,
      child: photoImage == null
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

/// Tampilan informasi sederhana (ikon + pesan teks) saat daftar masih kosong.
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

/// Kartu hijau tua untuk keadaan kosong, dengan ajakan positif.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.eco_outlined,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final isCyber = colors.isCyberpunk;
    final displayIcon = isCyber && icon == Icons.eco_outlined ? Icons.electric_bolt_rounded : icon;

    return HeroCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: isCyber
                  ? Border.all(
                      color: colors.primary.withValues(alpha: 0.60),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isCyber
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Icon(displayIcon, size: 38, color: colors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}


/// GlobalKey untuk root ScaffoldMessenger agar SnackBar dapat dipanggil secara konsisten
/// dari mana saja, termasuk setelah modal/bottom sheet ditutup.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Tampilkan SnackBar floating dengan tombol aksi "Urungkan (Undo)".
void showUndoSnackBar({
  BuildContext? context,
  required String message,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = rootScaffoldMessengerKey.currentState ??
      (context != null && context.mounted ? ScaffoldMessenger.maybeOf(context) : null);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        label: trG('Undo'),
        textColor: context != null ? Theme.of(context).colorScheme.primary : AppColors.sage,
        onPressed: () async {
          await onUndo();
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(trG('Item restored')),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    ),
  );
}

/// Container dengan latar belakang ambient (daun lembut untuk Botanical, grid & glow orbs untuk Cyberpunk)
/// untuk lembar konten di bawah header.
class BotanicalBackgroundSheet extends StatelessWidget {
  const BotanicalBackgroundSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCyber = context.isCyberpunk;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!isCyber)
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: BotanicalBackgroundPainter(),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

