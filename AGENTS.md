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

### Aturan Penomoran Versi (Semantic Versioning)
- **Major Release (`(+1).0.0+B`)**: Perombakan arsitektur besar, perubahan skema database tanpa backward-compatibility, atau perubahan fundamental pada alur aplikasi.
- **Minor Feature (`X.(+1).0+B`)**: Penambahan modul atau fitur baru (contoh: integrasi fitur ekspor baru, penambahan halaman grafik analitik, dukungan multi-mata uang).
- **Patch / Bug Fix (`X.Y.(+1)+B`)**: Perbaikan bug, penyesuaian styling UI/tema, perbaikan teks/lokalisasi, atau optimasi performa ringan.

---

## 2. Alur Rilis Otomatis (GitHub Actions Auto Release)
Repositori ini dilengkapi GitHub Actions workflow pada `.github/workflows/release.yml`.
- Setiap kali branch `main` menerima `push` (commit baru):
  1. Workflow akan membaca nomor versi terbaru dari `pubspec.yaml`.
  2. Mengekstrak catatan perubahan untuk versi tersebut dari `CHANGELOG.md`.
  3. Memeriksa apakah GitHub Release untuk tag `vX.Y.Z` sudah ada.
  4. Jika belum ada, GitHub Actions akan melakukan kompilasi APK rilis Flutter (`flutter build apk --release`) dan membuat **GitHub Release** secara otomatis lengkap dengan lampiran file APK dan catatan perubahan (*release notes*).

---

## 3. Standar Kode & Estetika
- **Design Token & Tema**: Gunakan selalu token warna dari `lib/core/theme.dart` (`AppColors.deepForest`, `AppColors.sage`, `AppColors.ivory`, `AppColors.ink`). Hindari warna *hardcoded* sembarangan.
- **Multilingual Support**: Setiap teks antarmuka yang tampil ke pengguna harus didaftarkan di `lib/core/l10n.dart` agar mendukung Bahasa Indonesia dan Bahasa Inggris.
- **Offline-First Integrity**: Database lokal menggunakan Drift SQLite (`lib/data/app_database.dart`). Operasi database harus tetap berfungsi lancar walau perangkat tidak terhubung ke internet. Sinkronisasi Firebase bersifat pelengkap cadangan *cloud*.
- **Web Landing Page (`docs/`)**: Landing page untuk GitHub Pages harus selalu responsif, modern, menggunakan Bahasa Inggris profesional, dan mencerminkan fitur riil yang ada pada aplikasi.
