/// Modal bottom sheet "Tentang Wall o' Pay" ([AboutWallOPaySheet]) yang menampilkan
/// informasi versi, filosofi desain Vice City Sunset, fitur utama, dan tautan repositori.
library;

import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/update_checker.dart';
import 'app_changelog.dart';

/// Menampilkan modal bottom sheet berisi informasi aplikasi, filosofi brand, dan lore Wall o' Pay.
void showAboutWallOPaySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AboutWallOPaySheet(),
  );
}

class AboutWallOPaySheet extends StatelessWidget {
  const AboutWallOPaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isIndonesian = AppLocale.code == 'id';
    const mutedColor = AppColors.mutedBlueGray;
    const borderColor = AppColors.borderOutline;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.midnightNavy,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.borderOutline.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedBlueGray.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('About Wall o\' Pay'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.softWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.softWhite),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: context.tr('Close'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.borderOutline.withValues(alpha: 0.5)),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Brand Header Card
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.borderOutline.withValues(alpha: 0.85),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sunsetMagenta.withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Image.asset(
                              'assets/new_asset/custom_text/logo_wordmark_tropical_neon.png',
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sunsetMagenta.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.goldenYellow.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              'v${UpdateCheckerService.currentVersion} • Release',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldenYellow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Your money, under your control.'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lore Quote Highlight Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.deepNavy.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.goldenYellow.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/new_asset/ui/dashboard_greeting.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr(
                                'Bold clarity, steady rhythm, and full control over every move.',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: AppColors.softWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Brand Lore & Philosophy
                    Text(
                      context.tr('Brand Lore & Philosophy'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldenYellow,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'Wall o\' Pay was built with a singular vision: managing personal finances should feel bold, effortless, and crystal clear—never cluttered or intimidating. Here is the meaning behind our identity:',
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Official Wendy Mascot Card
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.sunsetMagenta.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sunsetMagenta.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/new_asset/background/vice_city_background.png',
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.28),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/new_asset/poses/pose_10.png',
                                  width: 72,
                                  height: 90,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/new_asset/custom_text/logo_wordmark_glossy_neon.png',
                                            height: 18,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.neonCyan.withValues(alpha: 0.20),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.40)),
                                            ),
                                            child: const Text(
                                              'Mascot',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.neonCyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.tr('Wendy · Official Mascot Companion'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.softWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.tr(
                                          'Meet Wendy, your trusted companion navigating cashflow with Vice City Sunset style and confidence.',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mutedBlueGray,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Lore Pillars
                    _LoreCard(
                      icon: Icons.shield_outlined,
                      title: context.tr('The Protective Wall'),
                      description: context.tr(
                        'A steadfast financial barrier that shields you from overspending and safeguards your privacy with offline-first data sovereignty.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.savings_outlined,
                      title: context.tr('Pay Yourself First'),
                      description: context.tr(
                        'Reframing "Pay" into "Pay yourself first"—every rupiah budgeted and saved fuels your momentum toward bigger goals.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.auto_awesome_outlined,
                      title: context.tr('The Neon Horizon'),
                      description: context.tr(
                        'The glow of hitting your savings targets, clearing debts, and cruising toward lasting financial freedom.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.nights_stay_outlined,
                      title: context.tr('Vice City Sunset'),
                      description: context.tr(
                        'A retro-modern coastal sunset atmosphere with crisp neon contrast, replacing sterile corporate fintech with effortless style.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Section: Core Principles
                    Text(
                      context.tr('Core Principles'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldenYellow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PrincipleRow(
                      icon: Icons.offline_bolt_outlined,
                      title: context.tr('Offline-First Architecture'),
                      subtitle: context.tr(
                        'Fast SQLite storage with zero latency and complete local privacy.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PrincipleRow(
                      icon: Icons.cloud_done_outlined,
                      title: context.tr('Seamless Cloud Sync'),
                      subtitle: context.tr(
                        'Optional real-time backup to Firebase for multi-device continuity.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: App Information & Actions
                    Text(
                      context.tr('App Information'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dewMint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderOutline),
                      ),
                      child: Column(
                        children: [
                          _MetaRow(
                            label: context.tr('Developer'),
                            value: 'Hyenavia',
                          ),
                          Divider(height: 16, color: AppColors.dewMint.withValues(alpha: 0.12)),
                          _MetaRow(
                            label: context.tr('License'),
                            value: 'MIT License (Open Source)',
                          ),
                          Divider(height: 16, color: AppColors.dewMint.withValues(alpha: 0.12)),
                          _MetaRow(
                            label: context.tr('Source Code'),
                            value: 'GitHub Repository',
                            isLink: true,
                            onTap: () {
                              UpdateCheckerService.openUrl(
                                'https://github.com/hyenavia/wall-o-pay',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dewMint,
                              side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.history_edu_rounded, size: 18),
                            label: Text(
                              context.tr('Version Changelog'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              showAppChangelogSheet(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.glasshouseGreen,
                              foregroundColor: AppColors.softIvory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.35)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.feedback_outlined, size: 18),
                            label: Text(
                              context.tr('Send Feedback'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              final url = isIndonesian
                                  ? 'https://forms.gle/jzhTG5HmxA96xCsX8'
                                  : 'https://forms.gle/W5MNr8eeZcmiiPbp9';
                              UpdateCheckerService.openUrl(url);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoreCard extends StatelessWidget {
  const _LoreCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.dewMint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.dewMint.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: viceCityAssetForIcon(icon) != null
                ? Image.asset(viceCityAssetForIcon(icon)!, fit: BoxFit.contain)
                : Icon(icon, color: AppColors.dewMint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softIvory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.freshSage,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.dewMint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.dewMint.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: viceCityAssetForIcon(icon) != null
              ? Image.asset(viceCityAssetForIcon(icon)!, fit: BoxFit.contain)
              : Icon(icon, color: AppColors.dewMint, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softIvory,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.freshSage,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.freshSage,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isLink ? AppColors.dewMint : AppColors.softIvory,
              ),
            ),
            if (isLink) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: AppColors.dewMint,
              ),
            ],
          ],
        ),
      ],
    );

    if (isLink && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: content,
      );
    }
    return content;
  }
}

