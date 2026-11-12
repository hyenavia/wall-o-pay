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
import 'icons.dart';
import 'l10n.dart';
import 'period.dart';
import 'theme.dart';

/// AppBar dengan kanopi atmosferik dan lembar melengkung di bawahnya khusus untuk halaman tab utama (Transactions, Budget, Insights).
PreferredSizeWidget pageAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  Widget? bottom,
  double bottomHeight = 0,
}) {
  return AppBar(
    title: title,
    actions: actions,
    centerTitle: false,
    backgroundColor: AppColors.headerCanopyTop,
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
    flexibleSpace: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/glasshouse_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.headerCanopyTop.withValues(alpha: 0.78),
                AppColors.headerCanopyBottom.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
        const IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              isComplex: true,
              painter: BotanicalCanopyPainter(opacity: 0.12),
            ),
          ),
        ),
      ],
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
            color: const Color(0xFF163228),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.dewMint.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// AppBar bersih dan elegan untuk halaman sekunder/detail di luar tab utama.
/// Menggunakan warna dasar mossShadow tanpa latar foto atau lengkungan lembar agar fokus penuh pada konten.
PreferredSizeWidget secondaryAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    title: title,
    actions: actions,
    bottom: bottom,
    centerTitle: false,
    backgroundColor: AppColors.mossShadow,
    foregroundColor: AppColors.softIvory,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: const IconThemeData(color: AppColors.softIvory),
    actionsIconTheme: const IconThemeData(color: AppColors.softIvory),
    titleTextStyle: Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.softIvory),
  );
}

/// Gaya field input yang seragam bergaya Enchanted Glasshouse.
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
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: AppColors.freshSage.withValues(alpha: 0.9),
      fontWeight: FontWeight.w600,
    ),
    hintText: hint,
    hintStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.45),
    ),
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    prefixStyle: const TextStyle(
      color: AppColors.dewMint,
      fontWeight: FontWeight.w700,
    ),
    helperText: helper,
    helperStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.6),
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surfaceContainer.withValues(alpha: 0.70),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.dewMint.withValues(alpha: 0.16)),
    enabledBorder: border(AppColors.dewMint.withValues(alpha: 0.16)),
    focusedBorder: border(AppColors.dewMint.withValues(alpha: 0.55), 1.5),
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
/// Kartu standar dengan latar belakang kaca transparan bergaya Enchanted Glasshouse.
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: AppColors.dewMint.withValues(alpha: 0.16),
        width: 1.0,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.dewMint.withValues(alpha: 0.15),
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface.withValues(alpha: 0.95),
            AppColors.surfaceContainer.withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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

/// Kartu sorotan (HeroCard) untuk saldo, total anggaran, dan sorotan utama bergaya Enchanted Glasshouse.
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF26503E), // Luminous Glasshouse Emerald
            Color(0xFF132B21), // Deep Moss Shadow Glass
          ],
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.emeraldLeaf.withValues(alpha: 0.22),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background konservatori samar di dalam kartu
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                'assets/images/glasshouse_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Garis tepi kaca spekular
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.dewMint.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: BotanicalHeroCardPainter(),
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

/// Lencana ikon kategori persegi membulat bergaya Enchanted Glasshouse.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.categoryKey,
  });

  final IconData icon;
  final Color color;
  final double size;
  final String? categoryKey;

  @override
  Widget build(BuildContext context) {
    final assetPath = glasshouseAssetFor(categoryKey) ?? glasshouseAssetForIcon(icon);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.32),
      side: BorderSide(
        color: AppColors.dewMint.withValues(alpha: 0.22),
        width: 1.0,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(
                assetPath,
                width: size * 0.72,
                height: size * 0.72,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              )
            : Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

/// Indikator bilah progres horizontal dengan ujung membulat.
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

/// Chip pilihan bergaya kapsul stadium bertema Enchanted Glasshouse.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.categoryKey,
    this.assetPath,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final String? categoryKey;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final resolvedAsset = assetPath ??
        glasshouseAssetFor(categoryKey) ??
        (icon != null ? glasshouseAssetForIcon(icon!) : null);
    final fg = selected ? Colors.white : AppColors.softIvory;

    Widget? avatarWidget;
    if (resolvedAsset != null) {
      avatarWidget = Image.asset(
        resolvedAsset,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    } else if (icon != null) {
      avatarWidget = Icon(
        icon,
        size: 18,
        color: selected ? AppColors.dewMint : AppColors.freshSage,
      );
    }

    return ChoiceChip(
      avatar: avatarWidget,
      label: subtitle == null
          ? Text(label)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.dewMint : AppColors.freshSage,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: const Color(0xFF1B4434),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.70),
      side: BorderSide(
        color: selected
            ? AppColors.dewMint.withValues(alpha: 0.60)
            : AppColors.dewMint.withValues(alpha: 0.16),
        width: selected ? 1.2 : 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: TextStyle(
        color: fg,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.freshSage,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11),
                ],
              ),
            ),
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
          color: onDark ? Colors.white : AppColors.freshSage,
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: Text(
            period.label(),
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : AppColors.softIvory,
            ),
          ),
        ),
        IconButton(
          tooltip: context.tr('Next period'),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () => notifier.step(1),
          color: onDark ? Colors.white : AppColors.freshSage,
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
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.dewMint.withValues(alpha: 0.22),
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
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            shape: shape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMonthly ? Icons.calendar_month_outlined : Icons.view_week_outlined,
                size: 15,
                color: AppColors.freshSage,
              ),
              const SizedBox(width: 5),
              Text(
                context.tr(isMonthly ? 'Monthly' : 'Weekly'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softIvory,
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

/// Foto profil lingkaran organik pengguna. Jika belum ada foto, tampil inisial nickname.
/// Mendukung bingkai kaca botani [withGlassFrame] (Enchanted Glasshouse wreath).
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    this.size = 48,
    this.onTap,
    this.heroTag,
    this.withGlassFrame = false,
  });

  final double size;
  final VoidCallback? onTap;
  final String? heroTag;
  final bool withGlassFrame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final photoImage = ref.watch(profileProvider.select((s) => s.photoImage));
    final name = ref.watch(displayNameProvider) ?? '?';

    final avatarCore = CircleAvatar(
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

    final avatarDisplay = !withGlassFrame
        ? avatarCore
        : SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                avatarCore,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 1.42,
                      child: Image.asset(
                        'assets/images/frame_glasshouse.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    final core = heroTag != null ? Hero(tag: heroTag!, child: avatarDisplay) : avatarDisplay;

    return onTap == null
        ? core
        : InkWell(customBorder: const CircleBorder(), onTap: onTap, child: core);
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

    return HeroCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: ShapeDecoration(
              color: colors.primary.withValues(alpha: 0.22),
              shape: const CircleBorder(),
            ),
            child: Icon(icon, size: 38, color: colors.primary),
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

/// Container dengan latar belakang ambient daun botani lembut dan suasana rumah kaca fotorealistik
/// yang identik dengan lembar halaman Beranda (Enchanted Glasshouse).
class BotanicalBackgroundSheet extends StatelessWidget {
  const BotanicalBackgroundSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF163228), // Deep emerald mist at the top
            Color(0xFF11251E), // Subtle moss tint
            Color(0xFF0C1914), // Deep grounding moss shadow
          ],
          stops: [0.0, 0.40, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Suasana Rumah Kaca Alami dari Aset Fotorealistik
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/glasshouse_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF163228).withValues(alpha: 0.85),
                      const Color(0xFF163228).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

