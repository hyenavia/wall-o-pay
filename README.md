# Wall o' Pay 🌆

<div align="center">

<p align="center">
  <img src="docs/images/banner.png" alt="Wall o' Pay — Vice City Sunset Key Art Banner" width="100%" style="border-radius: 14px; max-width: 960px;">
</p>

### _Your Money, Under Your Control_

**Modern, Lightning-Fast & Offline-First Personal Finance Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Database](https://img.shields.io/badge/Database-Drift%20SQLite-101A3A?logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Security](https://img.shields.io/badge/Security-Keystore%20%7C%20Biometrics-38B271?logo=android&logoColor=white)](https://github.com/hyenavia/wall-o-pay)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-3.1.0-FB7185.svg)](CHANGELOG.md)

[🌐 Visit Landing Page](https://hyenavia.github.io/wall-o-pay/) • [📥 Download Latest APK](https://github.com/hyenavia/wall-o-pay/releases/latest) • [📐 Architecture Guide](ARCHITECTURE.md) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Wall o' Pay** is a modern, high-performance personal finance and cashflow tracker built with Flutter. Engineered with a strict **Offline-First Reactive Architecture** powered by Drift SQLite and Flutter Riverpod, the app operates instantaneously with zero network latency and works 100% offline.

When you're ready to back up or sync across devices, Wall o' Pay offers optional, seamless synchronization with Firebase Authentication and Cloud Firestore, backed by hardware-grade encryption on your device.

---

## 🚀 Highlights in Latest Release (v3.0.0)

Wall o' Pay v3.0.0 introduces the complete **Vice City Sunset** visual rebranding, hardware-backed Keystore security hardening, comprehensive 3D custom iconography, and hardened Cloud Firestore Security Rules:

- 🌆 **Full Vice City Sunset Branding:** Updated About Wall o' Pay lore, financial recap notifications, and documentation to reflect the **Vice City Sunset** identity (`Midnight Navy`, `Deep Navy`, `Sunset Magenta`, `Neon Cyan`, and `Golden Yellow`).
- 🎨 **25+ Bespoke Miami Sunset Icons:** Integrated compressed high-resolution custom icons across header actions, search bar, transaction filter chips, cashflow cards, and budget pillars.
- 🌅 **Prominent Coastal Sunset Background:** Activated the portrait tropical sunset and skyline across Home, Transactions, Budget, and Insights with balanced atmospheric scrim.

- 🌅 **Vice City Sunset Visual Identity:** A retro-modern, coastal sunset aesthetic featuring deep midnight navy (`#070D2B`), deep navy card surfaces (`#101A3A`), sunset magenta (`#FF2E93`), sunset orange (`#FF8A36`), neon cyan (`#20D9E8`), and golden yellow (`#FFD166`).
- 🌆 **Unified 4-Page Header Canopy (Concept A):** Home, Transactions, Budget, and Insights now share a vertical sunset skyline header canopy with dark navy gradient overlay, preserving the original sheet-based layout.
- 🪪 **Settings Coastal Sunset VIP Card:** The profile card in Settings features the panoramic coastal sunset landscape with Neon Edge Highlight border and transparent circular Vice City avatar frame.
- 🔤 **Retro-Modern Typography System:** Space Grotesk for bold headings and tabular financial numbers, Inter for smooth body copy, and IBM Plex Mono for technical details.
- 🚀 **Zero-Flash Midnight Navy Splash Screen:** Fully unified native launch background and Flutter startup in Midnight Navy (`#070D2B`) with centered emblem.
- 🪪 **Refreshed Logo & App Launcher Icon:** Replaced application icon with the iconic **Neon Sunset Wallet W Emblem** across Android adaptive icons, iOS, Web, and desktop launchers.
- 🎨 **30 Bespoke Miami Sunset Finance Icons:** High-precision, transparent 128x128 icons tailored for navigation, transactions, wallets, analytics, savings, and reminders.
- 🏝️ **Tropical Neon Empty State Illustrations:** 6 high-resolution 512x512 empty state illustrations for transactions, budgets, savings, analytics, search, and notifications.
- 🌆 **Atmospheric Backgrounds:** Coastal skyline sunset for authentication, onboarding, and PIN lock screens; midnight neon arc waves for headers and sheets.
- 🛡️ **Universal Biometric Unlock:** Instant fingerprint and face recognition (`local_auth`) coupled with a 6-digit PIN pad. Authenticate in a fraction of a second when opening the app.
- 🔐 **Hardware-Backed Secret Storage:** Cryptographic migration of PIN hashes, salts, and anti-tamper lockout counters into the **Android Keystore** (`EncryptedSharedPreferences`) and **iOS Keychain** via `FlutterSecureStorage`.
- 🔑 **Key-Stretched Security (v2 Salted HMAC-SHA256):** Upgraded PIN verification to a 2,048-iteration salted HMAC-SHA256 scheme with persistent exponential backoff lockout protection (30s → 120s → 300s).
- ⚡ **60 / 120 FPS Rendering & Quick Logging:** Parallel cold-start initialization, lazy tab mounting, SQL-aggregated wallet balances, Android home screen quick shortcuts, cashflow calendar, and 150ms search debounce.
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

- **Target Tracking & Pace Projection:** Set goals for emergency funds, gadgets, travel, or investments with recommended weekly/monthly contribution pace, status badges (_On Track_, _Behind Schedule_, _Due Today_, _Overdue_), and one-tap pace quick-fill.
- **Linked Account Deposits:** Fund savings goals directly from designated wallets (or track virtual allocations) with progress percentages and milestone markers.

### 🤝 Debts & Custom Split Bills

- **Lend & Borrow Tracking:** Keep track of who owes whom with due dates, overdue alerts, and settlement history.
- **Equal & Custom Split Bills:** Split bills evenly or customize exact per-friend amounts (`CustomSplitResult`) with live user-share validation.

### 📈 Visual Insights, Vitality Score & Filtered Reports

- **Net Worth & Financial Health Score:** Track unified net worth (`Liquid Assets + Receivables - Liabilities`) alongside a 0–100 four-pillar _Financial Health Score_ without double-counting goal allocations.
- **Weekly & Monthly Financial Recaps & Drill-Down:** Review completed period recaps, tap category rows or pie chart slices to inspect matching transactions, and explore 6-period trend charts powered by `fl_chart`.
- **Filtered PDF, CSV & Guest Backup:** Export wallet-filtered PDF statements, date- and wallet-filtered 8-column CSVs, and complete JSON backups with unobtrusive Guest Mode backup reminders.

### ⏰ Automation, Modules & Reminders

- **Recurring Transactions:** Automate subscriptions, bills, and salaries with due confirmation queues inside Home and Recurring Schedules.
- **Active Modules Manager:** Enable or disable optional feature pillars (`Goals`, `Debts & Splits`, `Recurring`, `Budget`, `Transfers`) dynamically via presets (**All Features** / **Minimalist**).
- **Smart Local Notifications:** Customizable daily reminders, 80%/100% budget warnings, debt due reminders, and contextual Financial Recap alerts scheduled cleanly on-device.

### 🌐 Bilingual Localization

- Complete native support for both **English** and **Bahasa Indonesia** with seamless in-app switching.

---

## 🛠️ Technology Stack

| Layer                   | Technology                                            | Details                                                       |
| :---------------------- | :---------------------------------------------------- | :------------------------------------------------------------ |
| **Framework**           | Flutter 3.47+ (Stable Channel)                        | High-performance cross-platform UI                            |
| **Language**            | Dart 3.13+                                            | Null-safe, modern reactive language                           |
| **State Management**    | Flutter Riverpod (`flutter_riverpod` 3.x)             | Predictable, reactive dependency injection                    |
| **Local Database**      | Drift SQLite (`drift`, `drift_flutter`)               | Type-safe SQL engine with reactive streams                    |
| **Hardware Security**   | `flutter_secure_storage` & `local_auth`               | Android Keystore / iOS Keychain & Biometrics                  |
| **Cloud & Auth**        | Firebase Core, Firebase Auth, Firestore               | Optional real-time cloud backup & cross-device sync           |
| **Charts & Analytics**  | `fl_chart`                                            | Interactive, animated vector charts                           |
| **Reporting & Export**  | `pdf` & `printing`                                    | Custom PDF generation & print-ready statements                |
| **Local Notifications** | `flutter_local_notifications` & `timezone`            | Offline scheduled notifications & threshold alerts            |
| **Typography & Icons**  | Space Grotesk, Inter & IBM Plex Mono (`google_fonts`) | Material 3 & tabular figures for number alignment             |
| **CI / CD Pipeline**    | GitHub Actions                                        | Automated `flutter analyze` & `flutter test` gate + APK build |

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
