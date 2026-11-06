# Aturan Proyek Wall o' Pay (AI Agent Guidelines)

Panduan ini wajib dipatuhi oleh seluruh asisten AI (seperti Google Antigravity / Gemini) saat mengembangkan, memodifikasi, dan merilis pembaruan pada repositori **Wall o' Pay**.

---

## 1. Manajemen Versi Aplikasi
Setiap kali melakukan modifikasi kode, penambahan fitur, pembaruan UI, atau perbaikan *bug*, **selalu perbarui (naikkan / bump) nomor versi dan dokumentasikan perubahannya**:

1. **Perbarui Versi di `pubspec.yaml`**:
   - Cari baris `version: X.Y.Z+B` (contoh: `version: 1.0.0+1`).
   - Naikkan nomor versi sesuai kategori perubahan di bawah, dan naikkan *build number* (+1).
2. **Dokumentasikan di `CHANGELOG.md`**:
   - Tambahkan entri rilis baru di paling atas dengan format `## [X.Y.Z] - YYYY-MM-DD`.
   - Gunakan **Bahasa Inggris (English)** mengikuti standar *Keep a Changelog* (kategori: *Added*, *Changed*, *Fixed*, *Removed*).
3. **Sinkronkan Versi pada Dokumentasi**:
   - Perbarui badge versi dan teks terkait di `README.md`.
   - Perbarui teks badge versi dan link download di `docs/index.html` dan variabel `APP_VERSION` di `docs/script.js`.
4. **Sinkronkan Versi pada Layanan & In-App Changelog**:
   - Perbarui konstanta fallback di `lib/data/update_checker.dart` (`fallbackVersion = 'X.Y.Z'`).
   - Tambahkan entri rilis pada `lib/features/settings/app_changelog.dart` (`AppChangelog.releases`) dan tandai versi terbaru dengan `isCurrent: true`.

### Aturan Penomoran Versi (Semantic Versioning)
> [!IMPORTANT]
> **Rilis Mayor v2.0.x**: Versi aplikasi kini berada pada lini `v2.0.x` (dimulai dari `2.0.0+75`).

- **Major Release (`(+1).0.0+B`)**: Perombakan arsitektur besar, perubahan skema database tanpa backward-compatibility, atau perubahan fundamental pada alur aplikasi.
- **Minor Feature (`X.(+1).0+B`)**: Penambahan modul atau fitur baru.
- **Patch / Bug Fix (`X.Y.(+1)+B`)**: Perbaikan bug, penyesuaian styling UI/tema, perbaikan teks/lokalisasi, atau optimasi performa ringan.

---

## 2. Alur Rilis Otomatis (GitHub Actions Auto Release)
Repositori ini dilengkapi GitHub Actions workflow pada `.github/workflows/release.yml`.
- Setiap kali branch `main` menerima `push` (commit baru):
  1. Workflow akan membaca nomor versi terbaru dari `pubspec.yaml`.
  2. Mengekstrak seluruh catatan perubahan dari `CHANGELOG.md` sejak rilis GitHub terakhir (menggabungkan semua versi perantara yang belum pernah dirilis).
  3. Memeriksa apakah GitHub Release untuk tag `vX.Y.Z` sudah ada.
  4. Jika belum ada, GitHub Actions akan melakukan kompilasi APK rilis Flutter (`flutter build apk --release`) dan membuat **GitHub Release** secara otomatis lengkap dengan lampiran file APK dan gabungan catatan perubahan (*release notes*).

**Aturan untuk agent:** Jangan menjalankan `git push` tanpa konfirmasi eksplisit
dari pengguna, dan jangan pernah menggunakan `--force` pada branch `main`.

---

## 3. Standar Kode & Estetika
- **Design Token & Tema**: Gunakan selalu token warna dari `lib/core/theme.dart` (`AppColors.deepForest`, `AppColors.sage`, `AppColors.ivory`, `AppColors.ink`). Hindari warna *hardcoded* sembarangan.
- **Multilingual Support**: Setiap teks antarmuka yang tampil ke pengguna harus didaftarkan di `lib/core/l10n.dart` agar mendukung Bahasa Indonesia dan Bahasa Inggris.
- **Offline-First Integrity**: Database lokal menggunakan Drift SQLite (`lib/data/app_database.dart`). Operasi database harus tetap berfungsi lancar walau perangkat tidak terhubung ke internet. Sinkronisasi Firebase bersifat pelengkap cadangan *cloud*.
- **Web Landing Page (`docs/`)**: Landing page untuk GitHub Pages harus selalu responsif, modern, menggunakan Bahasa Inggris profesional, dan mencerminkan fitur riil yang ada pada aplikasi.

---

## 4. Keamanan & Eskalasi Tugas Sensitif
Karena aplikasi ini menyimpan data keuangan pengguna dan setiap `push` ke `main` otomatis dirilis sebagai APK (lihat Bagian 2), perubahan di area sensitif harus ekstra hati-hati.

**Area sensitif:**
- Autentikasi dan otorisasi (termasuk Firebase Auth)
- Skema Drift SQLite dan migrasi (`lib/data/app_database.dart`), termasuk kenaikan `schemaVersion`
- Sinkronisasi Firebase (Firestore/Realtime Database) dan aturan aksesnya (security rules)
- Penanganan data keuangan atau data pribadi pengguna
- Secret, API key, keystore, `google-services.json`, dan GitHub Secrets pada workflow rilis

**Aturan:**
- Jika tugas menyentuh area sensitif di atas, **berhenti dan beri tahu pengguna terlebih dahulu**
  bahwa tugas ini sebaiknya dikerjakan dengan model yang lebih kuat yang tersedia di akun
  (misalnya Gemini 4 Argon atau Claude Opus 4.6/5.5), dengan effort High, sebelum dilanjutkan.
- Jangan pernah melakukan *hardcode* secret atau API key di kode, dan jangan commit file kredensial (keystore, `.env`, dsb.) ke repositori.
- Setiap perubahan skema database wajib menyertakan migrasi yang aman agar data pengguna yang sudah ada tidak hilang, dan tetap mematuhi prinsip Offline-First.
- Validasi input pengguna sebelum disimpan ke database lokal maupun dikirim ke Firebase.
- Jangan melonggarkan aturan akses Firebase (misalnya membuka baca/tulis publik) tanpa instruksi eksplisit dari pengguna.
- Untuk perubahan di area sensitif, jelaskan alasan tiap keputusan dan daftar kasus uji yang perlu dicek pengguna sebelum di-*push* ke `main`.

---

## 5. Prinsip Coding Umum
Pedoman ini condong ke kehati-hatian dibanding kecepatan. Untuk tugas yang sepele, gunakan penilaian sendiri.

### 5.1 Pikir Dulu Sebelum Coding
- Nyatakan asumsi secara eksplisit. Jika ragu, tanya.
- Jika ada beberapa interpretasi, sajikan semuanya. Jangan memilih diam-diam.
- Jika ada pendekatan yang lebih sederhana, sampaikan dan boleh membantah permintaan bila perlu.

### 5.2 Sederhana Dulu
- Tulis kode seminimal mungkin yang menyelesaikan masalah. Tanpa fitur, abstraksi, atau konfigurasi spekulatif yang tidak diminta.
- Pengecualian: standar di Bagian 3 (design token, l10n, Offline-First) bukan fitur tambahan dan selalu wajib dipenuhi.

### 5.3 Perubahan Bedah
- Jangan "memperbaiki" kode, komentar, atau format di sekitarnya. Ikuti gaya kode yang sudah ada.
- Jika menemukan dead code lama, sebutkan saja dan jangan dihapus. Hapus hanya import/variabel/fungsi yang menjadi tidak terpakai akibat perubahanmu.
- Setiap baris yang berubah harus berkaitan dengan permintaan pengguna, kecuali sinkronisasi versi dan dokumentasi di Bagian 1 yang selalu wajib.

### 5.4 Eksekusi Berorientasi Tujuan
- Tentukan kriteria sukses yang bisa diverifikasi. Jika area terkait sudah punya test, jalankan sebelum dan sesudah perubahan. Minimal jalankan `flutter analyze` sebelum menyatakan tugas selesai.
- Untuk perbaikan bug, jika wajar, buat test yang mereproduksi bug lalu pastikan lulus.
- Untuk tugas multi-langkah, tulis rencana singkat dengan pengecekan di tiap langkah.
