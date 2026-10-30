import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/update_checker.dart';

/// Tipe perubahan dalam catatan rilis.
enum ChangeType { added, changed, fixed }

/// Item catatan perubahan dengan dukungan bilingual (EN/ID).
class ChangeItem {
  final ChangeType type;
  final String textEn;
  final String textId;

  const ChangeItem({
    required this.type,
    required this.textEn,
    required this.textId,
  });
}

/// Entri rilis per versi.
class ReleaseEntry {
  final String version;
  final String dateEn;
  final String dateId;
  final bool isCurrent;
  final List<ChangeItem> changes;

  const ReleaseEntry({
    required this.version,
    required this.dateEn,
    required this.dateId,
    this.isCurrent = false,
    required this.changes,
  });
}

/// Sumber data changelog aplikasi Wall o' Pay.
class AppChangelog {
  static const List<ReleaseEntry> releases = [
    ReleaseEntry(
      version: '1.8.7',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      isCurrent: true,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified signature Botanical Forest theme (Night Pine, Velvet Forest & Sage) for a distinctive, cohesive aesthetic identity.',
          textId: 'Tema eksklusif Signature Botanical Forest (Night Pine, Velvet Forest & Sage) untuk identitas visual yang khas dan berkarakter.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Monthly Start Day (Payday) preference: customize the start day of monthly budget cycles (e.g. 25th) with dynamic period calculations.',
          textId: 'Preferensi Tanggal Mulai Bulanan (Gajian): sesuaikan tanggal awal siklus anggaran bulanan (misal tgl 25) dengan kalkulasi periode dinamis.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Synchronized balance masking: hiding Total Balance now simultaneously masks individual wallet amounts in Wallets & Accounts.',
          textId: 'Sinkronisasi sembunyikan saldo: menyembunyikan Total Saldo kini secara serentak juga menyamarkan nominal di bagian Dompet & Rekening.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.6',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed budget zeroing reversion during cloud sync by preventing stale Firestore merge overwrites and adding timestamp conflict resolution.',
          textId: 'Memperbaiki anggaran bernilai 0 yang kembali ke nominal lama saat sinkronisasi cloud dengan mencegah merge usang pada Firestore dan menambahkan pelacakan timestamp.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.5',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Manual "Send to Cloud" button to immediately upload and backup all local SQLite data to Firestore with item count confirmation.',
          textId: 'Tombol manual "Kirim ke Cloud" untuk mengunggah dan mencadangkan seluruh data SQLite lokal langsung ke Firestore lengkap dengan konfirmasi jumlah data.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Manual "Fetch from Cloud" button to restore and pull all latest cloud data into the local device database.',
          textId: 'Tombol manual "Tarik dari Cloud" untuk memulihkan dan mengambil seluruh data terbaru dari cloud ke database lokal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'In-app Version Changelog viewer in Settings to inspect release notes and patch history offline anytime.',
          textId: 'Fitur Catatan Pembaruan (Changelog) bawaan aplikasi pada menu Pengaturan untuk meninjau riwayat rilis dan patch secara offline kapan saja.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.4',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Resolved Maven Central HTTP 429 rate limit during GitHub Actions CI build by adding Google Cloud Maven mirror and Gradle build caching.',
          textId: 'Mengatasi kendala HTTP 429 rate-limiting pada Maven Central saat build CI di GitHub Actions dengan mirror resmi Google Cloud dan cache dependensi Gradle.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.3',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Permanent account deletion wipe across Firestore collections and username reservations, allowing immediate re-registration.',
          textId: 'Pembersihan tuntas saat hapus akun pada seluruh koleksi Firestore dan reservasi username, memungkinkan nama pengguna didaftarkan ulang seketika.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Multi-language localization for default wallets & accounts (Main Account, Digital Bank, Cash, E-Wallet) across English and Indonesian.',
          textId: 'Dukungan multibahasa untuk nama dompet & rekening bawaan (Rekening Utama, Bank Digital, Tunai, E-Wallet) pada Bahasa Inggris dan Bahasa Indonesia.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.2',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Resolved logout abort caused by missing SQLite table migration for debts and tx_templates.',
          textId: 'Memperbaiki kendala gagal logout akibat migrasi tabel SQLite yang belum selesai pada tabel debts dan tx_templates.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Added automated SQLite self-healing for missing tables on startup.',
          textId: 'Menambahkan mekanisme pemulihan mandiri (self-healing) otomatis saat aplikasi dibuka jika ada tabel database lokal yang belum terbentuk.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.1',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Complete multi-language localization for the Financial Insight tab (labels, charts, empty states, and dynamic advice).',
          textId: 'Lokalisasi multibahasa lengkap untuk tab Insight Keuangan (label grafik, status kosong, dan ringkasan finansial cerdas).',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed cross-device budget category synchronization.',
          textId: 'Memperbaiki sinkronisasi kategori anggaran antar-perangkat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.0',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Debts & Split Bills module to track IOUs, bill shares, and partial repayments.',
          textId: 'Modul Hutang & Patungan untuk mencatat siapa berhutang ke siapa, patungan tagihan, dan pelunasan bertahap.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Exportable PDF financial reports with custom date ranges, category breakdowns, and transaction details.',
          textId: 'Ekspor laporan keuangan format PDF lengkap dengan ringkasan kategori dan rincian transaksi untuk periode tanggal fleksibel.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Smart local notifications and daily logging reminder.',
          textId: 'Notifikasi lokal cerdas dan pengingat harian untuk mencatat pengeluaran secara konsisten.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Quick transaction templates for 1-tap logging of routine expenses.',
          textId: 'Template transaksi cepat untuk mencatat pengeluaran berulang dengan satu ketukan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Needs vs. Wants spending tag allocation for deeper financial clarity.',
          textId: 'Penandaan kategori Kebutuhan (Needs) vs Keinginan (Wants) untuk evaluasi alokasi pengeluaran.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.7.0',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Replaced Target tab with comprehensive Financial Insight tab featuring cashflow trends, pie charts, and actionable financial summaries.',
          textId: 'Menggantikan tab Target dengan tab Insight Keuangan komprehensif lengkap dengan grafik tren arus kas, diagram kategori, dan ringkasan cerdas.',
        ),
      ],
    ),
  ];
}

/// Menampilkan lembar changelog modal yang elegan.
void showAppChangelogSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AppChangelogSheet(),
  );
}

class AppChangelogSheet extends StatelessWidget {
  const AppChangelogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIndonesian = AppLocale.code == 'id';
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.deepForest.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: AppColors.deepForest,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Version Changelog'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              "What's new in Wall o' Pay v{version}",
                              {'version': UpdateCheckerService.currentVersion},
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: context.tr('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: AppChangelog.releases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final release = AppChangelog.releases[index];
                    return _ReleaseCard(
                      release: release,
                      isIndonesian: isIndonesian,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.isIndonesian,
  });

  final ReleaseEntry release;
  final bool isIndonesian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: release.isCurrent
              ? AppColors.deepForest.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: release.isCurrent ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${release.version}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: release.isCurrent ? AppColors.deepForest : null,
                ),
              ),
              const SizedBox(width: 8),
              if (release.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.deepForest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isIndonesian ? 'TERBARU' : 'LATEST',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                isIndonesian ? release.dateId : release.dateEn,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...release.changes.map((item) => _ChangeItemRow(item: item, isIndonesian: isIndonesian)),
        ],
      ),
    );
  }
}

class _ChangeItemRow extends StatelessWidget {
  const _ChangeItemRow({
    required this.item,
    required this.isIndonesian,
  });

  final ChangeItem item;
  final bool isIndonesian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color badgeBg;
    Color badgeFg;
    String badgeLabel;

    switch (item.type) {
      case ChangeType.added:
        badgeBg = const Color(0x1B4CAF50);
        badgeFg = Colors.green.shade700;
        badgeLabel = isIndonesian ? 'BARU' : 'ADDED';
        break;
      case ChangeType.changed:
        badgeBg = const Color(0x1B2196F3);
        badgeFg = Colors.blue.shade700;
        badgeLabel = isIndonesian ? 'UBAH' : 'CHANGED';
        break;
      case ChangeType.fixed:
        badgeBg = const Color(0x1BFF9800);
        badgeFg = Colors.orange.shade800;
        badgeLabel = isIndonesian ? 'PERBAIKAN' : 'FIXED';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeFg,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isIndonesian ? item.textId : item.textEn,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

