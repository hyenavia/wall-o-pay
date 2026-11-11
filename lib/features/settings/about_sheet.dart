/// Modal bottom sheet "Tentang Wall o' Pay" ([AboutWallOPaySheet]) yang menampilkan
/// informasi versi, filosofi desain Botanical Forest, fitur utama, dan tautan repositori.
library;

import 'package:flutter/material.dart';

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
    const mutedColor = AppColors.freshSage;
    const borderColor = AppColors.borderOutline;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.mossShadow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.dewMint.withValues(alpha: 0.35),
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
                  color: AppColors.dewMint.withValues(alpha: 0.35),
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
                          color: AppColors.softIvory,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.softIvory),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: context.tr('Close'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.dewMint.withValues(alpha: 0.12)),

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
                                color: AppColors.dewMint.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepForest.withValues(alpha: 0.40),
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
                          const SizedBox(height: 14),
                          const Text(
                            "Wall o' Pay",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.softIvory,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLeaf.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.dewMint.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'v${UpdateCheckerService.currentVersion} • Release',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dewMint,
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
                        color: AppColors.glasshouseGreen.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.dewMint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.dewMint,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr(
                                'Small steps, nurtured consistently, create meaningful growth.',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: AppColors.softIvory,
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
                        color: AppColors.dewMint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'Wall o\' Pay was built with a singular vision: managing personal finances should feel mindful, empowering, and calm—never stressful or intimidating. Here is the meaning behind our identity:',
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: mutedColor,
                        height: 1.4,
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
                      icon: Icons.eco_outlined,
                      title: context.tr('The Growing Sprout'),
                      description: context.tr(
                        'Reframing "Pay" into "Pay yourself first"—every dollar budgeted and saved is a seed nurtured to flourish over time.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.auto_awesome_outlined,
                      title: context.tr('The Guiding Star'),
                      description: context.tr(
                        'The spark of reaching your savings targets, debt freedom, and achieving lasting financial serenity.',
                      ),
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    _LoreCard(
                      icon: Icons.forest_outlined,
                      title: context.tr('The Botanical Sanctuary'),
                      description: context.tr(
                        'An organic, tranquil environment inspired by the deep forest, replacing aggressive corporate fintech with mindful peace.',
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
                        color: AppColors.dewMint,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dewMint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.dewMint.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: AppColors.dewMint, size: 20),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.dewMint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.dewMint.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: AppColors.dewMint, size: 18),
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

