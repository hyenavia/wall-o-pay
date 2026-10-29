# Changelog 📋

All notable changes to the **Wall o' Pay** modern & offline-first personal financial management project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.2] - 2026-10-30

### Fixed
- **Multi-Device Personalization & Cross-Device Budget Synchronization:**
  - Resolved cross-device budget mismatch where Device B failed to display budgets created on Device A because period settings (`periodType` and `firstDayOfWeek`) were only stored locally, resulting in conflicting period calculation keys.
  - Added full Cloud Firestore two-way synchronization and real-time listeners for user personalization (`users/{uid}/meta/preferences`), syncing Theme Mode, Language, Period Mode (Monthly vs Weekly), and Custom Payday / First Day of Week across all devices.
- **True Account & Cloud Data Deletion:**
  - Resolved issue where "Log out & erase data" previously only signed out without deleting the authentication account or username reservation.
  - Implemented `AuthService.deleteAccount()`, which permanently deletes the Firebase Authentication user account (`user.delete()`), releases username reservations in `usernames/{username}`, and deletes all user documents in Firestore `users/{uid}`.
  - Separated Settings into clear actions: a clean **Log Out** (preserves cloud data) and a dedicated **Delete Account & Data** (permanently erases account and data with password verification).

---

## [1.6.1] - 2026-10-29

### Fixed
- **App Startup White Screen Freeze:**
  - Resolved an issue where `Lock.instance.load()` accessed `FirebaseAuth.instance` before `Firebase.initializeApp()` was completed, throwing an uncaught startup exception and preventing `runApp()` from executing.
  - Reordered initialization in `main.dart` so Firebase initializes first, and added defensive fallback handling in `Lock.instance` so it safely defaults to offline guest mode if Firebase is unavailable.
  - Ensured `ShareService` runs post-frame callbacks so shared intent pop-ups never conflict with Flutter's initial widget layout.

---

## [1.6.0] - 2026-10-29

### Added
- **Recurring Transactions & Subscriptions:**
  - Automated recurring rule engine (`RecurringService`) supporting Daily, Weekly, and Monthly cycles.
  - Review-first confirmation flow: Due recurring rules generate into the pending transaction inbox with a distinct "Scheduled Recurring" badge, allowing users to review, adjust, or discard transactions before any wallet balances are affected.
  - Dedicated "Recurring & Subscriptions" management screen (`RecurringPage`) in Settings with schedule status toggles and rule deletion.
- **Receipt Attachment & External App Sharing:**
  - Native Android `ACTION_SEND` intent receiver to accept shared receipts (images and text) directly from m-banking apps (BCA, Livin' Mandiri, BRImo, BNI), e-wallets (GoPay, OVO, DANA, ShopeePay), and gallery receipts.
  - In-app receipt attachment in `TransactionForm` via Camera or Gallery with full-screen lightbox preview and remove capability.
  - Automatic parsing of amounts and notes from shared text using `TransactionParser`.
  - Visual receipt indicator on transaction lists (`TransactionTile`) and receipt preview within `PendingReviewSheet`.

### Fixed
- **Multi-Account Data Isolation & Cloud Wipe:**
  - Resolved cross-account data contamination by resetting the local SQLite database when switching accounts, ensuring separate accounts on the same device never see or overwrite each other's data.
  - Fixed "Log out & erase data" to completely erase remote Firestore collections under `users/{uid}`, preventing deleted cloud data from re-syncing.
  - Scoped App PIN lock credentials per account UID in local storage to prevent PIN erasure or corruption when switching accounts.
  - Added real-time two-way synchronization and user scoping for budget allocations, buckets, and custom total pools (`meta/budgetConfig`).
  - Streamlined Cloud Sync settings with a transparent real-time status card and manual sync trigger.

---

## [1.5.1] - 2026-10-29

### Fixed
- **Automatic In-App Update Pop-Up Dialog:**
  - Resolved an issue where update detection only updated the background state and dashboard card banner without displaying the automatic update pop-up dialog.
  - Added smart automatic pop-up prompt upon detecting new releases on startup and resume, with anti-spam session tracking (`_promptedVersion` and `_isShowingDialog`).
  - Added awareness of App PIN Lock so the update dialog waits gracefully until the user unlocks the screen before popping up on the dashboard.

---

## [1.5.0] - 2026-10-29

### Added
- **Multi-Device App PIN Lock Security (inspired by Lunera):**
  - Integrated a dedicated 6-digit PIN security lock with salted SHA-256 cryptographic hashing (`crypto`).
  - **Offline-First with Cloud Sync:** PIN configuration is stored securely locally in SharedPreferences and seamlessly synchronizes with Cloud Firestore (`users/{uid}/meta/security`) so users never lose their PIN across devices.
  - **Adaptive Auto-Lock Timeout:** Configurable background timeout (Immediately with 3s grace period, 1 minute, or 5 minutes). Automatically locks the application and returns to root safely when returning from the background.
  - **Full-Featured Security UI:**
    - Custom interactive numeric `PinPad` with circular keypads, tactile feedback, and 6 glowing dot indicators.
    - Premium dark forest themed `LockScreen` with brand logo and 5-attempt anti-brute-force rate limiting (30s cooldown).
    - Safe "Forgot PIN?" recovery flow allowing account sign-out to reset access.
    - Dedicated `SecurityPage` accessible from Settings with quick toggle, auto-lock timeout selector, and "Change PIN" workflow.

---

## [1.4.2] - 2026-10-29

### Fixed
- **Wallet Balance Synchronization & Adjustment:**
  - Resolved balance inflation where editing a wallet's balance erroneously added the new initial amount to existing net transactions instead of matching the user's intended current balance.
  - Added "Adjust Balance" dialog with dual modes: **Current Balance** (automatically computes initial balance so the wallet immediately reflects the exact real-world amount) and **Initial Balance** (sets the starting balance before transactions).
  - Fixed missing text label (`: `) in the wallet details bottom sheet to prominently display the active current balance and transaction net flow.

### Changed
- **Unified Total Net Worth Display on Dashboard Hero Card:**
  - Synchronized the main dashboard card to prominently display **Total Balance (All Accounts)** matching the sum of all individual wallets and accounts (`Rekening Utama`, `Bank Digital`, `E-Wallet`, `Tunai`).
  - Added a dedicated period cashflow indicator pill on the hero card (`Weekly Flow` / `Monthly Flow`) displaying net surplus/deficit (`+Rp X` / `-Rp X`) alongside income and expense breakdowns.

---

## [1.4.1] - 2026-10-29

### Changed
- Reverted update alerts strictly to clean In-App Notification Banners and Settings indicator badges to maximize battery efficiency and eliminate intrusive system status bar popups.

### Removed
- Removed native system status bar notification alerts and Android `POST_NOTIFICATIONS` runtime permission requirement.

---

## [1.4.0] - 2026-10-29

### Added
- **Multi-Wallet & Multi-Account Architecture (Kantong & Rekening):**
  - Added dedicated Drift SQLite table (`Wallets`) seeded with default accounts: Rekening Utama, Bank Digital, E-Wallet, and Tunai (Cash).
  - Integrated interactive Wallets slider on Home dashboard displaying live balances per account alongside initial balance configuration.
  - Added source fund / wallet selector in Transaction Form for both Expenses and Incomes.
  - Introduced seamless Wallet-to-Wallet Fund Transfers (`TxType.transfer`) that accurately update account balances without counting against living budget quotas.
  - Enhanced transaction history with transfer directional flow indicators (`Source ➔ Destination`) and account filtering.
- **Customizable Weekly Calculation Start Day:**
  - Added preference in Settings allowing users to choose their weekly period starting day (Monday through Sunday, e.g. Wednesday for users with midweek allowances).
  - Dynamically recalculates weekly periods, budget resets, cashflow analysis, and days remaining according to the selected start day.

---

## [1.3.3] - 2026-10-29

### Added
- **Android System Status Bar & Heads-Up Notification for App Updates:**
  - Added native Android notification channel (`wall_o_pay_updates`) with high importance to trigger real-time heads-up banners and status bar notifications outside the app.
  - Integrated one-tap direct download action directly from the system notification shade.
  - Added seamless background lifecycle checking and smart notification anti-spam persistence to prevent repeated alerts for the same release.

---

## [1.3.2] - 2026-10-29

### Added
- **Custom Nominal Budgeting Mode for Savings & Living Pillars:**
  - Added "Custom Nominal" mode toggle in the Budget dialog, allowing users to specify exact fixed savings amounts (e.g. Rp 100.000 out of Rp 600.000) alongside standard 50/30/20.
  - Dynamically calculates adaptive pillar percentages and interactive 3-color ratio preview bars based on actual allocations.
  - Added a convenient "Split remaining 70/30" quick action to automatically distribute remaining funds between Needs and Wants.
  - Added live allocation feedback indicator displaying remaining unallocated amounts.

---

## [1.3.1] - 2026-10-29

### Added
- **Proactive In-App "Update Available" Notification System:**
  - Added real-time `availableUpdateProvider` tracking whenever a newer release is published on GitHub.
  - Introduced an interactive In-App Notification Banner on the Home dashboard with direct "Update Now" action and session dismissal.
  - Added a distinctive "NEW" indicator badge on the Settings page next to "Check for Updates" when an update is detected.
  - Automatically checks for updates in the background on app startup and on Home dashboard pull-to-refresh.

---

## [1.3.0] - 2026-10-29

### Added
- **50/30/20 Budgeting Rule Architecture:**
  - Implemented the gold-standard 50/30/20 financial allocation framework in the Budget tab.
  - Users can input their overall budget/income for the active period, which automatically splits into 50% Needs, 30% Wants, and 20% Savings.
  - Added smart default categorization mapping expense categories to respective pillars.
  - Added flexible category management allowing users to reassign any category to Needs, Wants, or Savings with a single tap.
  - Supported optional micro-budget limits for individual categories within their macro bucket pool.
  - Added visual 3-pillar progress cards with real-time spending calculations and direct linkage from the Savings bucket to active Savings Goals.
  - Synchronized Home dashboard budget summary to seamlessly reflect the active 50/30/20 budget pool.

---

## [1.2.6] - 2026-10-28

### Added
- **Multi-Language User Feedback Integration:**
  - Added dedicated "Send Feedback" option inside the Settings dashboard (About & Support section).
  - Automatically directs users to localized feedback surveys based on active language setting (Indonesian Form vs. English Form).
  - Added direct link to the English User Feedback survey on the web landing page navigation bar and footer.
- **Brand Landscape Banner on Web Landing Page:**
  - Integrated official brand showcase banner with typography "Better Habits Bigger Goals", "Your money, under your control", and "Manage Plan Grow".
  - Configured high-resolution OpenGraph and Twitter social card banner previews (`og:image`).

---

## [1.2.5] - 2026-10-28

### Changed
- **Streamlined Release for General Public Accessibility:**
  - Temporarily disabled background notification listener service (`TransactionNotificationListenerService`) to prevent Google Play Protect false-positive fraud warnings and bypass Android 13+ restricted settings.
  - Simplified in-app Settings dashboard by removing the Auto-Detect Transactions and manual simulation configuration cards.
  - Streamlined website download installation guide to a straightforward, frictionless 4-step sideload process.

---

## [1.2.4] - 2026-10-28

### Fixed
- **Persistent Release Key Signing for Seamless Updates:**
  - Configured repository-level release signing credentials (`key.properties` and `release-keystore.jks`) for GitHub Actions CI and local builds.
  - Ensures every GitHub Actions build is signed with the identical cryptographic signature, eliminating Android's `INSTALL_FAILED_UPDATE_INCOMPATIBLE` ("App not installed as package conflicts with an existing package") error when updating in-place.

---

## [1.2.3] - 2026-10-28

### Added
- **In-App Update Checker (`UpdateCheckerService`):**
  - Integrated automatic release polling via GitHub Releases public API.
  - Displays a dedicated update dialog showing new version numbers, release notes, and a direct 1-tap "Update Now" button.
  - Added on-demand "Check for Updates" option in Settings dashboard.
  - Added background check 2 seconds after application launch.
- **Enhanced In-App Android 13+ Notification Setup Guide:**
  - Added an inline setup walkthrough inside the Settings > Auto-Detect Transactions section.
  - Added direct action buttons for "Open App Info" and "Open Notification Access".
- **Comprehensive Sideload & Security Installation Guide on Web Landing Page:**
  - Added visual walkthrough for bypassing Google Play Protect false positives on bank notification permissions.
  - Added step-by-step instructions for granting restricted settings on Android 13, 14, and 15.

### Fixed
- **CI Build Runner NDK Download Interruption:**
  - Pinned `ndkVersion` in `android/app/build.gradle.kts` to LTS version `27.0.12077973` pre-installed on GitHub Actions runners, eliminating 1GB network download failures during APK compilation.

---

## [1.2.2] - 2026-10-28

### Added
- **Exit Confirmation Dialog (`PopScope`):**
  - Added an elegant modal confirmation alert when pressing the Android back button from the root dashboard.
  - Automatically navigates back to the Home tab if pressed from child tabs, and prompts for confirmation before exiting the application.
- **Android 13+ Restricted Settings In-App Guide & Direct Shortcut:**
  - Added native platform method `openAppSettings` (`Settings.ACTION_APPLICATION_DETAILS_SETTINGS`) to launch Wall o' Pay's App Info settings directly.
  - Added an interactive in-app guide sheet explaining the 4-step process to unlock restricted notification listener access on Android 13, 14, and 15.

---

## [1.2.1] - 2026-10-27

### Added
- **Instant Auto-Sync on Network Reconnection (`connectivity_plus`):**
  - Integrated native network connectivity listener that detects when Wi-Fi or mobile data reconnects.
  - Automatically triggers instant two-way synchronization the exact moment internet connectivity is restored, without needing user intervention or app restarts.
  - Added a gentle 60-second periodic background sync safety heartbeat to guarantee consistency across intermittent networks.

---

## [1.2.0] - 2026-10-27

### Added
- **Automatic Multi-Device Cloud Synchronization (`AutoSyncService`):**
  - Instant real-time two-way sync between Drift SQLite and Firebase Firestore across all logged-in devices.
  - Reactive SQLite table update listener that automatically debounces and pushes local transactions, categories, budgets, and savings goals to Firestore.
  - Real-time Firestore snapshot listeners that instantly stream and apply remote changes directly to Drift database.
  - Automatic profile synchronization (nickname and photo avatar) across devices.
  - `RefreshIndicator` (pull-to-refresh) and manual "Sync Now" button on the Home dashboard for instant on-demand sync.
  - Background auto-sync triggered on application launch and resume (`WidgetsBindingObserver`).
- **Official Production Keystore & Release Signing:**
  - Configured dedicated release signing credentials (`release-keystore.jks` & `key.properties`) in Gradle.
  - Eliminates Google Play Protect untrusted debug certificate blocking during Android installation.

---

## [1.1.1] - 2026-10-27

### Fixed
- **Modal Bottom Sheet Overflow Resolution:**
  - Resolved `BOTTOM OVERFLOWED BY 32 PIXELS` layout error on the "Simulate Sample Notification" modal sheet by enabling `isScrollControlled: true`, `useSafeArea: true`, and wrapping contents in a scrollable `SingleChildScrollView`.
  - Added `SafeArea` padding to `PendingReviewSheet` and `_showPendingListModal` to prevent navigation bar clashes on Android devices with 3-button navigation bars.

---

## [1.1.0] - 2026-10-27

### Added
- **Auto-Detected Transaction Inbox with User Confirmation:**
  - Background notification interception powered by Android `NotificationListenerService` (`TransactionNotificationListenerService`) capturing transactions from Indonesian banks and e-wallets (BCA, Mandiri Livin', BRImo, BNI, GoPay, OVO, DANA, ShopeePay).
  - Intelligent regex parser (`TransactionParser`) extracting exact transaction amounts, transaction types (income vs. expense), merchant notes, and auto-suggesting categories based on keywords.
  - New Drift SQLite `PendingTransactions` table (database schema upgraded to v4) storing unconfirmed captured drafts securely on-device.
  - Interactive `PendingInboxCard` banner on the Home dashboard notifying users whenever new transactions are detected.
  - Modal review bottom sheet (`PendingReviewSheet`) allowing users to inspect raw notification snippets, edit amounts/categories/dates/memos, and either confirm & record or discard the transaction without touching official balance.
  - Built-in notification simulator in Settings for one-click testing with sample banking alerts without needing real bank transactions.

---

## [1.0.0] - 2026-10-27

### Added
- **Core Architecture & Offline Database:**
  - High-performance, offline-first local database powered by Drift SQLite (`AppDatabase`).
  - Reactive state management with `flutter_riverpod`.
- **Transaction & Cashflow Tracking:**
  - Income and expense logging with amount, category, custom timestamp, notes, and receipt photo attachments (`image_picker`).
  - Real-time search query filtering and category filtering.
- **Category Budgeting System:**
  - Monthly budget limit caps per expense category.
  - Reactive visual progress indicators reflecting real-time remaining quotas.
- **Dedicated Savings Goals:**
  - Goal creation with target dates and required amounts (e.g., Emergency Fund, Travel, Gadgets).
  - Progressive deposit contributions with percentage completion tracking.
- **Financial Analytics & Insights:**
  - Interactive charts powered by `fl_chart` visualizing monthly expenses vs. income and categorical distributions.
- **Cloud Backup & Authentication:**
  - Secure Firebase Authentication (Email/Password & Google Sign-In).
  - Cloud Firestore sync and backup/restore capabilities for multi-device migration.
  - One-click data export into standard CSV and JSON files.
- **Visual Identity & Design System:**
  - Bespoke color palette featuring Deep Forest Green (`#1E4238`), Sage (`#A9C5B1`), and Ivory.
  - Adaptive Android (API 26+) and iOS app launcher icons generated via `flutter_launcher_icons`.
  - Material 3 dual-theme system (Dark Mode & Light Mode).
  - In-app bilingual localization (English & Bahasa Indonesia).
- **Web Landing Page (`docs/`):**
  - Modern, fully responsive showcase website ready for GitHub Pages hosting.
  - Interactive 50/30/20 budget allocation simulator and goal timeline estimator.
  - Direct APK download section with Android step-by-step installation instructions and technical specifications.
- **CI/CD Automation:**
  - GitHub Actions auto-release workflow (`.github/workflows/release.yml`) for automated APK compilation and GitHub Releases generation upon push to `main`.
