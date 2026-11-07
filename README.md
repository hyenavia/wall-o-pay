# Wall o' Pay 🌿⚡

<div align="center">

### *Your Money, Under Your Control*
**Modern, Lightning-Fast & Offline-First Personal Finance Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Database](https://img.shields.io/badge/Database-Drift%20SQLite-1E4238?logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Security](https://img.shields.io/badge/Security-Keystore%20%7C%20Biometrics-38B271?logo=android&logoColor=white)](https://github.com/hyenavia/wall-o-pay)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.1.2-234B3B.svg)](CHANGELOG.md)

[🌐 Visit Landing Page](https://hyenavia.github.io/wall-o-pay/) • [📥 Download Latest APK](https://github.com/hyenavia/wall-o-pay/releases/latest) • [📐 Architecture Guide](ARCHITECTURE.md) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Wall o' Pay** is a modern, high-performance personal finance and cashflow tracker built with Flutter. Engineered with a strict **Offline-First Reactive Architecture** powered by Drift SQLite and Flutter Riverpod, the app operates instantaneously with zero network latency and works 100% offline.

When you're ready to back up or sync across devices, Wall o' Pay offers optional, seamless synchronization with Firebase Authentication and Cloud Firestore, backed by hardware-grade encryption on your device.

---

## 🚀 What's New in v2.0 (Major Release)

Version 2.0 brings major architectural enhancements, hardware-grade security, and a dual aesthetic system:

- 🛡️ **Universal Biometric Unlock:** Instant fingerprint and face recognition (`local_auth`) coupled with a 6-digit PIN pad. Authenticate in a fraction of a second when opening the app.
- 🔐 **Hardware-Backed Secret Storage:** Cryptographic migration of PIN hashes, salts, and anti-tamper lockout counters into the **Android Keystore** (`EncryptedSharedPreferences`) and **iOS Keychain** via `FlutterSecureStorage`.
- 🔑 **Key-Stretched Security (v2 Salted HMAC-SHA256):** Upgraded PIN verification to a 2,048-iteration salted HMAC-SHA256 scheme with persistent exponential backoff lockout protection (30s → 120s → 300s).
- 🎭 **Dual Signature Themes:** Choose between the soothing emerald depths of **Botanical Forest** or the high-contrast neon energy of **Cyberpunk Edgerunners**, complete with custom vector canvas decorations.
- ⚡ **60 / 120 FPS Rendering Pipeline:** Optimized vector painters wrapped with `RepaintBoundary(isComplex: true)`, eliminated offscreen `saveLayer` masks, implemented lazy sliver feeds, and introduced 150ms search debounce for buttery-smooth scrolling.
- 🧹 **Anti-Data-Leakage & Privacy Hardening:** Automatic purging of temporary receipt attachments, shared files, and exported documents on logout or data reset, backed by granular Firestore Security Rules.

---

## ✨ Key Capabilities

### ⚡ Offline-First Speed & Privacy
- **Instantaneous 5-Second Logging:** Record income and expenses in seconds with smart auto-categorization and a built-in mini calculator.
- **Guest Mode by Default:** Full access to all features without requiring an internet connection, account creation, or phone number.
- **Privacy Shield:** Your data stays on your device. Zero analytics trackers or invasive third-party SDKs.

### 💳 Multi-Account & Wallets
- **Flexible Account Management:** Track physical cash, bank accounts, and digital e-wallets in one unified view.
- **Inter-Account Transfers:** Transfer funds between wallets with dedicated records and instant balance updates.
- **Accounts Quick Bar:** View your portfolio overview and active wallet balances right from the Home header card.

### 📊 Smart Budgeting & 50/30/20 Rule
- **Period & Category Budgets:** Configure monthly or weekly budgets with custom payday cycle dates.
- **Needs vs. Wants Allocation:** Tag expenses to automatically track your 50/30/20 financial balance.
- **Daily Financial Pulse:** Real-time visual allowance meters with alert indicators when spending crosses 80% and 100% thresholds.

### 🎯 Dedicated Savings Goals
- **Target Tracking:** Set goals for emergency funds, gadgets, travel, or investments.
- **Linked Account Deposits:** Fund savings goals directly from designated wallets with progress percentages and milestone markers.

### 🤝 Debts & Split Bills
- **Lend & Borrow Tracking:** Keep track of who owes whom with due dates and payment status.
- **Partial & Full Repayments:** Log settlement payments seamlessly with one-tap transaction recording.
- **Group Bill Splitting:** Split dining or shared expenses evenly among friends and immediately log your share.

### 📈 Visual Insights & PDF Reports
- **Interactive Charts:** Comprehensive spending trends, category distributions, and income vs. expense breakdowns powered by `fl_chart`.
- **Exportable PDF Reports:** Generate clean, printable PDF financial statements for any custom date range or month.
- **Data Portability:** Export your complete financial history to standard CSV and JSON formats anytime.

### ⏰ Automation & Reminders
- **Recurring Transactions:** Automate recurring subscriptions, bills, salaries, and routine expenses.
- **Quick Transaction Templates:** Save favorite spending routines (e.g., daily coffee, routine lunch) for one-tap entry.
- **Smart Local Notifications:** Customizable daily reminders and budget threshold warnings scheduled directly via device alarms.

### 🌐 Bilingual Localization
- Complete native support for both **English** and **Bahasa Indonesia** with seamless in-app switching.

---

## 🛠️ Technology Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47+ (Stable Channel) | High-performance cross-platform UI |
| **Language** | Dart 3.13+ | Null-safe, modern reactive language |
| **State Management** | Flutter Riverpod (`flutter_riverpod` 3.x) | Predictable, reactive dependency injection |
| **Local Database** | Drift SQLite (`drift`, `drift_flutter`) | Type-safe SQL engine with reactive streams |
| **Hardware Security** | `flutter_secure_storage` & `local_auth` | Android Keystore / iOS Keychain & Biometrics |
| **Cloud & Auth** | Firebase Core, Firebase Auth, Firestore | Optional real-time cloud backup & cross-device sync |
| **Charts & Analytics** | `fl_chart` | Interactive, animated vector charts |
| **Reporting & Export** | `pdf` & `printing` | Custom PDF generation & print-ready statements |
| **Local Notifications**| `flutter_local_notifications` & `timezone` | Offline scheduled notifications & threshold alerts |
| **Typography & Icons** | Plus Jakarta Sans (`google_fonts`) | Material 3 & tabular figures for number alignment |
| **CI / CD Pipeline** | GitHub Actions | Automated release tagging, APK builds, and GitHub Releases |

---

## 📐 Architecture & Data Flow

Wall o' Pay follows a decoupled **Offline-First Reactive Architecture**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          UI LAYER (Flutter 3)                          │
│   HomeShell • Transactions • Budget • Insights • Accounts • Settings   │
└──────────────────┬─────────────────────────────────┬───────────────────┘
                   │ watch() / listen()              │ User Mutations
                   ▼                                 ▼
┌───────────────────────────────────┐  ┌─────────────────────────────────┐
│       RIVERPOD STATE LAYER        │  │     LOCAL DATABASE & STORAGE    │
│  providers.dart                   │  │  app_database.dart (Drift SQL)  │
│  feature_providers.dart           │◄─┤  flutter_secure_storage         │
│  budget_rule.dart                 │  │  shared_preferences            │
└───────────────────────────────────┘  └────────────────┬────────────────┘
                                                        │ Debounced 1.5s
                                                        ▼
                                       ┌─────────────────────────────────┐
                                       │        CLOUD SYNC LAYER         │
                                       │  cloud_sync.dart (Firestore)    │
                                       │  Conflict: Last-Write-Wins      │
                                       └─────────────────────────────────┘
```

> [!NOTE]
> For an in-depth breakdown of every folder, service, and core financial formula, refer to our comprehensive [Architecture Guide (`ARCHITECTURE.md`)](ARCHITECTURE.md).

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.47.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (version 3.13.0 or higher)
- Android Studio / VS Code with Flutter & Dart extensions
- Android device or emulator running Android 8.0+ (API 26+)

### Installation & Local Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hyenavia/wall-o-pay.git
   cd wall_o_pay
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Drift Database code (Code Generation):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run code analysis and tests:**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Launch the application:**
   ```bash
   flutter run
   ```

---

## 📦 Automated Release Pipeline

This repository is equipped with an automated continuous delivery pipeline via GitHub Actions ([`.github/workflows/release.yml`](.github/workflows/release.yml)):

1. Version bumping in `pubspec.yaml` and documenting changes in `CHANGELOG.md`.
2. Pushing commits to the `main` branch automatically triggers the workflow to:
   - Extract the release notes directly from `CHANGELOG.md`.
   - Compile the production-signed Android APK (`flutter build apk --release`).
   - Create a published **GitHub Release** complete with the APK attached for direct user download.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) © 2026 Wall o' Pay.
