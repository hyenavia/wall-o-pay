# Arsitektur & Panduan Kode Wall o' Pay (`ARCHITECTURE.md`)

Dokumen ini dirancang sebagai **bahan pembelajaran** sekaligus **panduan pemeliharaan (*maintenance*)** untuk proyek **Wall o' Pay**. Di dalamnya terdapat penjelasan menyeluruh mengenai cara kerja aplikasi, alur data, struktur setiap file di dalam folder `lib/`, hingga rumus logika bisnis utama.

---

## 1. Filosofi & Gambaran Besar Arsitektur

**Wall o' Pay** dibangun dengan arsitektur **Offline-First Reactive Architecture** menggunakan:
- **UI Layer:** Flutter (Material 3 dengan tema *Botanical Forest*).
- **State Management:** **Flutter Riverpod** (`Provider`, `StreamProvider`, `NotifierProvider`) untuk menghubungkan database dan preferensi secara reaktif ke antarmuka pengguna.
- **Local Database (Sumber Kebenaran Utama):** **Drift (SQLite)** di `lib/data/app_database.dart` & **SharedPreferences** untuk pengaturan ringan. Aplikasi **100% berfungsi tanpa internet**.
- **Cloud Sync (Pelengkap Cadangan):** **Firebase Auth** & **Cloud Firestore** yang berjalan secara asinkron di latar belakang (`AutoSyncService`) tanpa menghambat interaksi UI.

### Diagram Alur Data Utama

```
┌──────────────────────────────────────────────────────────────────────┐
│                           UI LAYER (Flutter)                         │
│   HomePage, TransactionsPage, BudgetPage, InsightsPage, SettingsPage │
└──────────────────┬────────────────────────────────┬──────────────────┘
                   │ watch() / listen()             │ Aksi Pengguna (Tambah/Ubah/Hapus)
                   ▼                                ▼
┌──────────────────────────────────┐  ┌────────────────────────────────┐
│     STATE / PROVIDER LAYER       │  │   DATABASE & SERVICE LAYER     │
│  providers.dart                  │  │  app_database.dart (Drift SQL) │
│  feature_providers.dart          │◄─┤  prefs.dart / budget_rule.dart │
│  budget_rule.dart                │  │  notifications.dart            │
└──────────────────────────────────┘  └───────────────┬────────────────┘
                                                      │ tableUpdates() / debounce 1.5s
                                                      ▼
                                      ┌────────────────────────────────┐
                                      │      CLOUD SYNC LAYER          │
                                      │  cloud_sync.dart (Firestore)   │
                                      │  Resolusi: Last-Write-Wins     │
                                      └────────────────────────────────┘
```

---

## 2. Alur Masuk Aplikasi (*Startup & Gate Pipeline*)

Saat aplikasi pertama kali dijalankan, eksekusi mengalir secara berurutan melalui "gerbang" (*gates*) berikut:

1. **`main()` (`lib/main.dart`)**
   - Menginisialisasi binding Flutter, format tanggal lokal (`en` dan `id`), zona waktu (`timezone`), dan `NotificationService`.
   - Memuat `SharedPreferences` untuk menentukan bahasa awal (`AppLocale.code`).
   - Menginisialisasi Firebase (`Firebase.initializeApp`), status kunci PIN (`Lock.instance.load()`), dan versi APK (`UpdateCheckerService.getInstalledVersion()`).
   - Membungkus aplikasi dalam `ProviderScope`.

2. **`WallOPayApp` & `_Root` (`lib/app.dart`)**
   - Mengatur tema (`buildTheme()`), lokalisasi (`AppStrings.delegate`), dan menampilkan `SplashPage` selama 1,4 detik sebelum masuk ke `AuthGate`.

3. **`AuthGate` (`lib/app.dart`)**
   - Memeriksa apakah pengguna sudah login ke Firebase Auth atau memilih **Mode Tamu** (`skipAuthProvider`).
   - Jika belum keduanya, menampilkan `AuthPage`. Jika sudah, masuk ke `LockGate`.

4. **`LockGate` (`lib/features/security/lock_screen.dart`)**
   - Memeriksa apakah pengguna mengaktifkan PIN 6 digit (`Lock.instance`).
   - Juga memantau siklus hidup aplikasi (`AppLifecycleState.paused` / `resumed`) untuk mengunci ulang layar secara otomatis setelah aplikasi ditinggalkan sesuai batas waktu (*timeout*).

5. **`OnboardingGate` (`lib/features/onboarding/onboarding_gate.dart`)**
   - Memeriksa apakah pengguna baru pernah menyelesaikan pengenalan awal (`onboarding_done_<uid>`). Jika belum dan belum ada transaksi sama sekali, menampilkan `OnboardingPage`.

6. **`HomeShell` (`lib/app.dart`)**
   - Kerangka utama aplikasi dengan 4 tab navigasi bawah (`HomePage`, `TransactionsPage`, `BudgetPage`, `InsightsPage`) dan tombol tengah (`FloatingActionButton`) untuk mencatat transaksi baru.
   - Menjalankan pengecekan transaksi berulang (`RecurringService.checkAndGenerateDue`), pengingat utang jatuh tempo (`checkDebtDueReminders`), listener *Share Intent* (`ShareService`), dan sinkronisasi otomatis (`AutoSyncService`).

---

## 3. Peta Lengkap Direktori & File (`lib/`)

### A. Root `lib/`
| File | Peran & Tanggung Jawab |
| :--- | :--- |
| `main.dart` | Titik masuk utama aplikasi (`main()`), inisialisasi layanan dasar sebelum UI dirender. |
| `app.dart` | Konfigurasi `MaterialApp`, `AuthGate`, dan kerangka navigasi utama (`HomeShell`). |
| `firebase_options.dart` | File konfigurasi otomatis FlutterFire untuk koneksi ke proyek Firebase. *(Jangan diubah manual)*. |

### B. `lib/core/` — Utilitas Dasar, Tema, & Komponen Bersama
Folder ini berisi kode fondasi yang dipakai di seluruh fitur dan tidak bergantung pada logika bisnis spesifik.

| File | Peran & Tanggung Jawab |
| :--- | :--- |
| `theme.dart` | Definisi palet warna *Botanical Forest* (`AppColors`) dan konfigurasi tema Material 3 (`buildTheme`) dengan tipografi *Plus Jakarta Sans* berfitur *tabular figures* (agar angka sejajar). |
| `botanical_decorations.dart` | `CustomPainter` untuk menggambar ornamen dedaunan dan efek cahaya (*glow*) khas Wall o' Pay pada AppBar (`BotanicalCanopyPainter`), kartu utama (`BotanicalHeroCardPainter`), dan latar belakang (`BotanicalBackgroundPainter`). |
| `brand.dart` | Widget logo aplikasi (`BrandMark`) dan tampilan layar pembuka (`SplashPage`). |
| `format.dart` | Fungsi pemformatan nominal Rupiah (`rupiah`), pemisah ribuan (`formatThousands`, `ThousandsInputFormatter`), format tanggal (`dateLabel`, `shortDate`, `dayHeader`), dan sapaan waktu (`greeting`). |
| `period.dart` | Model `Period` dan `PeriodType` (`monthly` / `weekly`). Menghitung tanggal awal & akhir periode (termasuk dukungan tanggal gajian kustom `firstDayOfMonth` dan hari awal minggu `firstDayOfWeek`), sisa hari (`daysLeft`), serta kunci periode (`key` seperti `2026-11`). |
| `icons.dart` | Peta kunci string ikon ke `IconData` Material (`categoryIcons`) dan daftar palet warna kategori (`categoryColors`). Disimpan sebagai string/int agar aman disimpan di SQLite & Firestore. |
| `l10n.dart` & `l10n_extra.dart` | Sistem lokalisasi dua bahasa (Inggris & Indonesia). Menyediakan extension `context.tr('Key')` untuk widget dan fungsi global `trG('Key')` untuk service tanpa `BuildContext`. |
| `widgets.dart` | Kumpulan widget UI standar proyek: `pageAppBar`, `AppCard`, `HeroCard`, `CategoryBadge`, `AppProgressBar`, `PeriodSwitcher`, `UserAvatar`, `EmptyState`, dan `showUndoSnackBar`. |
| `calculator_sheet.dart` | *Bottom sheet* kalkulator mini (`showCalculatorSheet`) untuk menghitung nominal langsung di dalam form transaksi. |

### C. `lib/data/` — Database Lokal, State Riverpod, & Layanan (*Services*)
Folder ini adalah "otak" penyimpanan dan pengolahan data aplikasi.

| File | Peran & Tanggung Jawab |
| :--- | :--- |
| `tables.dart` | Definisi skema 8 tabel SQLite Drift (`Categories`, `Wallets`, `Transactions`, `Budgets`, `SavingsGoals`, `RecurringRules`, `Debts`, `TxTemplates`) beserta `mixin SyncColumns` (`id`, `createdAt`, `updatedAt`, `deletedAt`). |
| `app_database.dart` | Kelas utama `AppDatabase` (Drift SQLite). Mengelola migrasi skema (`schemaVersion`), data awal (*seed* kategori & dompet), operasi CRUD, *soft-delete* (`deletedAt`), pencarian SQL, ekspor/impor JSON, dan jembatan sinkronisasi `syncTables`. |
| `app_database.g.dart` | Kode hasil *generate* otomatis oleh `build_runner` untuk Drift. *(Jangan diubah manual)*. |
| `providers.dart` | Provider Riverpod inti: instance database, periode terpilih (`selectedPeriodProvider`), sensor saldo (`hideBalanceProvider`), daftar transaksi, kategori, anggaran, serta perhitungan saldo tiap dompet secara *real-time* (`walletBalancesProvider`). |
| `feature_providers.dart` | Provider tambahan: pencarian transaksi SQL (`searchTransactionsProvider`), filter rentang tanggal, dan perhitungan *rollover* sisa anggaran periode sebelumnya (`carryOverProvider`, `effectiveBudgetProvider`). |
| `budget_rule.dart` | Logika dan state penganggaran **50/30/20** (`BudgetBucket`: *Needs*, *Wants*, *Savings*) maupun alokasi nominal kustom per periode (`BudgetRuleNotifier`, `budget503020BreakdownProvider`). |
| `prefs.dart` | Pengaturan personalisasi pengguna (`AppPrefs`: tema, bahasa, tipe periode bulanan/mingguan, hari awal minggu, tanggal gajian) beserta sinkronisasinya ke Firestore (`users/{uid}/meta/preferences`). |
| `feature_prefs.dart` | Pengaturan fitur opsional (`FeaturePrefs`: *rollover* anggaran, peringatan anggaran 80%/100%, dan jam pengingat harian). |
| `module_prefs.dart` | Pengaturan modul fitur yang bisa diaktifkan/dinonaktifkan pengguna (`ModulePrefs`). |
| `profile.dart` | Pengelolaan nama panggilan (*nickname*) dan foto profil (`ProfileController`, disimpan sebagai Base64 di lokal & Firestore), serta `displayNameProvider` untuk sapaan di beranda. |
| `auth_service.dart` | Layanan autentikasi Firebase (`AuthService`): login dengan email **atau** username (melalui koleksi Firestore `usernames`), pendaftaran akun, reset password, dan penghapusan akun permanen beserta seluruh data cloud. |
| `cloud.dart` | Provider status kesiapan Firebase (`firebaseReadyProvider`), stream status login (`authStateProvider`), dan status Mode Tamu (`skipAuthProvider`). |
| `cloud_sync.dart` | Layanan sinkronisasi dua arah otomatis & *real-time* (`AutoSyncService`). Memantau perubahan tabel lokal Drift dan *snapshot* Firestore, menangani *debounce push*, deteksi koneksi internet kembali aktif, serta pergantian akun. |
| `cloud_backup.dart` | Layanan pencadangan & pemulihan manual ke Cloud Firestore (`CloudBackupService` & `CloudBackupController`). |
| `lock.dart` | Layanan keamanan PIN 6 digit dengan *hash* SHA-256 + *salt* acak (`Lock`), sinkronisasi PIN antar perangkat, dan fitur *Privacy Shield* (`FLAG_SECURE` agar layar aplikasi disamarkan di *Recent Apps*). |
| `notifications.dart` | Layanan notifikasi lokal Android (`NotificationService`), pengecekan batas anggaran 80% & 100% (`checkBudgetAfterExpense`), serta pengingat jatuh tempo utang (`checkDebtDueReminders`). |
| `recurring_service.dart` | Kalkulasi tanggal jatuh tempo berikutnya (`calculateNextDueDate`) dan pencatatan otomatis transaksi berulang yang sudah jatuh tempo (`checkAndGenerateDue`). |
| `export_service.dart` | Ekspor riwayat transaksi ke file `.csv` (kompatibel dengan Excel via BOM UTF-8) serta ekspor/impor cadangan penuh `.json`. |
| `report_service.dart` | Pembuatan laporan keuangan formal berformat `.pdf` (`ReportService`) lengkap dengan tabel ringkasan, perincian kategori, *Needs vs Wants*, dan daftar transaksi. |
| `share_service.dart` | Menangani *Share Intent* dari aplikasi lain (misal bukti transfer dari m-banking/e-wallet yang dibagikan ke Wall o' Pay) dan membuka form transaksi secara otomatis. |
| `transaction_parser.dart` | Parser pintar berbasis *RegExp* & kata kunci (`TransactionParser`) untuk mengekstrak nominal Rupiah, mendeteksi aplikasi sumber (BCA, Mandiri, GoPay, dll.), serta menebak kategori dari teks bukti transaksi. |
| `update_checker.dart` | Memeriksa rilis terbaru di GitHub Releases API (`UpdateCheckerService`), membandingkan versi SemVer dengan aplikasi terpasang, dan menampilkan dialog unduh APK baru. |

### D. `lib/features/` — Antarmuka Pengguna per Fitur
Setiap subfolder mewakili satu modul fitur di antarmuka pengguna:

- **`accounts/` (`accounts_page.dart`)**: Halaman daftar dompet/rekening (Bank Konvensional, Bank Digital, E-Wallet, Tunai), form tambah/ubah akun, arsip akun, dan kartu ringkasan akun di Beranda (`AccountsSummaryCard`).
- **`auth/` (`auth_page.dart`)**: Halaman masuk, daftar akun baru, lupa password, pilihan lanjut sebagai Tamu (*Guest*), dan dialog penggabungan data tamu saat login.
- **`budget/`**:
  - `budget_page.dart`: Halaman utama pengelolaan anggaran dengan kartu ringkasan 50/30/20 dan daftar tiga pilar anggaran.
  - `budget_pillar_card.dart`: Widget kartu untuk masing-masing pilar (*Needs*, *Wants*, *Savings*) beserta progres sub-kategorinya.
  - `total_budget_dialog.dart`: Dialog pengaturan total anggaran periode (mode standar 50/30/20 atau alokasi nominal kustom).
  - `category_budget_sheet.dart`: *Bottom sheet* untuk memindahkan kategori ke pilar lain atau mengatur batas anggaran spesifik per kategori.
- **`categories/` (`categories_page.dart`)**: Halaman pengelolaan kategori pengeluaran dan pemasukan (tambah, ubah nama/ikon/warna, atau hapus *soft-delete*).
- **`debts/` (`debts_page.dart`)**: Halaman pencatatan utang (*I owe*) & piutang (*Owed to me*), pencatatan cicilan/pelunasan, serta kalkulator *Split Bill* (patungan bersama teman).
- **`goals/` (`goals_page.dart`)**: Halaman target tabungan (*Savings Goals*), penambahan saldo tabungan, dan daftar target yang sudah tercapai.
- **`home/`**:
  - `home_page.dart`: Halaman beranda utama (sapaan profil, kartu saldo & arus kas periode, pintasan cepat, progres anggaran, dan transaksi terbaru).
  - `daily_financial_pulse_card.dart`: Kartu indikator kesehatan finansial harian (*Safe* / *Caution* / *Limit*) berdasarkan kuota belanja harian yang aman.
- **`insights/`**:
  - `insights_page.dart`: Halaman analitik keuangan dengan 3 tab (*Summary*, *Categories*, *Trend*).
  - `insight_engine.dart`: Mesin kalkulasi analitik deterministik (`InsightEngine`) yang menghitung rasio tabungan, lonjakan kategori dibanding periode lalu, puncak hari belanja, dan rekomendasi pintar (`SmartInsightItem`).
  - `charts.dart`: Widget grafik visual menggunakan `fl_chart` (`ExpensePieChart`, `TrendBarChart`, dan grafik tren pengeluaran).
- **`more/` (`more_page.dart`)**: Halaman pusat navigasi menuju seluruh fitur lengkap aplikasi.
- **`onboarding/` (`onboarding_gate.dart` & `onboarding_page.dart`)**: Alur pengenalan awal 4 langkah untuk mengatur periode, uang tunai awal, uang saku rutin, dan anggaran dasar.
- **`profile/` (`profile_page.dart`)**: Halaman ubah foto profil dan *nickname*.
- **`recurring/` (`recurring_page.dart`)**: Halaman pengelolaan jadwal transaksi berulang & langganan (harian, mingguan, bulanan).
- **`security/` (`lock_screen.dart` & `security_page.dart`)**: Layar kunci PIN 6 digit, alur pembuatan/verifikasi PIN, pengaturan jeda kunci otomatis, dan *Privacy Shield*.
- **`settings/`**:
  - `settings_page.dart`: Halaman pengaturan lengkap (profil, periode, tanggal gajian, bahasa, notifikasi, sinkronisasi cloud, ekspor/impor data, dan info aplikasi).
  - `settings_actions.dart`: Logika aksi tombol sinkronisasi manual, keluar akun (*logout*), dan hapus akun permanen.
  - `report_dialog.dart`: Dialog pemilih rentang tanggal untuk mengekspor laporan PDF.
  - `about_sheet.dart`: *Bottom sheet* informasi filosofi brand dan pengembang Wall o' Pay.
  - `app_changelog.dart`: Data dan tampilan riwayat pembaruan aplikasi (*In-App Changelog*) dalam Bahasa Inggris & Indonesia.
- **`transactions/`**:
  - `transactions_page.dart`: Halaman daftar seluruh transaksi dengan pencarian SQL langsung, filter tipe (pemasukan/pengeluaran/transfer), filter dompet, filter kategori, dan filter rentang tanggal.
  - `transaction_form.dart`: Form input/edit transaksi lengkap dengan template sekali ketuk, kalkulator mini, lampiran foto struk, penanda *Need vs Want*, dan biaya admin transfer.
  - `transaction_tile.dart`: Komponen baris transaksi individual.

---

## 4. Cara Kerja Logika Bisnis Utama (Bahan Belajar)

### A. Mengapa Tidak Ada Kolom `currentBalance` di Tabel `Wallets`?
Jika kamu melihat `Wallets` di `lib/data/tables.dart`, tabel tersebut hanya menyimpan `initialBalance` (saldo awal). Saldo saat ini dihitung secara reaktif di `walletBalancesProvider` (`lib/data/providers.dart`) dengan rumus:
$$\text{Saldo Dompet} = \text{initialBalance} + \sum \text{Income} - \sum \text{Expense} - \sum \text{Transfer Out} + \sum \text{Transfer In}$$
**Keuntungannya:**
- Tidak akan pernah terjadi bug "saldo tidak sinkron" saat transaksi lama diedit, dihapus, atau disinkronkan dari perangkat lain via Cloud Firestore.

### B. Sistem *Soft-Delete* (`deletedAt`) & Resolusi Konflik Cloud
Semua tabel di SQLite menggunakan `mixin SyncColumns` (`id`, `createdAt`, `updatedAt`, `deletedAt`):
- Saat pengguna menghapus transaksi/kategori/dompet, baris tersebut **tidak dihapus dengan `DELETE FROM`**, melainkan kolom `deletedAt` diisi dengan waktu saat ini (`DateTime.now()`), dan `updatedAt` diperbarui.
- Mengapa? Agar saat sinkronisasi ke Cloud Firestore, perangkat lain tahu bahwa item tersebut telah dihapus (karena `updatedAt`-nya lebih baru dan memiliki nilai `deletedAt`), serta memungkinkan fitur **Undo (Urungkan)** dengan mudah (`restoreTransaction`).
- Saat sinkronisasi dua arah (`applyRemote` di `app_database.dart`), berlaku aturan **Last-Write-Wins**: data dari cloud hanya akan menimpa data lokal jika `remote.updatedAt.isAfter(local.updatedAt)`.

### C. Perhitungan *Daily Financial Pulse* (`daily_financial_pulse_card.dart`)
Kartu kesehatan finansial harian di Beranda menghitung **Kuota Harian Aman** (*Safe Daily Quota*):
$$\text{dailyAllowance} = \frac{\text{Pemasukan Periode Ini} - \text{Pengeluaran Periode Ini}}{\text{Sisa Hari dalam Periode (`daysLeft`)}}$$
Lalu menentukan status kesehatan (`DailyHealthTier`):
1. **Limit (Merah):** Jika total pengeluaran sudah mencapai/melebihi anggaran periode (`budgetSpent >= totalBudget`) atau saldo periode defisit (`balance <= 0`).
2. **Caution / Waspada (Kuning):** Jika pemakaian anggaran $\ge 85\%$ atau pengeluaran hari ini melebihi kuota harian aman (`todayExpense > dailyAllowance`).
3. **Safe / Aman (Hijau Sage):** Jika pengeluaran masih di bawah batas aman.

---

## 5. Tips Saat Ingin Memelihara atau Menambah Fitur Baru

1. **Menambah Teks UI Baru:**
   - Gunakan `context.tr('English text')` di dalam widget.
   - Daftarkan terjemahan Bahasa Indonesianya pada peta `_id` di `lib/core/l10n.dart` (atau `idExtra` di `lib/core/l10n_extra.dart`).
2. **Menggunakan Warna:**
   - Selalu gunakan token warna dari `AppColors` di `lib/core/theme.dart` (`AppColors.deepForest`, `AppColors.sage`, `AppColors.income`, `AppColors.expense`, `AppColors.warning`) atau `Theme.of(context).colorScheme`.
3. **Mengubah Skema Database (`tables.dart` / `app_database.dart`):**
   - Tambahkan kolom/tabel di `lib/data/tables.dart`.
   - Jalankan `dart run build_runner build --delete-conflicting-outputs` untuk memperbarui `app_database.g.dart`.
   - Naikkan `schemaVersion` di `AppDatabase` dan tambahkan blok migrasi di `onUpgrade` serta `beforeOpen` (jika perlu *self-healing*).
4. **Merilis Pembaruan:**
   - Ikuti daftar periksa di `AGENTS.md` Bagian 1 (naikkan versi di `pubspec.yaml`, `CHANGELOG.md`, `README.md`, `docs/index.html`, `docs/script.js`, `lib/data/update_checker.dart`, dan `lib/features/settings/app_changelog.dart`).
   - Jalankan `flutter analyze` untuk memastikan tidak ada *warning* atau *error*.

