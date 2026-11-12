/// Data riwayat pembaruan versi aplikasi ([AppChangelog]) dalam dua bahasa (EN/ID)
/// beserta komponen bottom sheet penampil catatan rilis di dalam aplikasi.
library;

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
      version: '2.16.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: true,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Widget Glass Opacity & Live Hub Previews — Switch between Deep, Frosted, and Clear glass styles for all 6 Home Screen widgets, preview cards with your live numbers in Settings, and re-enable required modules in one tap.',
          textId:
              'Gaya Kaca Widget & Pratinjau Langsung — Pilih tingkat transparansi Deep, Frosted, atau Clear untuk keenam widget layar utama, lihat pratinjau langsung dengan data asli di Pengaturan, dan aktifkan modul terkait dalam sekali ketuk.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Widget Polish & Quick Privacy Toggle — Added Material ripple feedback and larger touch targets across Home Screen widgets, 15s auto-dismiss for One-Tap Favorites Undo banners, Android 8–11 static previews, and direct privacy toggle on Quick Action Bar balance pill.',
          textId:
              'Penyempurnaan Widget & Sensor Cepat — Menambahkan efek riak Material dan area sentuh lebih lega, banner Urungkan otomatis tertutup setelah 15 detik di Favorit Sekali Ketuk, pratinjau statis Android 8–11, serta ketuk pil saldo di Bilah Aksi Cepat untuk menyembunyikan nominal.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.15.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Goals & Upcoming Bills Home Screen Widget — Track active savings goal progress with an inline goal switcher and watch upcoming or overdue scheduled bills right from your Android Home Screen (2×2 & 4×2).',
          textId:
              'Widget Target & Tagihan Mendatang — Pantau progres target tabungan aktif dengan tombol ganti target langsung serta jadwal tagihan mendatang dan terlambat dari layar beranda Android (2×2 & 4×2).',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'In-App Android Home Widgets Hub — Explore all 6 Enchanted Glasshouse widgets in Settings, see active Home Screen counts, sync snapshots immediately, and pin widgets directly on Android 8.0+.',
          textId:
              'Hub Widget Layar Utama di Pengaturan — Jelajahi seluruh 6 widget Enchanted Glasshouse, lihat jumlah yang terpasang, sinkronkan data seketika, dan sematkan widget langsung pada Android 8.0+.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.14.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'One-Tap Favorites Home Screen Widget — Record your saved transaction templates right from your Android Home Screen (4×1 & 4×2) in a single tap with instant Undo support.',
          textId:
              'Widget Favorit Sekali Ketuk — Catat template transaksi tersimpan langsung dari layar beranda Android (4×1 & 4×2) dalam sekali ketuk lengkap dengan tombol Urungkan instan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Budget Guardrail Home Screen Widget — Monitor remaining period budget, warning thresholds (Safe / 85%+ Near / 100%+ Over), and top 3 spending categories (2×2 & 4×2) with rollover and privacy masking.',
          textId:
              'Widget Penjaga Anggaran — Pantau sisa anggaran periode aktif, peringatan batas aman (Aman / Hampir 85%+ / Lewat 100%+), dan 3 kategori pengeluaran teratas (2×2 & 4×2) lengkap dengan rollover serta sensor privasi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Lock-Aware Widget Deep Link Routing — Tapping Home Screen widgets jumps straight to the relevant tab or transaction form while still honoring PIN and biometric LockGate.',
          textId:
              'Navigasi Deep Link Widget Aman PIN — Mengetuk widget beranda mengarahkan langsung ke tab terkait atau form transaksi setelah melewati verifikasi PIN & biometrik LockGate.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.13.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Daily Pulse & Balance Home Screen Widget — Monitor your safe daily spending quota, today\'s expense progress, financial health tier (Safe / Caution / Limit), total balance, and toggle balance privacy right from your Android Home Screen (2×2 & 4×2).',
          textId:
              'Widget Beranda Daily Pulse & Saldo — Pantau kuota belanja aman harian, progres pengeluaran hari ini, status kesehatan finansial (Aman / Waspada / Batas), total saldo, serta tombol sensor privasi langsung dari Home Screen Android (2×2 & 4×2).',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Quick Action Bar Home Screen Widget — A sleek 2×1 / 4×1 Enchanted Glasshouse action strip with live balance pill and one-tap Income, Expense, and Transfer shortcuts.',
          textId:
              'Widget Bilah Aksi Cepat — Bilah ringkas 2×1 / 4×1 bergaya Enchanted Glasshouse lengkap dengan pil saldo dan pintasan satu ketuk untuk Pemasukan, Pengeluaran, dan Transfer.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Shared Snapshot Sync & Midnight Rollover — Seamless Flutter-to-native snapshot sync with WorkManager midnight refresh so daily spending quotas stay accurate even before opening the app.',
          textId:
              'Sinkronisasi Snapshot & Pembaruan Tengah Malam — Sinkronisasi snapshot terpadu antara Flutter dan widget native dengan pembaruan otomatis tengah malam via WorkManager.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.12.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Faster Daily Recording & Duplication — Wallet chips now show compact live balances (privacy-aware), incoming shares auto-suggest type/category/merchant note, "Save as template" is directly accessible, and any transaction can be recorded again via long-press or the edit header.',
          textId:
              'Pencatatan & Duplikasi Lebih Cepat — Chip dompet kini menampilkan saldo ringkas (mengikuti mode privasi), teks bagikan otomatis mendeteksi tipe/kategori/catatan merchant, tombol "Simpan sebagai template" langsung terlihat, dan transaksi lama bisa dicatat ulang lewat tekan lama atau ikon salin.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'One-Tap Budget Continuity & Smarter Alerts — Copy your previous period total pool and category limits with one tap when starting an empty period, with budget alerts now factoring in category rollover carryover and total budget pools.',
          textId:
              'Kontinuitas Anggaran Satu Ketuk & Notifikasi Lebih Cerdas — Salin total anggaran dan batas kategori periode lalu dengan satu ketuk saat memulai periode kosong, plus peringatan anggaran kini memperhitungkan sisa rollover dan total anggaran periode.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Interactive Insight Drill-Down & Export Shortcuts — Tap Smart Insight cards to inspect matching transactions, tap scheduled bill reserves in Daily Financial Pulse to open Recurring Bills, and export PDF/CSV directly from Transactions.',
          textId:
              'Drill-Down Insight Interaktif & Pintasan Ekspor — Ketuk kartu Insight Pintar untuk memeriksa daftar transaksi terkait, ketuk cadangan tagihan di Daily Financial Pulse untuk membuka Jadwal Berulang, serta ekspor PDF/CSV langsung dari halaman Transaksi.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Consistent Budget Input Formatting — Total budget and category limit inputs now use live thousands separators.',
          textId:
              'Format Input Anggaran Konsisten — Kolom total anggaran dan batas kategori kini memakai pemisah ribuan otomatis saat diketik.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Default Transfer Wallets & PDF Transfer Sign — Default source/destination transfer chips now save immediately without re-tapping, and PDF tables display transfers cleanly with `<->` instead of `-`.',
          textId:
              'Dompet Bawaan Transfer & Tanda Transfer PDF — Chip dompet asal/tujuan bawaan pada mode transfer langsung tersimpan tanpa diketuk ulang, dan laporan PDF menampilkan transfer dengan `<->` alih-alih `-`.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.11.1',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Final Release UI & Bilingual Verification — Verified Net Worth & Vitality Score, Goal Savings Pace quick-fill, and Harvest Recap settings rendering cleanly across English and Indonesian.',
          textId: 'Verifikasi UI & Dwibahasa Final — Memastikan tampilan Kekayaan Bersih & Skor Vitalitas, isi cepat Ritme Target, serta pengaturan Rekap Panen berjalan mulus di Bahasa Inggris dan Indonesia.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Documentation & Landing Page Polish — Synchronized technical specs, architecture notes, and release readiness across README, ARCHITECTURE guide, and landing page.',
          textId: 'Penyelarasan Dokumentasi & Halaman Web — Menyelaraskan spesifikasi teknis, panduan arsitektur, dan kesiapan rilis di README, ARCHITECTURE, dan halaman landing.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.11.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Net Worth & Glasshouse Vitality Score — Track unified net worth (liquid wallets + receivables - liabilities) and a 0-100 four-pillar financial health score inside Insights.',
          textId: 'Kekayaan Bersih & Skor Vitalitas Glasshouse — Pantau kekayaan bersih menyeluruh (saldo dompet + piutang - utang) beserta skor kesehatan keuangan 0-100 empat pilar di halaman Insight.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Goal Savings Pace & Quick-Fill — View weekly/monthly target pace, on-track/behind status badges, and a one-tap recommended pace fill button when funding Savings Goals.',
          textId: 'Ritme Tabungan Target & Isi Cepat — Lihat target setoran mingguan/bulanan, lencana status progres, dan tombol isi cepat nominal rekomendasi saat menabung ke Target.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Contextual Harvest Recap Notifications — Enable optional digest alerts in Settings to get notified once when a new weekly or monthly recap is ready to review.',
          textId: 'Notifikasi Rekap Panen Kontekstual — Aktifkan pengingat opsional di Pengaturan untuk menerima pemberitahuan sekali saat rekap mingguan atau bulanan terbaru siap ditinjau.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'CI Release Quality Gate — Added automated static analysis and test verification checks ahead of release APK builds.',
          textId: 'Gerbang Kualitas Rilis CI — Menambahkan verifikasi analisis statis dan uji otomatis sebelum kompilasi APK rilis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.10.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Weekly & Monthly Financial Recap — Review completed weekly or monthly cashflow, savings rate, top categories, Needs/Wants balance, and goals progress via Glasshouse Harvest Review inside Insights.',
          textId: 'Rekap Keuangan Mingguan & Bulanan — Tinjau arus kas, rasio tabungan, kategori terbesar, rasio Kebutuhan/Keinginan, dan progres target tabungan melalui Tinjauan Panen Glasshouse di halaman Insight.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Interactive Category Drill-Down — Tap any top category row or Expense Composition slice/legend to inspect matching period transactions directly.',
          textId: 'Drill-Down Kategori Interaktif — Ketuk baris kategori teratas maupun irisan/legenda diagram lingkaran untuk langsung melihat rincian transaksi terkait.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Custom Split Bills & Filtered Exports — Split group bills with non-equal custom shares per friend, filter PDF & CSV exports by account and date range, and get local backup reminders in Guest Mode.',
          textId: 'Patungan Nominal Kustom & Ekspor Terfilter — Bagi tagihan dengan nominal berbeda per teman, filter ekspor PDF & CSV berdasarkan rekening dan rentang tanggal, serta pengingat cadangan JSON untuk Mode Tamu.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Active Modules & Incremental Cloud Sync — Customize active modules cleanly in Settings (including a Minimalist preset) alongside faster incremental Firestore sync cursors.',
          textId: 'Modul Aktif & Sinkronisasi Cloud Inkremental — Atur modul yang ingin ditampilkan lewat Pengaturan (termasuk preset Minimalis) beserta sinkronisasi Firestore inkremental yang lebih ringan kuota.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.9.1',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Streamlined Home Dashboard — Removed the 4-button Quick Actions strip on the Home screen to keep your main overview simple, calm, and focused while keeping Transfers, Recurring, Debts, and Goals accessible in their dedicated hubs.',
          textId: 'Beranda Lebih Ringkas — Menghapus bilah 4 Aksi Cepat dari Beranda agar tampilan utama tetap sederhana, tenang, dan fokus sementara Transfer, Jadwal Rutin, Utang, dan Target tetap mudah diakses lewat menunya masing-masing.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.9.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Multi-Filter Transaction Search & Net Flow Strip — Search across wallets, categories, localized category names, and Needs/Wants tags with up to 250 SQL results, one-tap clear search, and net flow summary.',
          textId: 'Pencarian Transaksi Multi-Filter & Ringkasan Arus Bersih — Cari berdasarkan dompet, kategori, nama kategori terjemahan, serta filter Kebutuhan/Keinginan hingga 250 hasil SQL lengkap dengan tombol hapus cepat dan ringkasan arus kas.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Recurring Confirmation Queue & Transfer Schedules — Due recurring rules queue safely for Confirm, Edit, or Skip (with Undo) right from Home or Recurring, plus schedule editing, Transfer support, Record now, and Skip next due.',
          textId: 'Antrean Konfirmasi Tagihan Rutin & Jadwal Transfer — Jadwal rutin yang jatuh tempo masuk antrean untuk Konfirmasi, Edit, atau Lewati (dengan Urungkan) dari Beranda maupun halaman Berulang, dilengkapi edit jadwal, dukungan Transfer, Catat sekarang, dan Lewati jatuh tempo.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Home Quick Actions & Itemized Debt Payment History — Added a 4-shortcut Quick Actions bar on Home (with live pending badge), unified empty state CTAs in Debts and Goals, and itemized Payment History with atomic delete/Undo on Debt details.',
          textId: 'Aksi Cepat Beranda & Riwayat Cicilan Utang — Menambahkan bilah 4 Aksi Cepat di Beranda (dengan lencana antrean), tombol ajakan seragam di Utang dan Target, serta Riwayat Pembayaran terperinci lengkap dengan hapus & Urungkan pada detail Utang.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.8.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Smart Daily Quota Breakdown — Recalibrated Daily Financial Pulse to deduct upcoming recurring bills, avoid false "Limit" warnings when spending from existing account balances, and show an interactive formula breakdown inside the guide sheet.',
          textId: 'Rincian Kuota Harian Cerdas — Menyempurnakan Daily Financial Pulse agar menyisihkan tagihan berulang mendatang, mencegah status "Batas" keliru saat memakai saldo rekening yang tersedia, serta menampilkan rincian rumus perhitungan di lembar panduan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Debt Editing, Template Removal & Dedicated Categories — Added editing for debt records, a dedicated full-settlement confirmation prompt, one-tap deletion for saved transaction templates, and dedicated system categories for Admin Fees and Savings Deposits/Withdrawals.',
          textId: 'Edit Utang, Hapus Template & Kategori Khusus — Menambahkan edit catatan utang, konfirmasi pelunasan penuh tersendiri, hapus cepat template transaksi tersimpan, serta kategori bawaan khusus untuk Biaya Admin dan Setoran/Penarikan Tabungan.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Core Financial Accuracy & Custom Payday Fixes — Fixed Need/Want tag persistence on transaction save/edit, repaired monthly Insights chart bucketing across custom payday cycles (firstDayOfMonth), unified Account transfers onto TransactionForm, and cleaned up Enchanted Glasshouse color tokens.',
          textId: 'Perbaikan Akurasi Keuangan & Siklus Gajian Kustom — Memperbaiki penyimpanan label Need/Want pada transaksi, memperbaiki pengelompokan grafik Analisis untuk tanggal gajian kustom, menyatukan alur transfer antar akun, dan merapikan token warna Enchanted Glasshouse.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.7.3',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Build Pipeline & AGP Compatibility — Upgraded the Android Gradle Plugin to 9.1.1 so release builds remain compatible with the latest Flutter stable SDK.',
          textId: 'Kompatibilitas Pipeline Build & AGP — Memperbarui versi Android Gradle Plugin ke 9.1.1 agar build rilis tetap kompatibel dengan Flutter stable SDK terbaru.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.7.2',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Quick Finance Widget Enchanted Glasshouse Redesign — Redesigned the Home Screen Widget and floating Quick Transaction dialog to seamlessly match Wall o\' Pay\'s Enchanted Glasshouse visual identity, pairing HeroCard emerald-to-moss glassmorphism, Dew Mint specular rims, subtle conservatory botanical accents, unified Emerald Leaf segmented tabs with vector icons, tabular monetary typography, AppChip-styled preset and selector pills, and dynamic TransactionForm Save CTA gradients across all widget sizes.',
          textId: 'Desain Ulang Enchanted Glasshouse Widget Quick Finance — Memperbarui tampilan Widget Layar Beranda dan dialog Quick Transaction agar konsisten sepenuhnya dengan identitas visual Enchanted Glasshouse Wall o\' Pay: latar kaca Deep Forest menuju Moss Shadow bergaya HeroCard, bingkai refraksi Dew Mint, aksen botani konservatori yang subtil, bilah tab segmented Emerald Leaf terpadu dengan ikon vektor, angka tabular, chip nominal & pemilih bergaya AppChip, serta gradien tombol simpan dinamis mengikuti gaya TransactionForm di berbagai ukuran widget.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.7.1',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Quick Finance Widget Direct Launch & Compatibility Fix — Replaced broadcast activity trampolines with direct PendingIntent.getActivity bindings so tapping Detail or the nominal area opens the floating Quick Transaction dialog reliably across Android 12–16 and MIUI/HyperOS without redirecting to the main app, plus automatic widget rebinding on app update, boot, and locale change.',
          textId: 'Perbaikan Peluncuran Langsung & Kompatibilitas Widget Quick Finance — Mengganti alur broadcast dengan PendingIntent.getActivity langsung agar mengetuk Detail atau area nominal selalu membuka dialog melayang Quick Transaction secara andal di Android 12–16 serta MIUI/HyperOS tanpa dialihkan ke aplikasi utama, sekaligus pembaruan widget otomatis setelah pembaruan aplikasi, boot, dan perubahan bahasa.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.7.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Direct Home Screen Quick Finance Recording & Floating Dialog — Record Income, Expense, and Transfer transactions directly on the Home Screen widget using preset amounts (+10k/+20k/+50k/+100k) and category/wallet chips, or open the translucent floating Quick Transaction dialog for custom nominal & descriptions without launching the main app, with automatic two-way Drift SQLite & cloud synchronization.',
          textId: 'Pencatatan Langsung dari Widget Home Screen & Dialog Melayang — Catat transaksi Pemasukan, Pengeluaran, dan Transfer langsung dari widget layar utama menggunakan chip nominal cepat (+10k/+20k/+50k/+100k) serta pemilih kategori/akun, atau buka dialog melayang transparan untuk nominal kustom & keterangan tanpa membuka aplikasi utama, lengkap dengan sinkronisasi otomatis ke Drift SQLite dan cloud.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.6.0',
      dateEn: 'November 12, 2026',
      dateId: '12 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Quick Finance Android Home Screen Widget (Enchanted Glasshouse) — Integrated an interactive Android Home Screen App Widget allowing instant recording of Income, Expense, or Transfer transactions directly from your home screen. Crafted in signature Enchanted Glasshouse styling with real-time balance sync and privacy sensor masking.',
          textId: 'Widget Home Screen Android Keuangan Cepat (Enchanted Glasshouse) — Menghadirkan App Widget interaktif pada layar utama Android untuk mencatat transaksi Pemasukan, Pengeluaran, atau Transfer secara instan langsung dari beranda ponsel. Dirancang dengan identitas visual Enchanted Glasshouse lengkap dengan sinkronisasi saldo waktu nyata dan sensor privasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.6',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Freeform Transparent Android Home Screen Launcher Icon (Nesty Style) — Removed mipmap-anydpi-v26 adaptive icon wrapper to match the exact transparent icon configuration of the Nesty project. Android launchers (including Xiaomi/POCO Launcher) now render the transparent PNG launcher icon directly on the home screen wallpaper with zero background plates, masks, or container boxes.',
          textId: 'Ikon Launcher Home Screen Android Transparan Bebas (Gaya Nesty) — Menghapus pembungkus adaptive icon mipmap-anydpi-v26 agar sama persis dengan konfigurasi ikon transparan pada proyek Nesty. Launcher Android (termasuk Xiaomi/POCO Launcher) kini menampilkan ikon launcher PNG transparan secara langsung di atas wallpaper layar utama tanpa piringan latar belakang, mask, maupun kotak pembungkus.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Enchanted Glasshouse Typography & Asset Hygiene — Standardized FilledButton to use DM Sans, removed unused Plus Jakarta Sans web font, and purged obsolete legacy hybrid assets.',
          textId: 'Penyelarasan Tipografi & Pembersihan Aset Enchanted Glasshouse — Menyelaraskan FilledButton menggunakan DM Sans, menghapus impor font web Plus Jakarta Sans yang tidak terpakai, dan membersihkan aset usang tema hybrid.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.5',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Transparent Android Launcher Icons & Adaptive Layer Optimization — Replaced the dark green background container box with transparent background (#00000000) for Android adaptive icons. Configured authentic transparent PNG assets (assets/images/logo_foreground.png for adaptive foreground and assets/images/logo.png for legacy mipmaps) with calibrated 10% safe area inset to eliminate clipping on circular, squircle, and rounded rectangular OEM launcher masks while preserving the original Enchanted Glasshouse brand identity.',
          textId: 'Ikon Launcher Android Transparan & Optimasi Layer Adaptif — Mengganti kotak background hijau gelap dengan konfigurasi background transparan (#00000000) untuk adaptive icon Android. Menggunakan aset PNG transparan asli (assets/images/logo_foreground.png untuk adaptive foreground dan assets/images/logo.png untuk mipmap legacy) dengan inset safe area 10% terkalibrasi guna mencegah pemotongan pada berbagai mask launcher OEM (lingkaran, squircle, dan rounded rectangle) serta mempertahankan identitas visual Enchanted Glasshouse asli.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.4',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Enchanted Glasshouse Profile Card for Settings Page — Designed and implemented a bespoke botanical glassmorphism profile card in the Settings screen. Features a horizontal rounded card (22px) with Moss Shadow & Glasshouse Green gradient, circular avatar with botanical glass frame, Outfit SemiBold user name, DM Sans email/handle, a frosted emerald "Personal Account" pill badge, an edit profile button at the top-right, and specular greenhouse architectural sheen lines.',
          textId: 'Kartu Profil Pengguna Enchanted Glasshouse untuk Halaman Pengaturan — Merancang dan mengimplementasikan kartu profil pengguna botanical glassmorphism kustom pada layar Pengaturan. Menghadirkan kartu horizontal bersudut tumpul (22px) dengan gradien Moss Shadow & Glasshouse Green, avatar melingkar berbingkai kaca botani, nama pengguna Outfit SemiBold, email/username DM Sans, badge pill "Personal Account" beraksen mint, tombol edit profil di sudut kanan atas, serta garis arsitektur dan kilau kaca conservatory.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.3',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Enchanted Glasshouse App Launcher Icons & Web Favicons — Regenerated all launcher icons across Android (mipmap & adaptive background #10251F), iOS (AppIcon.appiconset), Windows, and Web. Generated crisp multi-resolution favicons (favicon.ico, favicon.png), apple-touch-icon, and icon.png for the documentation and landing page.',
          textId: 'Ikon Launcher Aplikasi & Favicon Web Enchanted Glasshouse — Memperbarui seluruh ikon launcher aplikasi di Android (mipmap & adaptive icon dengan latar #10251F), iOS (AppIcon.appiconset), Windows, dan Web. Menghasilkan favicon multi-resolusi yang tajam (favicon.ico, favicon.png), apple-touch-icon, dan icon.png untuk dokumentasi dan landing page web.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.2',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Minimalist Clean 3D Botanical Navigation Bar — Streamlined the bottom navigation bar by removing the enclosed glass pill container around active tabs. The bespoke 3D botanical icons now breathe freely on the dark canvas, illuminating with smooth AnimatedOpacity to full brilliance (1.0) and bold dewMint typography when active, while resting gracefully at 0.38 opacity when passive.',
          textId: 'Penyederhanaan Bersih Bilah Navigasi 3D Botani — Merapikan bilah navigasi bawah dengan meniadakan wadah pil kaca di sekitar tab aktif. Ikon 3D botani kustom kini tampil lebih lega dan leluasa tanpa bingkai kotak, menyala penuh (1.0) secara halus dengan AnimatedOpacity dan tipografi tegas dewMint saat aktif, serta bersandar tenang pada transparansi 0.38 saat pasif.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.1',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified 100% 3D Botanical Glasshouse Navigation Bar — Replaced the mixed Material line icons on unselected tabs with consistent 3D botanical glass icons across all states (Home, Transactions, Budget, Insights). Passive tabs now render with an elegant, soft opacity (0.38) and freshSage labels, while the active tab glows with full opacity, an animated translucent dewMint glass pill container, and vibrant mint typography.',
          textId: 'Penyelarasan 100% Ikon 3D Botani pada Bilah Navigasi Bawah — Menghilangkan percampuran antara ikon garis bawaan dan ikon kustom dengan menerapkan ikon 3D botani kustom secara seragam di seluruh tab (Beranda, Transaksi, Anggaran, Analisis) baik dalam status aktif maupun pasif. Tab pasif tampil redup lembut (transparansi 0.38) dengan label freshSage, sementara tab aktif menyala penuh dengan wadah pil kaca dewMint berpendar animasi dan tipografi mint tegas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.5.0',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Enchanted Glasshouse Visual Identity Splash Screen — Added dedicated mobile splash screen featuring a modern minimalist botanical glassmorphic theme. Displays a custom combination logo with a vaulted conservatory architectural arch enclosing a flourishing financial sprout with radiant dew droplet, high-contrast Outfit SemiBold and DM Sans typography, signature tagline "Grow Your Financial Habits.", and glowing minimalist loading capsule. Powered by EnchantedGlasshouseBackgroundPainter with subtle conservatory ceiling trusses, animated natural sunbeam caustics, edge foliage silhouettes, and ethereal floating dew motes. Added native dark launch splash for Android and iOS to prevent white-screen cold-boot flicker.',
          textId: 'Layar Pembuka (Splash Screen) Identitas Visual Enchanted Glasshouse — Menambahkan layar pembuka aplikasi mobile bertema botanical glassmorphism modern minimalis. Menampilkan simbol kombinasi (combination logo) lengkungan arsitektur rumah kaca modern dengan tunas botani finansial bertumbuh di dalamnya, tipografi kontras tinggi Outfit SemiBold & DM Sans Regular, slogan "Grow Your Financial Habits." (Tumbuhkan Kebiasaan Finansialmu), dan kapsul indikator pemuatan minimalis berpendar. Didukung oleh EnchantedGlasshouseBackgroundPainter dengan struktur atap kaca konservatori, bias sinar matahari alami animasi, siluet dedaunan tepi, dan butiran embun berpendar. Ditambah konfigurasi native splash gelap untuk Android dan iOS demi mencegah kedipan layar putih saat cold boot.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Silky smooth transition from splash sequence to authentication and dashboard gates upon initialization, preserving instant bypass for pending shortcuts.',
          textId: 'Transisi lembut dari layar pembuka menuju gerbang autentikasi dan dashboard utama setelah proses inisialisasi selesai, dengan jalan pintas instan untuk aksi cepat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.13',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 7 UI Redesign: Profile, Settings, Security, & Onboarding — Modernized Profile Page with dark moss surfaces, specular dewMint accents, and polished WhatsApp-style photo bottom sheet with circular action containers; refined About Wall o\' Pay sheet with botanical glasshouse identity and high-contrast typography; upgraded Settings & More hubs with high-contrast avatars, specular icon badges, and glowing chevrons; enhanced Security & Lock screens with specular biometric containers and high-contrast circular PIN keypad; polished Auth and Onboarding flows with botanical green CTA buttons and high-contrast step indicators.',
          textId: 'Perombakan UI Fase 7: Profil, Pengaturan, Keamanan, & Onboarding — Pembaruan Halaman Profil dengan permukaan moss gelap, aksen dewMint reflektif, dan bottom sheet foto profil gaya WhatsApp dengan kontainer aksi melingkar; penyempurnaan lembar Tentang Wall o\' Pay dengan identitas botanical glasshouse dan tipografi kontras tinggi; peningkatan Pusat Pengaturan & Menu Lainnya dengan avatar kontras tinggi, badge ikon berbingkai reflektif, dan chevron berpendar; penyempurnaan Halaman Keamanan & Layar Kunci dengan wadah biometrik reflektif dan keypad PIN melingkar berkontras tinggi; polesan alur Masuk dan Onboarding dengan tombol aksi utama hijau botani dan indikator langkah berkontras tinggi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.12',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Consistent Account & Wallet Icons — Resolved icon mismatch in "Accounts & Wallets" where Digital Bank displayed default outline icons while others rendered bespoke 3D glass icons. All account kinds (Commercial Bank, Digital Bank, E-Wallet, Cash) and transfer records now render bespoke 3D Enchanted Glasshouse icons seamlessly.',
          textId: 'Penyelarasan Ikon Akun & Rekening — Memperbaiki inkonsistensi ikon di "Akun & Rekening" di mana Bank Digital sempat menampilkan ikon outline bawaan sementara akun lain memakai ikon 3D botani kustom. Seluruh kategori akun (Bank Konvensional, Bank Digital, E-Wallet, Tunai) serta mutasi transfer kini seragam menampilkan ikon 3D Enchanted Glasshouse.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.11',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 6 UI Redesign: Financial Utilities & Supporting Modules — Modernized Accounts Page with glowing mint icons, distinct category count pills, tabular figures, and teal transfer cards; refined Categories Page with specular borders and elevated buttons; upgraded Debts Page with SegmentedButton toggles and high-contrast settled/left badges; polished Goals Page with tabular progress metrics and deposit action buttons; enhanced Recurring Bills Page with glowing schedule badges and tabular income/expense indicators.',
          textId: 'Perombakan UI Fase 6: Modul Finansial Pendukung (Akun, Kategori, Hutang, Target, & Berulang) — Pembaruan Halaman Akun dengan ikon mint berpendar, pill jumlah kategori, angka tabular, dan kartu transfer teal; penyempurnaan Halaman Kategori dengan garis reflektif dan tombol terangkat; modernisasi Halaman Hutang dengan toggle SegmentedButton dan badge status lunas berkontras tinggi; polesan Halaman Target Impian dengan metrik progres tabular dan tombol tambah dana; penyempurnaan Halaman Transaksi Berulang dengan badge jadwal pendar dan indikator pemasukan/pengeluaran tabular.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.10',
      dateEn: 'November 11, 2026',
      dateId: '11 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 5 UI Redesign: Insights Page & Custom Chart Styling — Redesigned Net Balance card with glowing surplus/deficit badges and tabular metrics, modernized period comparison with reduced spending badges, upgraded expense and trend charts with dark glass tooltips and high-contrast colorways, refined Needs vs Wants card with jewel tones, and enhanced top category rows with rank pills.',
          textId: 'Perombakan UI Fase 5: Halaman Analisis & Penyesuaian Grafik — Pembaruan kartu Saldo Bersih dengan badge surplus/defisit berpendar dan angka tabular, kartu perbandingan periode dengan badge penghematan pengeluaran, grafik batang pengeluaran dan tren dengan tooltip dark glass dan kontras tinggi, kartu Kebutuhan vs Keinginan bertema jewel tone, serta baris kategori teratas dengan pill peringkat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.9',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 4 UI Redesign: Budget Page & 50/30/20 Pillars — Redesigned Total Budget card with tabular currency figures, elevated 50/30/20 preview bar with jewel tones, refreshed Rollover banner with glowing mint accents, upgraded BudgetPillarCard with high-contrast text and specular borders, and restyled CategoryBudgetSheet and TotalBudgetDialog with dark glass aesthetics.',
          textId: 'Perombakan UI Fase 4: Halaman Anggaran & Pilar 50/30/20 — Pembaruan kartu Total Anggaran dengan angka tabular, bilah pratinjau 50/30/20 warna jewel tone, banner Sisa Anggaran Bergulir (Rollover) beraksen mint bercahaya, kartu pilar anggaran berbingkai kaca reflektif, serta lembar bottom sheet dan dialog pengaturan anggaran bernuansa dark glass.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.8',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 3 UI Redesign: Transactions Page & Interactive Cashflow Telemetry — Enhanced search bar with frosted glass surface, upgraded filter chips with tactile icons, elevated account & category dropdown pills with Dew Mint borders, added daily net cashflow badges on date headers, and polished interactive Cashflow Calendar with dual glowing indicators.',
          textId: 'Perombakan UI Fase 3: Halaman Riwayat Transaksi & Telemetri Arus Kas — Pembaruan bilah pencarian berkaca frosted, chip filter dengan ikon taktil, tombol dropdown akun & kategori bergaris tepi Dew Mint, penambahan badge arus kas bersih harian pada header tanggal, serta penyempurnaan Kalender Arus Kas interaktif.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.7',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Scoped Atmospheric Canopy Exclusively to Main Tabs: Reserved the atmospheric header canopy and BotanicalBackgroundSheet for primary tabs (Home, Transactions, Budget, and Insights), introducing clean secondaryAppBar styling and removing decorative sheet overlays for all secondary screens.',
          textId: 'Pemusatan Kanopi & Lembar Botani Khusus Tab Utama: Membatasi kanopi atmosferik dan BotanicalBackgroundSheet hanya untuk 4 tab utama (Beranda, Transaksi, Anggaran, Analisis), serta menerapkan secondaryAppBar yang bersih dan minimalis tanpa distraksi visual pada seluruh halaman sekunder.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.6',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Atmospheric Header Canopy Depth & Separation: Darkened the header backdrop gradient across HomePage and pageAppBar to provide distinct atmospheric depth and clear visual separation from the content sheet.',
          textId: 'Peningkatan Kedalaman & Pemisahan Kanopi Header: Menggelapkan latar belakang header pada Beranda dan pageAppBar untuk memberikan kedalaman atmosferik serta pembeda yang tegas dengan lembaran konten di bawahnya.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.5',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Harmonized Enchanted Glasshouse Header & Atmospheric Background Across All Pages: Brought the sunlit conservatory canopy header and atmospheric multi-stop gradient background with precision botanical foliage to all application pages.',
          textId: 'Penyelarasan Header & Latar Belakang Rumah Kaca di Seluruh Halaman: Menerapkan kanopi berkilau matahari pada header serta latar belakang gradien atmosferik dan dedaunan botani presisi ke seluruh halaman aplikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.4',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 2 UI Redesign: Add / Edit Transaction Modal & Glass Keypad. Translucent glass calculator sheet with high-contrast figures, specular borders, 3D botanical glasshouse icon integration in AppChip, and elevated transaction bottom sheet.',
          textId: 'Perombakan UI Fase 2: Modal Tambah/Edit Transaksi & Keypad Kaca. Kalkulator kaca transparan dengan kontras tinggi, border specular, integrasi ikon 3D glasshouse pada AppChip, dan bottom sheet transaksi yang disempurnakan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.3',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'High-Precision Botanical Foliage & Conservatory Backdrop: Redesigned botanical painter with 30+ meticulously detailed ovate leaves, midribs, lateral veins, cascading ivy garlands, and authentic photorealistic conservatory foliage backdrop.',
          textId: 'Dedaunan Botani Presisi Tinggi & Latar Konservatori: Menggambar ulang painter botani dengan 30+ helai daun oval berurat presisi, juntaian tanaman merambat, dan latar belakang daun konservatori fotorealistik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.2',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Atmospheric Glasshouse Background: Replaced solid dark background canvas with an atmospheric multi-stop vertical gradient, soft sunbeam glow, conservatory vaulted glass arches, and calibrated botanical leaf silhouettes.',
          textId: 'Latar Belakang Rumah Kaca Atmosferik: Mengganti warna kanvas solid polos dengan gradasi vertikal multi-stop, pendar cahaya matahari lembut, lengkungan kubah kaca konservatori, dan siluet daun botani berembun.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.1',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Phase 1 UI Redesign Benchmark (Dashboard / Home): Upgraded header with frosted glass action buttons, elevated DailyFinancialPulseCard with translucent emerald glass depth and specular highlights, polished flow tiles and quick accounts bar.',
          textId: 'Fase 1 Redesign UI Benchmark (Dashboard / Home): Menyempurnakan header dengan tombol kaca buram, mengangkat DailyFinancialPulseCard dengan kedalaman kaca zamrud dan highlight spekular, serta memoles tile arus kas dan bar dompet cepat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.4.0',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Enchanted Glasshouse Visual Identity: Remade the botanical aesthetic into a modern enchanted conservatory with translucent glass surfaces, specular glass highlights, 24 bespoke 3D botanical glass icons, and vaulted glasshouse architectural accents.',
          textId: 'Identitas Visual Enchanted Glasshouse: Me-remake estetika botani menjadi suasana rumah kaca magis modern dengan permukaan kaca transparan, highlight spekular kaca, 24 ikon 3D botanical glass, dan aksen arsitektur kubah konservatori.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Atmospheric Conservatory Lock Screen & Glass Avatar Frame: Implemented serene glasshouse background with ambient lighting on LockScreen and an intricate botanical glass wreath frame for profile photos.',
          textId: 'Layar Kunci Konservatori & Bingkai Kaca Profil: Menghadirkan latar rumah kaca dengan pencahayaan lembut pada Layar Kunci serta bingkai karangan bunga kaca botani untuk foto profil.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Refined Glasshouse Typography & Palette: Integrated Google Fonts Outfit for headings and DM Sans with tabular figures for financial metrics, alongside the new Enchanted Glasshouse palette (Glasshouse Green, Emerald Leaf, Fresh Sage, Dew Mint, Soft Ivory, and Moss Shadow).',
          textId: 'Tipografi & Palet Warna Glasshouse: Mengintegrasikan Google Fonts Outfit untuk judul dan DM Sans bertabular figures untuk angka finansial, didukung palet warna Enchanted Glasshouse (Glasshouse Green, Emerald Leaf, Fresh Sage, Dew Mint, Soft Ivory, dan Moss Shadow).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.3.0',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Focused Botanical Forest Identity: Retired Cyberpunk mode and dual theme switching to unify Wall o\' Pay 100% around the calm, signature Botanical Forest design system, typography, and iconography.',
          textId: 'Fokus Penuh Identitas Botanical Forest: Menghentikan mode Cyberpunk dan pengalih tema ganda agar Wall o\' Pay sepenuhnya menyatu pada estetika, tipografi, dan ikonografi khas Botanical Forest.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Lighter App Footprint & Backward Compatibility: Removed unused Cyberpunk visual assets, painters, and dictionaries while keeping legacy JSON backups and cloud preference sync compatible.',
          textId: 'Aplikasi Lebih Ringan & Tetap Kompatibel: Menghapus aset visual, painter, dan kamus teks Cyberpunk yang tidak lagi digunakan dengan tetap menjaga kompatibilitas impor cadangan JSON dan sinkronisasi cloud lama.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.0',
      dateEn: 'November 7, 2026',
      dateId: '7 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Android Home Screen Quick Shortcuts & Direct Note Field: Long-press the app icon to immediately record an Expense, Income, or Transfer without unlocking PIN/biometrics, with the Note field now directly accessible on the main form.',
          textId: 'Pintasan Cepat Ikon Beranda & Kolom Catatan Langsung: Tekan-tahan ikon aplikasi untuk langsung mencatat Pengeluaran, Pemasukan, atau Transfer tanpa perlu membuka kunci PIN/biometrik, dilengkapi kolom Catatan langsung di form utama.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Interactive Cashflow Calendar: Toggle the new on-demand calendar heatmap in the Transactions tab to see daily activity dots and filter transactions by date.',
          textId: 'Kalender Arus Kas Interaktif: Buka kalender arus kas di tab Transaksi untuk melihat indikator aktivitas harian dan memfilter transaksi per tanggal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Split Bill Wallet Integration & Frequent Small Purchases Insight: Choose which wallet pays when splitting bills, and spot recurring micro-expenses ("Latte Factor") in Insights.',
          textId: 'Integrasi Dompet Patungan & Deteksi Pengeluaran Kecil Berulang: Pilih rekening pembayaran saat patungan tagihan, serta pantau akumulasi pengeluaran kecil berulang di tab Insight.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.2',
      dateEn: 'November 7, 2026',
      dateId: '7 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Faster Cold Start & Lazy Navigation Tabs: Parallelized startup initialization with 10-year timezone tables and deferred building unvisited navigation tabs until opened.',
          textId: 'Buka Aplikasi Lebih Cepat & Lazy Tab: Memparalelkan inisialisasi awal dengan tabel zona waktu 10-tahunan serta menunda pembuatan tab navigasi yang belum dibuka.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'SQL-Aggregated Wallet Balances & GPU Batching: Computed wallet net flows directly in SQLite without loading all historical transactions into RAM, and batched Cyberpunk grid/scanline paths for smoother GPU frame rendering.',
          textId: 'Agregasi Saldo SQL & Optimasi GPU: Menghitung arus kas dompet langsung di SQLite tanpa memuat seluruh riwayat transaksi ke RAM, serta menggabungkan garis grid Cyberpunk ke satu Path agar render GPU lebih ringan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Smaller APK & Asset Footprint: Losslessly compressed bundled PNG brand assets and removed unused high-resolution image assets from the runtime bundle.',
          textId: 'Ukuran APK & Aset Lebih Ringan: Mengompresi aset gambar PNG secara lossless serta menghapus aset gambar beresolusi besar yang tidak terpakai dari bundel aplikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.1',
      dateEn: 'November 7, 2026',
      dateId: '7 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Restored Authentic v1.11 Botanical Brand Icon: Replaced all launcher and brand assets with the exact signature Botanical Forest artwork from v1.11, removing the 16% foreground inset in Android adaptive icon XML that caused home screen icons to shrink.',
          textId: 'Kembalikan Ikon Botani Otentik v1.11: Mengembalikan seluruh aset ikon dan brand persis seperti versi 1.11, serta menghapus inset foreground 16% pada XML adaptive icon Android yang sebelumnya menyebabkan ikon mengecil di layar beranda.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.0',
      dateEn: 'November 7, 2026',
      dateId: '7 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'WhatsApp-Style Profile Photo Studio: Interactive circular photo cropper with zoom/pan/rotate, full-screen interactive viewer, and direct camera/gallery bottom modal sheet.',
          textId: 'Studio Foto Profil ala WhatsApp: Pemotong foto lingkaran interaktif dengan zoom/geser/putar, penampil layar penuh interaktif, dan modal sheet kamera/galeri langsung.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Cyberpunk HUD Telemetry & Monospace Typography: Integrated Share Tech Mono font across all financial metrics, authentic chamfered beveled geometry, CRT scanlines, and animated money counter.',
          textId: 'Telemetri HUD & Tipografi Monospasi Cyberpunk: Mengintegrasikan font Share Tech Mono pada angka finansial, geometri chamfered bersudut, scanlines CRT, dan animasi counter saldo.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Discreet Theme Switcher in "About Wall o\' Pay": Shifted theme switcher into About sheet with contextual warning dialog, keeping Settings uncluttered.',
          textId: 'Pengalih Tema Minimalis di "Tentang Wall o\' Pay": Memindahkan saklar tema ke lembar Tentang disertai dialog konfirmasi bertema, merapikan halaman Pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Full-Bleed Adaptive Launcher Icon: Scaled Android adaptive icon foreground layer to ~93% viewport with solid pine background, eliminating margins and letterboxing on modern launchers.',
          textId: 'Ikon Peluncur Full-Bleed Adaptif: Menyesuaikan layer foreground ikon adaptif ke ~93% viewport dengan latar hijau hutan, menghilangkan margin kosong pada launcher modern.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Exhaustive Bilingual Localization & Zero Color Leaks: Standardized Indonesian and English terminology across all navigation, filters, and dialogs with zero color leaks in Cyberpunk.',
          textId: 'Standarisasi Lokalisasi Dwibahasa & Bebas Kebocoran Warna: Menyelaraskan istilah Bahasa Indonesia dan Inggris di seluruh navigasi, filter, dan dialog tanpa kebocoran warna di Cyberpunk.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.0.0',
      dateEn: 'November 6, 2026',
      dateId: '6 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'A New Era of Wall o\' Pay: Introduced Cyberpunk Neo-Tokyo theme alongside Botanical Garden with OLED midnight canvas, neon telemetry glowing accents, and hybrid brand identity.',
          textId: 'Era Baru Wall o\' Pay: Menghadirkan tema Cyberpunk Neo-Tokyo mendampingi Botanical Garden dengan kanvas OLED gelap pekat, aksen telemetri neon menyala, dan identitas brand hibrida.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added universal Biometric Unlock (Fingerprint & Face Unlock) alongside the 6-digit PIN and migrated PIN secrets to hardware-backed Android Keystore / iOS Keychain.',
          textId: 'Menambahkan Buka Kunci Biometrik universal (Sidik Jari & Pengenalan Wajah) mendampingi PIN 6 digit serta memindahkan enkripsi PIN ke Android Keystore / iOS Keychain.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Hardened app security with 2,048-iteration HMAC-SHA256 PIN hashing, persistent exponential brute-force lockout, automatic cleanup of export & receipt files on logout, and strict Firestore rules.',
          textId: 'Memperkuat keamanan dengan hashing PIN 2.048 iterasi HMAC-SHA256, penalti brute-force persisten, pembersihan otomatis file ekspor & struk saat logout, serta aturan Firestore ketat.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Major 60/120 FPS UI performance upgrade: GPU RepaintBoundary caching on all custom painters, removed full-screen ShaderMask saveLayer on Home, and lazy SliverList rendering on Transactions.',
          textId: 'Peningkatan performa UI 60/120 FPS (anti nge-frame): caching GPU RepaintBoundary pada seluruh dekorasi latar, penghapusan ShaderMask berat di Beranda, serta rendering SliverList hemat memori di Riwayat Transaksi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.38',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added comprehensive ARCHITECTURE.md developer guide and Bahasa Indonesia docstrings across the entire codebase.',
          textId: 'Menambahkan panduan arsitektur lengkap (ARCHITECTURE.md) dan penjelasan dokumentasi kode di seluruh modul aplikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.37',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Polished Settings page with colorful rounded icon badges and aligned dividers across all sections.',
          textId: 'Mempercantik halaman Pengaturan dengan lencana ikon berwarna dan garis pemisah rapi di seluruh bagian.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.36',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Restructured More Features page into 3 functional category cards with colorful icon badges.',
          textId: 'Menata ulang halaman Fitur Lainnya menjadi 3 kartu kategori fungsional dengan lencana ikon berwarna.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified botanical ambient background across More, Accounts, Settings, Debts, and Goals pages.',
          textId: 'Menyeragamkan background botani ke halaman Fitur Lainnya, Akun, Pengaturan, Utang, dan Impian.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.35',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Increased bottom scroll padding to 96px across all pages so FAB never obstructs content.',
          textId: 'Menaikkan padding bawah daftar menjadi 96px agar tombol + tidak menutupi kartu atau konten.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Applied botanical background glow and subtle leaf contours to Transactions, Budget, and Insights.',
          textId: 'Menerapkan pendaran background botani dan siluet daun halus ke halaman Transaksi, Anggaran, dan Wawasan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Enhanced over-budget indicator with explicit excess amount and high-contrast color.',
          textId: 'Memperjelas indikator anggaran terlampaui dengan nominal kelebihan yang eksplisit dan warna kontras.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Polished exit application confirmation dialog theme contrast.',
          textId:
              'Menyempurnakan kontras tema dialog konfirmasi keluar aplikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.34',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added subtle botanical foliage canopy to headers across all pages and home.',
          textId: 'Menambahkan siluet kanopi daun botani di header seluruh halaman dan beranda.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Refined Total Balance card with subtle emerald aurora glow and topographic contour rings.',
          textId: 'Menyempurnakan kartu Total Saldo dengan pendaran aurora emerald dan garis kontur topografi halus.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Enhanced main background with ambient emerald glow and delicate leaf contours.',
          textId: 'Mempercantik background utama dengan pendaran emerald lembut dan siluet daun tipis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.33',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Balance Card Accounts Shortcut & Quick Preview Bar: Tappable Total Balance header with chevron indicator and an interactive compact bar showing active account avatars and summary beneath the cashflow card.',
          textId: 'Shortcut & Bar Ringkas Akun di Kartu Saldo: Judul Total Saldo interaktif dengan ikon panah serta bar ringkas berisi avatar akun aktif dan ringkasan yang langsung membuka halaman Akun & Rekening.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.32',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Landing Page Modernization & Feature Parity: Overhauled docs landing page with an 8-card feature matrix, dynamic showcase previews for all tabs, 3-block Rupiah mobile mockup, and rate-limit guard.',
          textId: 'Modernisasi Landing Page & Sinkronisasi Fitur: Memperbarui landing page docs dengan matriks 8 kartu fitur riil, preview showcase dinamis per tab, mockup HP Rupiah 3-blok, dan proteksi versi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.31',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Undo Delete via Floating SnackBar: Promptly undo accidental deletion of transactions, transfer entries, debt records, or savings goals right from an interactive SnackBar without losing data.',
          textId: 'Urungkan Hapus via SnackBar: Kembalikan transaksi, transfer, catatan utang, atau target tabungan yang terhapus secara instan lewat tombol "Urungkan" tanpa kehilangan data.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Settings & Payday in JSON Backup: JSON export files now back up app preferences (payday cycle, rollover, reminders) and 50/30/20 budget pools, keeping Guest mode migrations completely intact.',
          textId: 'Pengaturan & Gajian di Backup JSON: Ekspor file JSON kini menyertakan preferensi (tanggal gajian, rollover, pengingat) dan aturan anggaran 50/30/20, aman untuk migrasi pengguna Mode Tamu.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.30',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Side-by-Side Debug & Release Builds: Debug builds now use a separate package ID (.debug) and "Wall o\' Pay (Debug)" label so both Debug and Release apps can coexist on the same phone.',
          textId: 'Instalasi Berdampingan Debug & Release: Build debug kini memakai ID paket terpisah (.debug) dan label "Wall o\' Pay (Debug)" sehingga aplikasi Debug dan Release bisa terpasang bersamaan di satu HP.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.29',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Offline Guest Mode: Continue without an account to track finances 100% offline on your device, complete with local profile & PIN lock support.',
          textId: 'Mode Tamu Offline: Lanjut tanpa akun untuk mencatat keuangan 100% offline di perangkatmu, lengkap dengan profil lokal & kunci PIN.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Seamless Account Linking: Upgrade from Guest Mode to a cloud account anytime with automatic local data migration or cloud-only restore choice.',
          textId: 'Penautan Akun Mulus: Beralih dari Mode Tamu ke akun cloud kapan saja dengan migrasi data lokal otomatis atau opsi pemulihan cloud saja.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.28',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added optional Admin Fee support to Expense transactions with custom nominal entry and quick presets (Free, Rp 1.000, Rp 2.500, Rp 5.000).',
          textId: 'Menambahkan dukungan Biaya Admin opsional pada transaksi Pengeluaran dengan input nominal kustom dan tombol cepat (Gratis, Rp 1.000, Rp 2.500, Rp 5.000).',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Applied tabular figures typography for aligned numerical values, enhanced contrast for income/expense semantic colors, and styled primary action buttons in luminous Sage.',
          textId: 'Menerapkan tipografi tabular figures untuk perataan angka monospaced, meningkatkan kontras warna pemasukan/pengeluaran, dan menyematkan warna Sage kontras tinggi pada tombol aksi utama.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.27',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Consolidated home screen into 3 essential blocks: 1) Total Balance & Cashflow, 2) Unified Financial Health & Period Budget Pulse, 3) Recent Transactions. Removed duplicate accounts card from home.',
          textId: 'Memadatkan halaman utama menjadi 3 blok inti: 1) Saldo & Arus Kas, 2) Kondisi Kesehatan Finansial & Anggaran Terpadu, 3) Transaksi Terakhir. Menghapus kartu akun redundan dari halaman utama.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.26',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Streamlined transaction form with progressive disclosure: core flow (Amount, Category, Account, Save) takes < 5 seconds with zero scrolling; optional details (Date, Notes, Needs/Wants, Receipts) neatly tucked under "More details".',
          textId: 'Menyederhanakan form transaksi dengan progressive disclosure: alur inti (Nominal, Kategori, Dompet, Simpan) selesai dalam < 5 detik tanpa perlu scrolling; detail opsional (Tanggal, Catatan, Kebutuhan/Keinginan, Struk) rapi terlipat di balik "Detail lainnya".',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.25',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added customizable Transfer Admin Fee input with quick presets (Free, Rp 1.000, Rp 2.500, Rp 6.500) and automatic expense deduction from the source wallet.',
          textId: 'Menambahkan kolom input biaya admin transfer yang dapat dikustomisasi bebas lengkap dengan tombol cepat (Gratis, Rp 1.000, Rp 2.500, Rp 6.500) dan pencatatan pengeluaran otomatis dari rekening asal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added automated local due date reminders for debts and receivables (due today or tomorrow H-1) with daily deduplication to keep obligations on track.',
          textId: 'Menambahkan notifikasi lokal pengingat jatuh tempo utang-piutang (jatuh tempo hari ini atau besok H-1) dengan pencegahan duplikasi harian.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.24',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Integrated in-app mini calculator into the transaction form amount field, supporting multi-item receipt additions and bill splitting.',
          textId: 'Menghadirkan kalkulator mini terintegrasi pada kolom nominal transaksi untuk memudahkan penjumlahan nota belanjaan dan patungan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added dedicated "000" triple-zero keypad button and quick amount chips (+000, +10k, +50k, +100k) for lightning-fast Rupiah entry.',
          textId: 'Menambahkan tombol angka "000" (tiga nol instan) pada keypad kalkulator dan chip cepat (+000, +10rb, +50rb, +100rb) di bawah input nominal.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.23',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added dedicated interactive Account and Category filter pills to the Transactions page with real-time summary updates and one-tap reset.',
          textId: 'Menambahkan filter interaktif Rekening dan Kategori di halaman Transaksi lengkap dengan pembaruan total ringkasan dan reset 1-ketuk.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Integrated wallet selection for Savings Goals deposits and withdrawals, automatically synchronizing bank balances with financial targets.',
          textId: 'Mengintegrasikan pilihan rekening pada setoran dan penarikan Impian/Tabungan, menyinkronkan saldo rekening dengan target keuangan secara otomatis.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Added wallet account selector when recording debt and split bill repayments, keeping balances consistent.',
          textId: 'Menambahkan pilihan dompet/rekening saat mencatat pelunasan utang dan patungan agar saldo akun selalu akurat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.22',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Optimized Firestore background auto-sync by removing redundant 60-second polling and full collection fetches, significantly saving quota and battery.',
          textId: 'Mengoptimalkan sinkronisasi cloud dengan menghapus polling 60 detik dan fetch koleksi penuh berulang, sangat menghemat kuota Firestore dan baterai.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified application lifecycle handling into HomeShell, removing duplicate sync triggers from the Home screen.',
          textId: 'Menyatukan manajemen siklus hidup aplikasi ke HomeShell, menghilangkan pemicu sinkronisasi ganda dari layar Beranda.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Updated repository links and theme documentation in README for full consistency.',
          textId: 'Memperbarui tautan repositori resmi dan dokumentasi tema pada README.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.21',
      dateEn: 'November 4, 2026',
      dateId: '4 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Integrated direct Budget navigation into More Features alongside other tools for instant 1-tap access.',
          textId: 'Menambahkan menu Anggaran langsung ke halaman Fitur Lainnya untuk akses instan 1-ketuk.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Removed confusing Active Modules toggles from Settings and More screen; all core modules are always accessible.',
          textId: 'Menghapus toggle Modul Aktif dari Pengaturan dan Fitur Lainnya; semua modul utama kini selalu aktif dan dapat diakses.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Streamlined onboarding by removing module selection step for a faster and friction-free setup.',
          textId: 'Membuat alur onboarding lebih ringkas dengan meniadakan langkah pilih modul.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.20',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Removed Quick Action button row from Home screen to deliver an uncluttered, minimalist dashboard.',
          textId: 'Menghapus deretan tombol Quick Action dari layar Beranda untuk tampilan yang lebih bersih dan minimalis.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Replaced manual header sync button with one-tap More Features hub icon, keeping sync feedback subtle.',
          textId: 'Mengganti tombol sinkronisasi manual di header dengan ikon Fitur Lainnya yang instan dan elegan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added interactive Active Modules summary banner and direct customization button on the More screen.',
          textId: 'Menambahkan banner ringkasan Modul Aktif interaktif dan tombol kustomisasi langsung di halaman Lainnya.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.19',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Modular feature selection step in onboarding allowing new users to customize enabled modules.',
          textId: 'Langkah pemilihan modul pada onboarding awal yang memungkinkan pengguna menyesuaikan fitur yang aktif.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Dynamic Home quick actions and budget dashboard that automatically adapt to active modules.',
          textId: 'Aksi cepat Beranda dan kartu anggaran dinamis yang otomatis menyesuaikan dengan modul yang aktif.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Active Modules & Features sheet accessible from Settings and More menus.',
          textId: 'Lembar kelola Modul & Fitur Aktif yang dapat diakses kapan saja dari menu Pengaturan dan Lainnya.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.18',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Daily Financial Pulse card with human-centered Safe, Caution, and Limit status indicators on Home screen.',
          textId: 'Kartu Status Finansial Harian dengan indikator visual humanis Aman, Waspada, dan Batas pada layar Beranda.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Real-time daily quota tracker comparing today\'s spending velocity against remaining days and budget caps.',
          textId: 'Pelacak kuota harian waktu nyata yang membandingkan laju belanja hari ini terhadap sisa hari dan batas anggaran.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.17',
      dateEn: 'November 3, 2026',
      dateId: '3 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Modern Gaussian blur effect for hidden balances across Home overview and Wallets & Accounts.',
          textId: 'Efek Gaussian blur modern saat menyembunyikan saldo di kartu Beranda dan Kantong & Rekening.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Cleaned up Home balance card header by removing redundant "All Accounts" badge to avoid text collisions.',
          textId: 'Menghapus badge "Semua Rekening" yang redundan di kartu saldo utama agar tampilan lebih bersih dan tidak bertabrakan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.16',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Resolved looping update prompts by dynamically detecting the installed version via native Android PackageManager.',
          textId: 'Mengatasi pop-up pembaruan berulang dengan mendeteksi versi aplikasi terpasang secara dinamis via PackageManager native Android.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.15',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Direct database SQL transaction search, App Switcher Privacy Shield (FLAG_SECURE), and automatic rollover budget.',
          textId: 'Pencarian transaksi langsung SQL database, Pelindung Privasi App Switcher (FLAG_SECURE), dan rollover sisa anggaran otomatis.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Database indexing optimization and modularized Budget & Settings architecture.',
          textId: 'Optimasi indeks database dan modularisasi arsitektur Anggaran & Pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Decommissioned sensitive background notification tracking services and cleaned pending transactions schema.',
          textId: 'Menonaktifkan layanan pelacak notifikasi latar belakang dan membersihkan skema transaksi tertunda.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.14',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Restored smooth native scrolling across all screens by removing dynamic gesture-interrupting listeners.',
          textId: 'Memulihkan responsivitas scroll di seluruh halaman dengan mengembalikan penanganan gestur gulir native.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.13',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified smooth fade scroll transition across all screens in the app for a cohesive, premium experience.',
          textId: 'Menyeragamkan efek transisi scroll pudar halus di seluruh halaman aplikasi agar pengalaman visual konsisten dan mulus.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.12',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed dark theme contrast in About sheet (version badge, quote, headers, and lore icons now brightly legible).',
          textId: 'Memperbaiki kontras tema gelap pada lembar Tentang (badge versi, kutipan, judul, dan ikon kini terlihat jelas).',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Added smooth fade scroll transition at top of Home sheet to prevent abrupt clipping of cards and account chips.',
          textId: 'Menambahkan transisi scroll halus di bagian atas lembar Beranda untuk mencegah elemen terpotong kasar saat digulir.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.11',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed time-based greeting to properly show "Good evening" during midnight and wee hours (00:00 - 04:59) instead of "Good morning".',
          textId: 'Memperbaiki sapaan waktu agar menampilkan "Selamat malam" pada tengah malam dan dini hari (00:00 - 04:59), bukan "Selamat pagi".',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.10',
      dateEn: 'November 2, 2026',
      dateId: '2 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Streamlined Home quick actions with essential workflows (Transfer, Goals, Debts, More) and unified compact period switcher.',
          textId: 'Mengefisienkan aksi cepat Beranda dengan fitur esensial (Transfer, Impian, Utang, Lainnya) dan merampingkan navigasi periode.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Cleaned up duplicate menus between More page (Financial Tools) and Settings page (System Preferences).',
          textId: 'Menata ulang menu tumpang tindih antara halaman Lainnya (Alat Finansial) dan halaman Pengaturan (Preferensi Sistem).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.9',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Cleaned up obsolete repository setup files and orphaned assets.',
          textId:
              'Membersihkan file panduan lama dan aset usang dari repositori.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.8',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Refined Botanical Forest theme contrast with richer night pine canvas (#121D17) and floating emerald cards (#1E3026).',
          textId: 'Menyempurnakan kontras tema Botanical Forest dengan latar hijau pinus yang lebih hidup (#121D17) dan kartu mengapung yang jelas (#1E3026).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.7',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added official Brand Lore & Philosophy section in About Wall o\' Pay sheet and web landing page.',
          textId: 'Menambahkan kisah dan filosofi brand resmi pada menu Tentang Wall o\' Pay dan web landing page.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.6',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Adopted new signature botanical forest brand icon across launcher, in-app branding, and web landing page.',
          textId: 'Menerapkan ikon visual baru bertema botanical forest pada ikon launcher, identitas dalam aplikasi, dan web landing page.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.5',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Hardened account deletion flow by cancelling scheduled notifications and purging all local device flags.',
          textId: 'Menyempurnakan alur hapus akun dengan membatalkan pengingat harian dan membersihkan seluruh penanda lokal.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.4',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Synced all user settings (reminders, rollover, alerts, privacy, onboarding) to Cloud Firestore for seamless multi-device continuity.',
          textId: 'Menyinkronkan seluruh pengaturan akun (pengingat harian, rollover, sensor privasi, onboarding) ke cloud agar tidak perlu setting ulang saat ganti perangkat.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Clarified settings layout between automated real-time Cloud Sync and Manual Backup & Export.',
          textId: 'Menata ulang menu Pengaturan untuk memperjelas perbedaan Sinkronisasi Cloud Otomatis dan Cadangan Manual/Ekspor.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.3',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Restored pure native Android layout without desktop wrapper layers.',
          textId: 'Mengembalikan tata letak murni native Android tanpa wrapper desktop tambahan.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Completed comprehensive bilingual localization across recurring schedules, accounts, and review sheets.',
          textId: 'Melengkapi lokalisasi dwibahasa menyeluruh pada jadwal rutin, akun, dan lembar tinjauan transaksi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.2',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed Onboarding Skip & Finish button transition on desktop and offline mode.',
          textId: 'Memperbaiki tombol Lewati & Selesai pada Onboarding yang macet di desktop dan mode offline.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Persisted offline mode without account so desktop launches do not repeatedly show the Firebase screen.',
          textId: 'Menyimpan preferensi mode offline tanpa akun agar desktop tidak berulang kali memunculkan layar Firebase.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added centered responsive container for desktop and widescreen monitors.',
          textId: 'Menambahkan tata letak responsif terpusat untuk PC/laptop layar lebar.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.1',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added privacy balance visibility toggle (eye icon) on the Accounts page HeroCard.',
          textId: 'Menambahkan tombol sensor privasi saldo (ikon mata) langsung pada kartu Total Saldo di halaman Akun.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.0',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added structured account categories: Commercial Bank, Digital Bank, E-Wallet, and Cash with section subtotals and counts.',
          textId: 'Pengelompokan akun ke dalam kategori terstruktur: Bank Konvensional, Bank Digital, E-Wallet, dan Tunai lengkap dengan subtotal dan jumlah akun.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Automatic balance-descending ordering within each category for a clean, frictionless financial overview.',
          textId: 'Pengurutan otomatis berdasarkan saldo terbesar di tiap kategori untuk pengalaman finansial yang bersih dan rapi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.10.0',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added drag-and-drop customization for accounts in Accounts page, allowing custom ordering across the entire app.',
          textId: 'Menambahkan fitur drag-and-drop untuk mengatur dan mengkustomisasi urutan akun di halaman Akun dan seluruh aplikasi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Added interactive grip handles on account cards and seamless offline storage for preferred order.',
          textId: 'Menambahkan pegangan geser interaktif pada kartu akun serta penyimpanan urutan preferensi secara offline.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.9.2',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Synchronized Total Balance to strictly equal the sum of active accounts listed in Your Accounts.',
          textId: 'Menyelaraskan Total Saldo agar benar-benar persis sama dengan total penjumlahan uang pada daftar Akun Anda.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Streamlined account balance input: simplified label to "Balance" showing real-time current balance instead of starting balance.',
          textId: 'Penyederhanaan input saldo akun: mengganti label menjadi "Saldo" yang menampilkan saldo riil saat ini (bukan saldo awal).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.9.1',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Refined Home header layout: dynamic greeting on top and prominent username below without truncation.',
          textId: 'Penyempurnaan tata letak header Beranda: sapaan ramah di atas dan nama pengguna tebal di bawah tanpa terpotong.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Unified Transactions page header: date switcher placed inside curved green app bar consistent with Budget and Insights.',
          textId: 'Penyelarasan header halaman Transaksi: pemilih rentang tanggal disematkan di header hijau melengkung seragam dengan Anggaran dan Wawasan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.9.0',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Dedicated Accounts management page with balances, inter-account transfers, and transaction history.',
          textId: 'Halaman manajemen Akun khusus dengan rincian saldo, transfer antar rekening, dan riwayat transaksi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: '3-Tab Insights layout (Overview, Categories, Trend) with 6-period historical trend table.',
          textId: 'Tampilan Wawasan 3 tab (Ringkasan, Kategori, Tren) dengan tabel perbandingan tren 6 periode.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Income & Expense summary tiles on Transactions page and positive action EmptyStateCards.',
          textId: 'Ringkasan Pemasukan & Pengeluaran di halaman Transaksi serta EmptyStateCard dengan ajakan positif.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Curved sheet headers across Home, Budget, and Insights for a polished, cohesive aesthetic.',
          textId: 'Header lembar melengkung di Beranda, Anggaran, dan Wawasan untuk tampilan yang elegan dan kohesif.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.7',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      isCurrent: false,
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
                            context.tr("What's new in Wall o' Pay v{version}", {
                              'version': UpdateCheckerService.currentVersion,
                            }),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
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
  const _ReleaseCard({required this.release, required this.isIndonesian});

  final ReleaseEntry release;
  final bool isIndonesian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    const primaryCol = AppColors.deepForest;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: release.isCurrent
              ? primaryCol.withValues(alpha: 0.45)
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
                  color: release.isCurrent ? primaryCol : null,
                ),
              ),
              const SizedBox(width: 8),
              if (release.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryCol,
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
          ...release.changes.map(
            (item) => _ChangeItemRow(item: item, isIndonesian: isIndonesian),
          ),
        ],
      ),
    );
  }
}

class _ChangeItemRow extends StatelessWidget {
  const _ChangeItemRow({required this.item, required this.isIndonesian});

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
