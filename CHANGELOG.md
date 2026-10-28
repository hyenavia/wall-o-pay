# Changelog 📋

All notable changes to the **Wall o' Pay** modern & offline-first personal financial management project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
