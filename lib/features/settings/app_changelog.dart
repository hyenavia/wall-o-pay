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
      version: '2.1.2',
      dateEn: 'November 7, 2026',
      dateId: '7 November 2026',
      isCurrent: true,
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
          textEn: 'Smaller APK & Asset Footprint: Enabled R8 code/resource shrinking with safe ProGuard rules and optimized bundled PNG assets.',
          textId: 'Ukuran APK & Aset Lebih Ringan: Mengaktifkan pemangkasan kode/resource R8 dengan aturan ProGuard yang aman serta mengoptimalkan aset gambar PNG.',
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
          textEn: 'Polished exit application confirmation dialog theme contrast.',
          textId: 'Menyempurnakan kontras tema dialog konfirmasi keluar aplikasi.',
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
          textEn:
              'Balance Card Accounts Shortcut & Quick Preview Bar: Tappable Total Balance header with chevron indicator and an interactive compact bar showing active account avatars and summary beneath the cashflow card.',
          textId:
              'Shortcut & Bar Ringkas Akun di Kartu Saldo: Judul Total Saldo interaktif dengan ikon panah serta bar ringkas berisi avatar akun aktif dan ringkasan yang langsung membuka halaman Akun & Rekening.',
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
          textEn:
              'Landing Page Modernization & Feature Parity: Overhauled docs landing page with an 8-card feature matrix, dynamic showcase previews for all tabs, 3-block Rupiah mobile mockup, and rate-limit guard.',
          textId:
              'Modernisasi Landing Page & Sinkronisasi Fitur: Memperbarui landing page docs dengan matriks 8 kartu fitur riil, preview showcase dinamis per tab, mockup HP Rupiah 3-blok, dan proteksi versi.',
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
          textEn:
              'Undo Delete via Floating SnackBar: Promptly undo accidental deletion of transactions, transfer entries, debt records, or savings goals right from an interactive SnackBar without losing data.',
          textId:
              'Urungkan Hapus via SnackBar: Kembalikan transaksi, transfer, catatan utang, atau target tabungan yang terhapus secara instan lewat tombol "Urungkan" tanpa kehilangan data.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Settings & Payday in JSON Backup: JSON export files now back up app preferences (payday cycle, rollover, reminders) and 50/30/20 budget pools, keeping Guest mode migrations completely intact.',
          textId:
              'Pengaturan & Gajian di Backup JSON: Ekspor file JSON kini menyertakan preferensi (tanggal gajian, rollover, pengingat) dan aturan anggaran 50/30/20, aman untuk migrasi pengguna Mode Tamu.',
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
          textEn:
              'Side-by-Side Debug & Release Builds: Debug builds now use a separate package ID (.debug) and "Wall o\' Pay (Debug)" label so both Debug and Release apps can coexist on the same phone.',
          textId:
              'Instalasi Berdampingan Debug & Release: Build debug kini memakai ID paket terpisah (.debug) dan label "Wall o\' Pay (Debug)" sehingga aplikasi Debug dan Release bisa terpasang bersamaan di satu HP.',
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
          textEn:
              'Offline Guest Mode: Continue without an account to track finances 100% offline on your device, complete with local profile & PIN lock support.',
          textId:
              'Mode Tamu Offline: Lanjut tanpa akun untuk mencatat keuangan 100% offline di perangkatmu, lengkap dengan profil lokal & kunci PIN.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Seamless Account Linking: Upgrade from Guest Mode to a cloud account anytime with automatic local data migration or cloud-only restore choice.',
          textId:
              'Penautan Akun Mulus: Beralih dari Mode Tamu ke akun cloud kapan saja dengan migrasi data lokal otomatis atau opsi pemulihan cloud saja.',
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
          textEn: 'Cleaned up obsolete repository setup files and orphaned assets.',
          textId: 'Membersihkan file panduan lama dan aset usang dari repositori.',
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
                    Builder(
                      builder: (ctx) {
                        final isCyber = ctx.isCyberpunk;
                        final iconCol = isCyber ? ctx.themeColors.primary : AppColors.deepForest;
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconCol.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_edu_rounded,
                            color: iconCol,
                            size: 24,
                          ),
                        );
                      },
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
    final isCyber = context.isCyberpunk;
    final primaryCol = isCyber ? context.themeColors.primary : AppColors.deepForest;

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryCol,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isIndonesian ? 'TERBARU' : 'LATEST',
                    style: TextStyle(
                      color: isCyber ? const Color(0xFF080912) : Colors.white,
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

