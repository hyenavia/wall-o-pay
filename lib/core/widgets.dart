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
    flexibleSpace: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          isComplex: true,
          painter: isCyber
              ? const CyberCanopyPainter()
              : const BotanicalCanopyPainter(opacity: 0.10),
        ),
      ),
    ),
    bottom: _SheetEdge(childHeight: bottomHeight, child: bottom),
  );
}

/// Lengkungan atas lembar background di bawah header hijau / garis cyber divider.
class _SheetEdge extends StatelessWidget implements PreferredSizeWidget {
  const _SheetEdge({this.child, this.childHeight = 0});

  final Widget? child;
  final double childHeight;

  static const double edge = 24;

  @override
  Size get preferredSize => Size.fromHeight(childHeight + edge);

  @override
  Widget build(BuildContext context) {
    final isCyber = context.isCyberpunk;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (child != null) SizedBox(height: childHeight, child: child),
        Container(
          height: edge,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: isCyber
                ? null
                : const BorderRadius.vertical(top: Radius.circular(28)),
            border: isCyber
                ? Border(
                    top: BorderSide(
                      color: context.themeColors.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  )
                : null,
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
  final isCyber = context.isCyberpunk;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(isCyber ? 6 : 14),
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

/// Warna progres anggaran: hijau/primary, kuning mendekati batas, merah jika lewat.
Color budgetColor(double ratio, ColorScheme scheme, [AppThemeColors? colors]) {
  if (ratio > 1) return colors?.expense ?? AppColors.expense;
  if (ratio >= 0.8) return colors?.warning ?? AppColors.warning;
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
    final colors = context.themeColors;
    final isCyber = colors.isCyberpunk;

    final shape = isCyber
        ? BeveledRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(6),
            ),
            side: BorderSide(
              color: colors.primary.withValues(alpha: 0.32),
              width: 1.0,
            ),
          )
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant,
              width: 1.0,
            ),
          );

    return Container(
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: shape,
        shadows: isCyber
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.12),
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
        shape: shape,
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

    final shape = isCyber
        ? BeveledRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(8),
            ),
            side: BorderSide(
              color: colors.primary.withValues(alpha: 0.55),
              width: 1.4,
            ),
          )
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: isCyber ? null : colors.heroBackground,
        gradient: isCyber
            ? const LinearGradient(
                colors: [Color(0xFF13172E), Color(0xFF101326), Color(0xFF1A102B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        shape: shape,
        shadows: [
          BoxShadow(
            color: isCyber
                ? colors.primary.withValues(alpha: 0.30)
                : AppColors.deepForest.withValues(alpha: 0.25),
            blurRadius: isCyber ? 22 : 18,
            spreadRadius: isCyber ? -1 : 0,
            offset: const Offset(0, 6),
          ),
          if (isCyber)
            BoxShadow(
              color: colors.expense.withValues(alpha: 0.16),
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

/// Lencana ikon kategori persegi membulat (Botanical) atau bersegi chamfer/tech-cut (Cyberpunk).
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
    final shape = isCyber
        ? BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.22),
            side: BorderSide(
              color: color.withValues(alpha: 0.50),
              width: 1.2,
            ),
          )
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.3),
          );

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: isCyber ? 0.22 : 0.16),
        shape: shape,
        shadows: isCyber
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

/// Indikator bilah progres horizontal dengan ujung membulat (Botanical) atau meter HUD datar (Cyberpunk).
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
    final isCyber = context.isCyberpunk;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCyber ? 2 : height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        color: color ?? scheme.primary,
        backgroundColor: backgroundColor ?? scheme.outlineVariant,
      ),
    );
  }
}

/// Chip pilihan bergaya kapsul stadium (Botanical) atau modul chamfered (Cyberpunk).
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
    final isCyber = context.isCyberpunk;
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
      shape: isCyber
          ? const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            )
          : const StadiumBorder(),
      labelStyle: TextStyle(
        color: fg,
        fontWeight: FontWeight.w700,
        letterSpacing: isCyber ? 0.4 : 0.0,
      ),
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
      final colors = context.themeColors;
      final isCyber = colors.isCyberpunk;
      final shape = isCyber
          ? BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: colors.primary.withValues(alpha: 0.35),
                width: 1.0,
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1.0,
              ),
            );

      return InkWell(
        customBorder: shape,
        onTap: () {
          final next = isMonthly ? PeriodType.weekly : PeriodType.monthly;
          ref.read(appPrefsProvider.notifier).setPeriodType(next);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: theme.colorScheme.surface,
            shape: shape,
            shadows: isCyber
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.12),
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

/// Foto profil: lingkaran organik pada Botanical, atau Chamfered HUD Badge pada Cyberpunk.
/// Jika belum ada foto, tampil inisial nickname.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 48, this.onTap, this.heroTag});

  final double size;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final photoImage = ref.watch(profileProvider.select((s) => s.photoImage));
    final name = ref.watch(displayNameProvider) ?? '?';
    final isCyber = context.isCyberpunk;
    final colors = context.themeColors;

    final Widget avatarCore;
    if (isCyber) {
      final bevel = size * 0.22;
      final shape = BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(bevel),
        side: BorderSide(
          color: colors.primary,
          width: size > 60 ? 2.0 : 1.4,
        ),
      );

      final initialLetter =
          (name.isEmpty ? '?' : String.fromCharCode(name.runes.first)).toUpperCase();

      avatarCore = Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          color: const Color(0xFF080912),
          shape: shape,
          shadows: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.35),
              blurRadius: size > 60 ? 10 : 5,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoImage != null)
                Image(
                  image: photoImage,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                )
              else
                Container(
                  color: const Color(0xFF13172E),
                  alignment: Alignment.center,
                  child: Text(
                    initialLetter,
                    style: TextStyle(
                      fontSize: size * 0.44,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      shadows: [
                        Shadow(
                          color: colors.primary.withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              if (size > 60)
                Positioned(
                  top: 5,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'ID',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      avatarCore = CircleAvatar(
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
    }

    final core = heroTag != null ? Hero(tag: heroTag!, child: avatarCore) : avatarCore;
    final clickBorder = isCyber
        ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(size * 0.22))
        : const CircleBorder();

    return onTap == null
        ? core
        : InkWell(customBorder: clickBorder, onTap: onTap, child: core);
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
            decoration: ShapeDecoration(
              color: colors.primary.withValues(alpha: 0.22),
              shape: isCyber
                  ? BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.60),
                        width: 1.5,
                      ),
                    )
                  : const CircleBorder(),
              shadows: isCyber
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
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: ValueKey('sheetBg_$isCyber'),
                isComplex: true,
                painter: isCyber
                    ? const CyberBackgroundPainter()
                    : const BotanicalBackgroundPainter(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Widget angka finansial dengan animasi roll-up / counter naik yang halus.
/// Mendukung aksesibilitas (otomatis di-bypass jika [MediaQuery.disableAnimationsOf] bernilai true).
class AnimatedMoneyCounter extends StatelessWidget {
  const AnimatedMoneyCounter({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
  });

  final int amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      return Text(
        '$prefix${rupiah(amount)}',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: amount.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(
          '$prefix${rupiah(value.round())}',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

