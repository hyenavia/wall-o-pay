/// Kumpulan komponen UI bersama (reusable widgets) yang dipakai di seluruh fitur,
/// seperti AppBar melengkung (`pageAppBar`), `AppCard`, `HeroCard`, `PeriodSwitcher`, dan `UserAvatar`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

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
  final colors = context.themeColors;
  return AppBar(
    title: title,
    actions: actions,
    centerTitle: false,
    backgroundColor: colors.headerCanopyTop,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
    flexibleSpace: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          colors.verticalBgAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.isDark
                  ? [
                      colors.headerCanopyTop.withValues(alpha: 0.15),
                      colors.headerCanopyBottom.withValues(alpha: 0.55),
                    ]
                  : [
                      colors.headerCanopyTop.withValues(alpha: 0.52),
                      colors.headerCanopyBottom.withValues(alpha: 0.68),
                    ],
            ),
          ),
        ),
        ExcludeSemantics(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                isComplex: true,
                painter: BotanicalCanopyPainter(
                  opacity: 0.12,
                  isDark: colors.isDark,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    bottom: _SheetEdge(childHeight: bottomHeight, child: bottom),
  );
}

/// Lengkungan atas lembar background di bawah header.
class _SheetEdge extends StatelessWidget implements PreferredSizeWidget {
  const _SheetEdge({this.child, this.childHeight = 0});

  final Widget? child;
  final double childHeight;

  static const double edge = 24;

  @override
  Size get preferredSize => Size.fromHeight(childHeight + edge);

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (child != null) SizedBox(height: childHeight, child: child),
        Container(
          height: edge,
          decoration: BoxDecoration(
            color: colors.isDark ? colors.cardSurface : colors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colors.borderOutline.withValues(alpha: colors.isDark ? 0.85 : 1.0),
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
PreferredSizeWidget secondaryAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final colors = context.themeColors;
  return AppBar(
    title: title,
    actions: actions,
    bottom: bottom,
    centerTitle: false,
    backgroundColor: colors.bg,
    foregroundColor: colors.textPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle:
        colors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    iconTheme: IconThemeData(color: colors.textPrimary),
    actionsIconTheme: IconThemeData(color: colors.textPrimary),
    titleTextStyle: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700, color: colors.textPrimary),
  );
}

/// Gaya field input yang seragam untuk tema Vice City Sunset & Daylight.
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
  final colors = context.themeColors;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: colors.accentSecondary.withValues(alpha: colors.isDark ? 0.9 : 1.0),
      fontWeight: FontWeight.w600,
    ),
    hintText: hint,
    hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    prefixStyle: TextStyle(
      color: colors.isDark ? AppColors.dewMint : colors.primary,
      fontWeight: FontWeight.w700,
    ),
    helperText: helper,
    helperStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: colors.isDark
        ? AppColors.surfaceContainer.withValues(alpha: 0.70)
        : colors.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(
      colors.isDark ? AppColors.dewMint.withValues(alpha: 0.16) : colors.inputBorder,
    ),
    enabledBorder: border(
      colors.isDark ? AppColors.dewMint.withValues(alpha: 0.16) : colors.inputBorder,
    ),
    focusedBorder: border(
      colors.isDark ? AppColors.dewMint.withValues(alpha: 0.55) : colors.primary,
      1.5,
    ),
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
    final colors = context.themeColors;
    final borderColor = colors.borderOutline.withValues(alpha: colors.isDark ? 0.8 : 1.0);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: borderColor,
        width: 1.0,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        color: colors.isDark ? null : colors.cardSurface,
        gradient: colors.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.cardSurface.withValues(alpha: 0.95),
                  colors.surfaceContainer.withValues(alpha: 0.88),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1A0E33).withValues(alpha: 0.06),
            blurRadius: 14,
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

/// Kartu sorotan (HeroCard) untuk saldo, total anggaran, dan sorotan utama bergaya Vice City Sunset & Daylight.
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [
                  Color(0xFF2B1554), // Midnight Purple (calibrated)
                  Color(0xFF14092B), // Deep Twilight Purple
                ]
              : const [
                  Color(0xFF0A4DA6), // Ocean Sapphire
                  Color(0xFF082E6E), // Deep Coastal Blue
                ],
        ),
        shadows: colors.isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.sunsetMagenta.withValues(alpha: 0.16),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0A4DA6).withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Background neon/daylight waves samar di dalam kartu
          Positioned.fill(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: colors.isDark ? 0.18 : 0.42,
                child: Image.asset(
                  colors.heroBgAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (!colors.isDark)
            Positioned.fill(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0A4DA6).withValues(alpha: 0.48),
                        const Color(0xFF082E6E).withValues(alpha: 0.62),
                      ],
                    ),
                  ),
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
                    color: colors.isDark
                        ? AppColors.borderOutline.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: BotanicalHeroCardPainter(isDark: colors.isDark),
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

/// Lencana ikon kategori persegi membulat bergaya Vice City Sunset & Daylight.
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
    final colors = context.themeColors;
    final duotoneIcon = phosphorForCategoryOrIcon(categoryKey, icon);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.32),
      side: BorderSide(
        color: colors.borderOutline.withValues(alpha: colors.isDark ? 0.8 : 1.0),
        width: 1.0,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: colors.isDark
            ? colors.surfaceContainer.withValues(alpha: 0.85)
            : colors.surfaceContainer,
        shape: shape,
        shadows: colors.isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1A0E33).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: AppDuotoneIcon(
          duotoneIcon,
          size: size * 0.56,
          color: color,
        ),
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
    this.duotoneIcon,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final String? categoryKey;
  final PhosphorDuotoneIconData? duotoneIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final resolvedDuotone =
        duotoneIcon ??
        phosphorForKey(categoryKey) ??
        (icon != null ? phosphorForIcon(icon!) : null);
    final fg = selected
        ? (colors.isDark ? Colors.white : colors.onPrimary)
        : colors.textPrimary;
    final iconColor = selected
        ? (colors.isDark ? AppColors.dewMint : colors.onPrimary)
        : colors.accentSecondary;

    Widget? avatarWidget;
    if (resolvedDuotone != null) {
      avatarWidget = AppDuotoneIcon(
        resolvedDuotone,
        size: 17,
        color: iconColor,
      );
    } else if (icon != null) {
      avatarWidget = Icon(
        icon,
        size: 18,
        color: iconColor,
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
                    color: selected
                        ? (colors.isDark
                            ? AppColors.dewMint
                            : colors.onPrimary.withValues(alpha: 0.9))
                        : colors.accentSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: colors.isDark ? const Color(0xFF1B4434) : colors.primary,
      backgroundColor: colors.isDark
          ? AppColors.surfaceContainer.withValues(alpha: 0.70)
          : colors.surfaceContainer,
      side: BorderSide(
        color: selected
            ? (colors.isDark
                ? AppColors.dewMint.withValues(alpha: 0.60)
                : colors.primary)
            : (colors.isDark
                ? AppColors.dewMint.withValues(alpha: 0.16)
                : colors.inputBorder),
        width: selected ? 1.2 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final colors = context.themeColors;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentSecondary,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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

  /// Teks dan ikon putih, untuk dipakai di atas header gelap.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeColors;
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
          color: onDark ? Colors.white : colors.accentSecondary,
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: Text(
            period.label(),
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: context.tr('Next period'),
          visualDensity: compact ? VisualDensity.compact : null,
          onPressed: () => notifier.step(1),
          color: onDark ? Colors.white : colors.accentSecondary,
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
    final colors = context.themeColors;
    final type = ref.watch(appPrefsProvider.select((p) => p.periodType));
    if (compact) {
      final isMonthly = type == PeriodType.monthly;
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.isDark
              ? AppColors.dewMint.withValues(alpha: 0.22)
              : colors.inputBorder,
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
            color: colors.isDark
                ? AppColors.surfaceContainer.withValues(alpha: 0.85)
                : colors.surfaceContainer,
            shape: shape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMonthly
                    ? Icons.calendar_month_outlined
                    : Icons.view_week_outlined,
                size: 15,
                color: colors.accentSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                context.tr(isMonthly ? 'Monthly' : 'Weekly'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
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
    final frameId = ref.watch(profileProvider.select((s) => s.frameId));
    final frameAsset = profileFrameAssetPath(frameId);
    final name = ref.watch(displayNameProvider) ?? '?';

    final initialText = Text(
      (name.isEmpty ? '?' : String.fromCharCode(name.runes.first))
          .toUpperCase(),
      style: TextStyle(
        fontSize: size * 0.4,
        fontWeight: FontWeight.w800,
        color: scheme.onPrimaryContainer,
      ),
    );

    final avatarCore = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      child: photoImage == null
          ? initialText
          : ClipOval(
              child: Image(
                image: photoImage,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: initialText),
              ),
            ),
    );

    final avatarDisplay = frameAsset == null
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
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: profileFrameScale(frameId),
                        child: FractionalTranslation(
                          translation: profileFrameOffset(frameId),
                          child: Image.asset(
                            frameAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    final core = heroTag != null
        ? Hero(tag: heroTag!, child: avatarDisplay)
        : avatarDisplay;

    return onTap == null
        ? core
        : InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: core,
          );
  }
}

/// Helper untuk menentukan path ilustrasi kosong Tropical Neon Finance berdasarkan [IconData].
String resolveEmptyIllustration(IconData icon) {
  if (icon == Icons.receipt ||
      icon == Icons.receipt_long ||
      icon == Icons.receipt_long_outlined ||
      icon == Icons.account_balance_wallet ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.wallet ||
      icon == Icons.payments ||
      icon == Icons.payment ||
      icon == Icons.swap_horiz) {
    return 'assets/new_asset/ui/empty_wallet.png';
  }
  if (icon == Icons.pie_chart ||
      icon == Icons.pie_chart_outline ||
      icon == Icons.pie_chart_rounded ||
      icon == Icons.donut_large) {
    return 'assets/new_asset/ui/empty_budget.png';
  }
  if (icon == Icons.savings ||
      icon == Icons.savings_outlined ||
      icon == Icons.flag ||
      icon == Icons.flag_outlined ||
      icon == Icons.track_changes ||
      icon == Icons.eco_outlined ||
      icon == Icons.eco) {
    return 'assets/illustrations/empty_savings.png';
  }
  if (icon == Icons.insights ||
      icon == Icons.insights_outlined ||
      icon == Icons.bar_chart ||
      icon == Icons.show_chart ||
      icon == Icons.trending_up) {
    return 'assets/new_asset/ui/weekly_monthly_summary.png';
  }
  if (icon == Icons.search ||
      icon == Icons.search_rounded ||
      icon == Icons.search_off ||
      icon == Icons.search_off_rounded ||
      icon == Icons.filter_list) {
    return 'assets/new_asset/ui/no_data_state.png';
  }
  if (icon == Icons.notifications ||
      icon == Icons.notifications_outlined ||
      icon == Icons.notifications_off_outlined ||
      icon == Icons.repeat ||
      icon == Icons.repeat_rounded ||
      icon == Icons.event_repeat ||
      icon == Icons.alarm) {
    return 'assets/illustrations/empty_notifications.png';
  }
  return 'assets/new_asset/ui/empty_wallet.png';
}

/// Tampilan informasi saat daftar masih kosong dengan ilustrasi Tropical Neon Finance.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.illustrationAsset,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? illustrationAsset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final illustration = illustrationAsset ?? resolveEmptyIllustration(icon);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              illustration,
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
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
    builder: (_) =>
        _AmountDialog(title: title, initial: initial, helper: helper),
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
  late final TextEditingController _controller = TextEditingController(
    text: formatThousands(widget.initial ?? 0),
  );

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
        decoration: appInput(context, prefixText: currencyInputPrefix, helper: widget.helper),
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

/// Kartu keadaan kosong bergaya Vice City Sunset dengan ilustrasi dan ajakan positif.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.receipt_long_outlined,
    this.illustrationAsset,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final illustration = illustrationAsset ?? resolveEmptyIllustration(icon);

    return HeroCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Image.asset(
            illustration,
            width: 124,
            height: 124,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.isDark ? colors.textPrimary : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.isDark
                  ? colors.textMuted
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: colors.isDark ? colors.primary : Colors.white,
                foregroundColor: colors.isDark ? colors.onPrimary : colors.primary,
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
  final messenger =
      rootScaffoldMessengerKey.currentState ??
      (context != null && context.mounted
          ? ScaffoldMessenger.maybeOf(context)
          : null);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        label: trG('Undo'),
        textColor: context != null
            ? Theme.of(context).colorScheme.primary
            : AppColors.sage,
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

typedef ViceCityBackgroundSheet = BotanicalBackgroundSheet;

/// Container dengan latar belakang ambient neon waves dan suasana retro-modern
/// yang identik dengan lembar halaman Beranda (Vice City Sunset).
class BotanicalBackgroundSheet extends StatelessWidget {
  const BotanicalBackgroundSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.isDark
              ? const [
                  Color(0xFF0E1738), // Deep Navy canopy at top
                  Color(0xFF090F2C), // Subtle Midnight Navy
                  Color(0xFF070D2B), // Deep Midnight Navy Canvas
                ]
              : [
                  colors.bg,
                  const Color(0xFFF3EEFA),
                  colors.bg,
                ],
          stops: const [0.0, 0.40, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Suasana Sunset / Daylight Vertikal Vice City
          Positioned.fill(
            child: Image.asset(
              colors.verticalBgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.isDark
                      ? [
                          const Color(0xFF0E1738).withValues(alpha: 0.78),
                          const Color(0xFF070D2B).withValues(alpha: 0.85),
                          const Color(0xFF070D2B).withValues(alpha: 0.92),
                        ]
                      : [
                          colors.bg.withValues(alpha: 0.86),
                          colors.bg.withValues(alpha: 0.94),
                          colors.bg.withValues(alpha: 0.97),
                        ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: BotanicalBackgroundPainter(isDark: colors.isDark),
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
                      (colors.isDark ? colors.cardSurface : colors.bg)
                          .withValues(alpha: 0.85),
                      (colors.isDark ? colors.cardSurface : colors.bg)
                          .withValues(alpha: 0.0),
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
