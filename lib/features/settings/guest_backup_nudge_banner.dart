/// Banner pengingat backup JSON lokal untuk pengguna Mode Tamu saat jumlah transaksi lokal
/// sudah memadai dan belum pernah dicadangkan (atau sudah melewati ambang hari).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/budget_rule.dart';
import '../../data/export_service.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import 'settings_actions.dart';

/// Mengekspor seluruh data lokal (database, preferensi, aturan anggaran) ke berkas JSON
/// dan mencatat waktu backup terakhir di `SharedPreferences`.
Future<void> triggerGuestJsonBackup(BuildContext context, WidgetRef ref) {
  return SettingsActions.runAction(context, () async {
    final prefsMap = ref.read(appPrefsProvider.notifier).exportPreferences();
    final budgetMap = ref.read(budgetRuleProvider.notifier).exportConfig();
    await ExportService(ref.read(databaseProvider)).shareBackup(
      preferences: prefsMap,
      budgetConfig: budgetMap,
    );
    await ref.read(sharedPreferencesProvider).setInt(
          kLastJsonBackupMsKey,
          DateTime.now().millisecondsSinceEpoch,
        );
    return trG('Backup file ready to share.');
  });
}

/// Banner peringatan ringan untuk pengguna Mode Tamu agar melakukan backup JSON secara berkala.
class GuestBackupNudgeBanner extends ConsumerStatefulWidget {
  const GuestBackupNudgeBanner({
    super.key,
    required this.onBackupNow,
    this.margin = const EdgeInsets.only(top: 16),
  });

  final Future<void> Function() onBackupNow;
  final EdgeInsetsGeometry margin;

  @override
  ConsumerState<GuestBackupNudgeBanner> createState() =>
      _GuestBackupNudgeBannerState();
}

class _GuestBackupNudgeBannerState
    extends ConsumerState<GuestBackupNudgeBanner> {
  Future<int>? _txCountFuture;

  void _refreshCount() {
    _txCountFuture = ref
        .read(databaseProvider)
        .allActiveTransactions()
        .then((rows) => rows.length);
  }

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  void didUpdateWidget(covariant GuestBackupNudgeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.read(sharedPreferencesProvider);
    return FutureBuilder<int>(
      future: _txCountFuture,
      builder: (context, snapshot) {
        final txCount = snapshot.data ?? 0;
        final shouldShow = ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: txCount,
          lastBackupMs: prefs.getInt(kLastJsonBackupMsKey),
          dismissedAtMs: prefs.getInt(kGuestBackupNudgeDismissedAtMsKey),
          now: DateTime.now(),
        );
        if (!shouldShow) return const SizedBox.shrink();

        return Container(
          margin: widget.margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Back up your local records'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.softIvory,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(
                            'You have {count} local transactions without a recent backup. Save a JSON copy so your data stays safe.',
                            {'count': txCount},
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.freshSage,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.freshSage,
                    ),
                    tooltip: context.tr('Dismiss'),
                    onPressed: () async {
                      await prefs.setInt(
                        kGuestBackupNudgeDismissedAtMsKey,
                        DateTime.now().millisecondsSinceEpoch,
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    await widget.onBackupNow();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: Text(context.tr('Backup Now')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.mossShadow,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

