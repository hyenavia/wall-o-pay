# Changelog 📋

All notable changes to the **Wall o' Pay** modern & offline-first personal financial management project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.11.32] - 2026-11-05

### Changed
- **Web Landing Page Modernization & App Feature Parity:**
  - **Accurate Feature Grid (8 Cards):** Balanced the features section into an even 8-card grid representing real in-app capabilities (Offline-First & Guest Mode, Rapid 5-Second Logging & Mini Calculator, Multi-Account & Wallets, Smart 50/30/20 Budgets, Debts & Split Bills, Goals Linked to Wallets, Visual Insights & Export, and Signature Botanical Forest theme).
  - **Removed Legacy Inbox Reference:** Purged legacy references to the removed background notification auto-track inbox across `docs/index.html` and `README.md`.
  - **3-Block Rupiah Phone Mockup:** Redesigned the Hero mobile preview to reflect the contemporary 3-Block Home architecture (Balance Inflow/Outflow, Daily Budget Pulse, and Recent Activities) with localized Rupiah (`Rp`) currency formatting and tabular figures.
  - **Dynamic Interactive Showcase:** Upgraded the Showcase section so switching tabs between Dashboard, Transactions, Budgets, and Savings Goals dynamically renders dedicated rich visual UI previews.
  - **Version Consistency & Anti-Downgrade Guard:** Synchronized version markers across the landing page and updated `fetchLatestReleaseVersion()` in `docs/script.js` to ensure older GitHub API releases do not downgrade the current build version.

---

## [1.11.31] - 2026-11-05

### Added
- **Undo Delete via Floating SnackBar:**
  - Added an **"Undo (Urungkan)"** action to floating SnackBars shown immediately after deleting transactions, transfer entries, debt records, or savings goals. Tapping Undo promptly restores the soft-deleted item and its reactive balance calculations without manual re-entry.
- **Budget & Payday Settings in JSON Backup:**
  - Included app preferences (payday `firstDayOfMonth`, period type, rollover, and alert flags) and 50/30/20 budget pool configurations (`BudgetRuleConfig` & category buckets) in the `.json` backup file.
  - Guest mode users migrating between devices now preserve their customized payday cycle and budget allocations alongside their SQLite data.
  - Fully backward-compatible with legacy backup files.

---

## [1.11.30] - 2026-11-05

### Changed
- **Side-by-Side Debug & Release Builds:**
  - Added `applicationIdSuffix = ".debug"` and a dedicated `Wall o' Pay (Debug)` app label for Android debug builds so developers can install and test debug builds alongside the production release APK on the same device without signature conflicts (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) or overwriting production local SQLite data.

---

## [1.11.29] - 2026-11-04

### Added
- **Offline Guest Mode (Pure Local Mode):**
  - Added a **"Continue as Guest"** option on the authentication screen, allowing users to jump straight into tracking cashflow 100% offline on-device without creating a Firebase account.
  - Enabled local Guest profile customization (nickname & avatar photo) and local 6-digit PIN protection.
  - Added seamless Guest-to-Account data migration when registering a new account, plus a smart conflict prompt (**Merge Data** vs. **Use Cloud Only**) when signing into an existing account from Guest mode.
  - Updated **Settings** for Guest sessions with a dedicated **Sign In / Create Account** card, **Exit Guest Mode**, and **Erase Local Guest Data** controls.

---

## [1.11.28] - 2026-11-04

### Added
- **Admin Fee on Expense Transactions:**
  - Added dedicated Admin Fee support to Expense transactions within the "More details" section.
  - Supports completely custom admin fee entry (e.g. food delivery fees, electricity token convenience charges) alongside one-tap quick chips (`Free`, `Rp 1.000`, `Rp 2.500`, `Rp 5.000`).
  - Automatically records an associated secondary expense transaction from the selected payment account without requiring database schema changes.

### Changed
- **Botanical Forest Theme & Typography Polish:**
  - Configured tabular figures (`FontFeature.tabularFigures()`) across all text styles, ensuring monospaced alignment for numerical values and Rupiah amounts in calculators and lists.
  - Promoted primary CTA buttons (`FilledButton` & Floating Action Button) to high-contrast `AppColors.sage` (`#A9C5B1`) with dark ink text (`#202923`) for crisp visual prominence.
  - Enhanced `AppColors.income` contrast to `#38B271` and exposed high-contrast surface/semantic tokens (`incomeOnDark`, `expenseOnDark`, `bg`, `cardSurface`, `surfaceContainer`, `borderOutline`) in `AppColors`.
  - Centralized `bottomSheetTheme`, `popupMenuTheme`, and `snackBarTheme` in `buildTheme()`.

---

## [1.11.27] - 2026-11-04

### Changed
- **Home Screen Simplicity & 3-Block Architecture:**
  - Consolidated the home screen into three essential, focused blocks that instantly answer *"Are my finances safe?"*:
    1. **Balance & Period Cashflow Card**: Real-time total balance and monthly/weekly net flow.
    2. **Unified Financial Health & Budget Pulse**: Combines health status tier (Safe / Caution / Limit), safe daily spending quota, today's expenses, and monthly budget progress with direct access to budget setup.
    3. **Recent Transactions**: Immediate access to the latest 4 records with single-tap navigation to the full transactions view.
  - Removed duplicate accounts card from the home screen to eliminate vertical clutter, directing users to the dedicated Accounts tab for detailed account balances.

---

## [1.11.26] - 2026-11-04

### Changed
- **Progressive Disclosure in Transaction Form (The 5-Second Rule):**
  - Streamlined `TransactionForm` to focus strictly on core inputs: **Amount** (with calculator & quick chips), **Category**, and **Account/Wallet**, followed immediately by the **Save** action.
  - Collapsed secondary inputs (Date, Notes, Need/Want classification, Receipt photo attachments, and Save as template) behind a clean, interactive **"More details"** expansion panel.
  - In transfer mode, tucked the admin fee input behind a compact **"+ Add admin fee"** button to eliminate visual clutter.
  - In edit mode or when applying templates with notes/receipts, automatically expands the details panel to prevent any hidden data confusion.

---

## [1.11.25] - 2026-11-04

### Added
- **Custom Transfer Admin Fee (Biaya Admin Transfer):**
  - Added dedicated Admin Fee support to transfer transactions in `TransactionForm`.
  - Supports completely custom admin fee entry to match any bank or e-wallet tariff, alongside one-tap quick preset chips (`Free (Rp 0)`, `Rp 1.000`, `Rp 2.500`, `Rp 6.500`).
  - Automatically deducts the transfer admin fee from the source account via a corresponding expense transaction (`TxType.expense`) without requiring database schema migrations.
- **Due Date Reminders for Debts & Receivables:**
  - Added automated local notifications for upcoming or due debts and receivables (`dueDate` today, tomorrow H-1, or overdue up to 7 days).
  - Categorizes reminders into debt collection (`Debt collection reminder`) and debt repayment (`Debt repayment reminder`).
  - Implemented daily deduplication through `SharedPreferences` to ensure users receive at most one reminder notification per debt item each day.
  - Linked reminder checks to app lifecycle startup, resume events, and immediate debt creation/payment flows.

---

## [1.11.24] - 2026-11-04

### Added
- **Integrated Mini Calculator & Quick "000" Input:**
  - Added a dedicated mini-calculator bottom sheet in `TransactionForm` accessible directly via a calculator icon button in the amount input field, allowing users to effortlessly sum multi-item receipts or split bills.
  - Included a prominent **"000"** (triple zero) key alongside digits, clear, backspace, and standard arithmetic operators (`+`, `-`, `×`, `÷`, `=`).
  - Added horizontal quick-denomination chips (`+000`, `+10rb`, `+50rb`, `+100rb`) immediately beneath the transaction amount field for lightning-fast amount entry.

---

## [1.11.23] - 2026-11-04

### Added
- **Account & Category Filters on Transactions:**
  - Added dedicated interactive filter dropdown pills for **Accounts / Wallets** and **Categories** on the Transactions screen, allowing users to quickly filter transactions by specific accounts (e.g. GoPay, Digital Bank) or categories with one tap.
  - Added dynamic transaction summary indicators that update real-time income and expense totals based on active account/category filters.
  - Added a quick "Clear filters" action to immediately restore full view.
- **Goal Savings Deposit & Withdrawal with Wallet Integration:**
  - Added support for withdrawing funds from savings goals back into chosen accounts.
  - Added editing support for goal names, target amounts, and target dates via popup menu.
  - Integrated account selection toggle into goal funds deposits and withdrawals, automatically generating expense or income transactions tied to the specified account.

### Changed
- **Debt Repayment Account Association:**
  - Enhanced debt payment recording dialog to include an account/wallet selector when recording transactions, ensuring repayments are properly attributed to specific accounts and keeping wallet balances synchronized.

---

## [1.11.22] - 2026-11-04

### Fixed & Optimized
- **Firestore Sync Quota & Battery Optimization:**
  - Removed aggressive 60-second periodic full-database polling in `AutoSyncService`, relying on reactive Firestore real-time snapshot listeners, network connectivity triggers, and app lifecycle resumption.
  - Eliminated redundant `col.get()` full-collection fetches during debounced local auto-pushes by only querying SQLite records changed since the last sync timestamp (`_lastPushedAt`).
  - Cached remote document timestamps during the pull phase of two-way synchronization, avoiding duplicate remote collection reads during the subsequent push phase.
- **Unified App Lifecycle Management:**
  - Consolidated `WidgetsBindingObserver` lifecycle listening inside `HomeShell` and removed duplicate observer and initial sync triggers in `HomePage`.
  - Replaced `HomePage` stateful lifecycle boilerplate with a clean `ConsumerWidget`.
- **Repository Documentation Accuracy:**
  - Updated repository clone, release, and landing page URLs in `README.md` to reference the official `hyenavia/wall-o-pay` repository.
  - Corrected aesthetic styling description in `README.md` to accurately represent the signature Botanical Forest dark theme.

---

## [1.11.21] - 2026-11-04

### Changed
- **Direct Access Menu in More Features:**
  - Removed the confusing "Active Modules & Features" toggle banner and popup sheet from More Features.
  - Added a direct **Budget** menu tile into the More Features screen alongside Accounts, Goals, Transfer Balance, Debts & Splits, Recurring, Categories, PDF Report, and Settings, giving immediate 1-tap access to every core feature.
  - Ensured the Home screen budget card remains consistently visible as a standard budgeting overview.

### Removed
- **Streamlined Settings & Simplified Onboarding:**
  - Removed the redundant "Active Modules & Features" toggle item and sheet from Settings.
  - Streamlined new user onboarding by removing the feature toggle step so all tools are activated by default with zero friction.
  - Removed orphaned `module_sheet.dart` component.

---

## [1.11.20] - 2026-11-03

### Changed
- **Minimalist Home Screen & Header Feature Hub:**
  - Removed cluttered Quick Action button row from the center of the Home screen to achieve a zen, distraction-free aesthetic flowing directly from Daily Financial Pulse to Recent Transactions.
  - Replaced the redundant manual sync icon button on the Home header with a dedicated **More Features** hub icon (`Icons.grid_view_rounded`) for one-tap access to all modular tools.
  - Refined background synchronization feedback into an unobtrusive, subtle micro-spinner next to the header greeting during active syncing.
  - Elevated the **More** screen with an interactive Active Modules & Features summary banner and direct customization shortcut.

---

## [1.11.19] - 2026-11-03

### Added
- **Modular Feature Architecture & Onboarding Setup:**
  - Implemented modular feature system with persistent `modulePrefsProvider` supporting five core modular components: Savings Goals, Debts & Split Bills, Recurring Schedules, Account Transfers, and Category Budgets.
  - Added dedicated Module Selection step to the initial onboarding flow (`OnboardingPage`), enabling new users to choose their desired features or pick "All Features" vs "Minimalist" presets.
  - Dynamic Home dashboard quick actions and budget card that automatically adapt to show only active modules without visual clutter.
  - Added "Active Modules & Features" management bottom sheet accessible from both Settings and the More screen.
  - Full bilingual localization (English and Indonesian) and automated test suite for module preference state.

---

## [1.11.18] - 2026-11-03

### Added
- **Daily Financial Pulse Card (Humanized Status Visuals):**
  - Integrated a dedicated `DailyFinancialPulseCard` on the Home screen inspired by empathetic, human-centered financial design.
  - Features three-tier botanical health status badges: **Safe (Aman)** in soothing Sage, **Caution (Waspada)** in warm Amber, and **Limit (Batas)** in soft Terracotta clay.
  - Automatically assesses today's spending velocity against daily safe allowance (`balance / daysLeft`) and overall budget exhaustion.
  - Includes real-time spent vs daily quota progress meter, days remaining counter, and reassuring contextual advice to alleviate financial anxiety.
  - Full bilingual localization support (English & Indonesian) and comprehensive automated widget and logic test suite.

---

## [1.11.17] - 2026-11-03

### Added
- **Gaussian Blur Balance Masking:**
  - Replaced dot-masking (`Rp ••••••`) with native `ImageFiltered` Gaussian blur (`sigma: 8.0`) when toggling balance hiding.
  - Applied blur to Total Balance, Period Cashflow, Income, Expense, and individual account balances in Wallets & Accounts without causing layout shifts.

### Changed
- **Home Balance Card Header Cleanliness:**
  - Removed redundant "All Accounts" pill badge in the balance card header to eliminate visual crowding and collision with the savings percentage badge.

---

## [1.11.16] - 2026-11-02

### Fixed
- **Dynamically Resolved Installed App Version (Looping Update Prompt Fix):**
  - Integrated native Android `PackageManager.getPackageInfo` method channel (`getAppVersion`) to dynamically query the real installed app version (`versionName` set from `pubspec.yaml` by Gradle).
  - Resolved the persistent looping update prompt where updating to `v1.11.15` continued prompting the user to update due to a hardcoded version string in `UpdateCheckerService`.
  - Added startup initialization of the resolved version in `main.dart` and aligned in-app changelog entries for `v1.11.15` and `v1.11.16`.

---

## [1.11.15] - 2026-11-02

### Added
- **Direct Database Transaction Search (Direct SQL Search):**
  - Integrated `watchSearchTransactions` in Drift database using indexed SQL JOIN on notes and category names with instant reactive stream updates.
  - Implemented seamless `unwrapPrevious()` handling in `TransactionsPage` ensuring the keyboard never dismisses or flickers while typing search queries.
- **Privacy Shield (App Switcher Protection):**
  - Added Android native `FLAG_SECURE` toggling via method channel to hide sensitive financial screen content on Recent Apps switcher and prevent unwanted screenshots.
  - Provided bilingual toggle in Security settings with immediate startup enforcement.
- **Rollover Budget Integration:**
  - Implemented automatic carryover calculation in `effectiveBudgetProvider` that rolls forward unspent positive balances from previous periods into the current budget.
  - Added Rollover active banner and per-category rollover breakdown badges in `BudgetPage`.

### Changed
- **Database Indexing & Performance:**
  - Added composite indexes on `Transactions` (`date, deleted_at`, `category_id, deleted_at`, `wallet_id, deleted_at`, `to_wallet_id, deleted_at`) and `Budgets` (`month_key, deleted_at`) with self-healing SQLite setup on startup.
- **Code Modularization & Architecture Cleanliness:**
  - Refactored monolithic `budget_page.dart` (1,071 lines down to ~345 lines) by modularizing `BudgetPillarCard`, `showTotalBudgetDialog`, and `showCategoryBudgetSheet`.
  - Refactored monolithic `settings_page.dart` (1,132 lines down to ~720 lines) by extracting data, authentication, and cloud synchronization logic into `SettingsActions`.
- **Scheduled Recurring Rules Execution:**
  - Scheduled rules now record transactions directly into the official `transactions` table, properly preserving source/destination wallet associations.

### Removed
- **Sensitive Background Auto-Tracker & Notification Listener:**
  - Purged Android `TransactionNotificationListenerService.kt` and obsolete method channel handlers.
  - Removed `PendingTransactions` table from Drift schema and cleaned all related pending models, cards, and review sheets.
  - Decoupled manual Android receipt/text share receiver into standalone `transaction_parser.dart`.

---

## [1.11.14] - 2026-11-02

### Fixed
- **Scroll Responsiveness & Gesture Restoration:**
  - Resolved scroll-lock issue across secondary screens by removing the dynamic `NotificationListener` wrapper (`FadedScrollBody`), which previously disrupted active scroll drag gestures via mid-scroll rebuilds.
  - Restored native, reliable Flutter scrolling across all screens (Transactions, Budget, Insights, More, Settings, Accounts, Goals, Debts, Recurring, Security, and Profile).
  - Maintained the zero-overhead static top fade transition on Home page exclusively where curved container clipping actually occurs.

---

## [1.11.13] - 2026-11-02

### Changed
- **Unified Smooth Scroll Transition Across All Screens:**
  - Introduced `FadedScrollBody` in `lib/core/widgets.dart` powered by `NotificationListener<ScrollNotification>` and `ShaderMask`.
  - Standardized smooth feathering and fade-out at the top edge of all major screens (Transactions, Budget, Insights, More, Settings, Accounts, Goals, Debts, Recurring, Security, and Profile), creating a cohesive, luxurious scrolling experience throughout the entire app without harsh edge clipping.

---

## [1.11.12] - 2026-11-02

### Fixed
- **Dark Theme Contrast in About Sheet:**
  - Resolved low-contrast and unreadable elements in `about_sheet.dart` by replacing hardcoded `AppColors.deepForest` foreground colors on the version badge, lore quote icon, section headers, lore pillar icons, principles icons, links, and action buttons with high-contrast `AppColors.sage`.
- **Home Screen Scroll Transition & Clipping:**
  - Added a smooth gradient fade transition (`ShaderMask`) at the top of the curved `_Sheet` in `HomePage`, preventing cards and account chips from getting sliced abruptly by the sheet's top rounded corners during scroll.
- **Accounts Breakdown Card Distinct Identity:**
  - Refined `AccountsSummaryCard` header to show "Wallets & Accounts" with active accounts count and subtotal, eliminating title duplication with the hero balance card.

---

## [1.11.11] - 2026-11-02

### Fixed
- **Time-Aware Greeting Accuracy:**
  - Fixed greeting logic in `lib/core/format.dart` where early morning hours (00:00 - 04:59 midnight / wee hours) mistakenly greeted the user with "Selamat pagi" ("Good morning").
  - Adjusted time ranges so that 00:00 - 04:59 properly greets with "Selamat malam" ("Good evening"), aligning with Indonesian cultural conventions and English evening greetings.
  - Added unit test coverage in `test/greeting_test.dart` validating all 24 hours of the day across both Indonesian and English locales.

---

## [1.11.10] - 2026-11-02

### Changed
- **Home Dashboard & Navigation Streamlining:**
  - Revitalized Home quick actions by replacing redundant shortcuts (Add Tx, Budget, Insight) with essential 1-tap financial workflows: **Transfer Balance**, **Savings Goals**, **Debts & Splits**, and **More**.
  - Unified the Period Switcher and Monthly/Weekly period toggle into a single compact horizontal header row, saving vertical space and bringing the balance summary immediately above the fold.
- **Separation of Concerns between More & Settings:**
  - Dedicated `MorePage` as the central Financial Toolbox with direct access to Accounts, Transfer, Goals, Debts, Recurring, Categories, and PDF Reports, removing redundant navigation shortcuts.
  - Streamlined `SettingsPage` to focus exclusively on system preferences, user profile, security, cloud sync, notifications, and language.

---

## [1.11.9] - 2026-11-01

### Removed
- **Repository Cleanliness & Asset Hygiene:**
  - Removed obsolete setup manual `LANGKAH_LOGO.txt` from repository root.
  - Removed orphaned legacy `docs/images/logo_foreground.png`.

### Changed
- **Asset Alignment & Tooling Hygiene:**
  - Synchronized `assets/images/logo_foreground.png` with the new signature botanical forest adaptive icon foreground.
  - Updated `flutter_launcher_icons` configuration in `pubspec.yaml` to reference `#11392E`.
  - Added `*.ps1` to `.gitignore` to prevent temporary PowerShell scripts from being tracked.

---

## [1.11.8] - 2026-11-01

### Changed
- **Botanical Forest Theme Contrast & Visual Refinement (Lush Emerald Depth):**
  - Replaced dead near-black charcoal background (`#101713`) with a richer, organic night pine green (`#121D17`).
  - Elevated card surfaces from `#18221C` to `#1E3026` with crisp pine borders (`#2F473A`), giving all financial cards, wallet balances, and transaction lists a distinct floating depth.
  - Enhanced contrast and legibility for secondary typography, inactive navigation icons (`#7E9687`), dialogs (`#253C2F`), and synchronized design tokens across mobile and web landing page (`docs/style.css`).

---

## [1.11.7] - 2026-11-01

### Added
- **Official Brand Lore & Philosophy (In-App & Landing Page):**
  - Added dedicated **About Wall o' Pay** modal sheet in app settings (`settings_page.dart` -> `about_sheet.dart`) featuring complete bilingual explanation of the 4 core pillars: The Protective Wall (financial shield & offline sovereignty), The Growing Sprout ("Pay yourself first"), The Guiding Star (milestone clarity), and The Botanical Sanctuary (mindful peace).
  - Added a responsive **Brand Philosophy & Lore** section to the web landing page (`docs/index.html`) linking directly from the navigation bar.
  - Included app metadata, MIT open-source license information, quick links to changelog and user feedback.

---

## [1.11.6] - 2026-11-01

### Changed
- **Signature Botanical Forest Brand Icon & Visual Identity:**
  - Adopted new brand icon (Variasi 1) featuring the elegant white rounded "W" monogram, sprouting botanical leaf, and celestial star against a deep emerald forest gradient (`#11392E`).
  - Updated all Android adaptive launcher icons (`mipmap-*/ic_launcher.png`, `drawable-*/ic_launcher_foreground.png`, `colors.xml`, and `ic_launcher.xml`) with safe-zone compliance for squircle, circle, and rounded rectangle masks.
  - Replaced in-app brand mark (`assets/images/logo.png`), landing page brand showcase (`docs/images/logo.png`), and web favicons (`docs/favicon.png`, `docs/images/icon.png`).

---

## [1.11.5] - 2026-11-01

### Fixed
- **Account Deletion & Data Wipe Hardening:**
  - Automatically cancels all scheduled daily notification alarms when an account is deleted to prevent orphan notifications.
  - Clears device-level onboarding flags (`onboarding_done_$uid`) to ensure complete data hygiene upon permanent deletion.

---

## [1.11.4] - 2026-11-01

### Added
- **Multi-Device Personalization & Settings Cloud Sync:**
  - Integrated `FeaturePrefs` (daily reminder toggle, reminder time, budget alerts, and budget rollover) into Cloud Firestore (`meta/preferences`).
  - Added cloud synchronization for privacy balance visibility toggle (`hideBalance`) and account onboarding completion status (`onboardingDone`).
  - Switching to a new device or logging in on multiple phones now instantly restores all user preferences, notification schedules, and skips completed onboarding automatically without requiring manual reconfiguration.

### Changed
- **Settings Menu Hierarchy & Offline Backup Clarification:**
  - Renamed offline file backup section to **Manual Backup & Export** (`Cadangan Manual & Ekspor`) to clearly distinguish between automated real-time Cloud Sync and manual JSON/CSV archives for privacy-conscious offline users.

---

## [1.11.3] - 2026-11-01

### Changed
- **Pure Android Native Layout Alignment:**
  - Removed desktop-specific container wrappers in `MaterialApp`, restoring 100% native edge-to-edge mobile rendering and IME keyboard behavior for Android.

### Fixed
- **Comprehensive Bilingual Localization Audit:**
  - Audited and localized over 25 previously untranslated or mismatched UI phrases across accounts, recurring schedules, home shortcuts, transfer menus, and pending review sheets in both Indonesian and English.
  - Standardized action label capitalization across pages to match global translation dictionaries.

---

## [1.11.2] - 2026-11-01

### Fixed
- **Onboarding Skip & Finish Transition on Desktop / Offline Mode:**
  - Resolved an issue where clicking "Skip" or "Finish" in Onboarding Step 4 failed to transition to the main app dashboard. Replaced fragile `FutureBuilder` snapshot caching with deterministic state management in `OnboardingGate`.
  - Added comprehensive `try-catch` safety around database setup operations in `OnboardingPage` to prevent saving state deadlocks.
- **Persistent Offline / Desktop Authentication Bypass:**
  - Persisted "Continue without account" (`skipAuthProvider`) into `SharedPreferences`. The app will now remember offline mode on subsequent launches on desktop or environments without Firebase initialized.

### Added
- **Responsive Max-Width Container for Desktop & Tablets:**
  - Wrapped root app view in a centered, max-width constrained container (`maxWidth: 540`) with atmospheric dark background margins to provide an optimal reading and navigation experience on widescreen PC / laptop displays without awkwardly stretched layouts.

---

## [1.11.1] - 2026-11-01

### Added
- **Total Balance Privacy Toggle on Accounts Page:**
  - Added visibility toggle button (eye icon) directly to the `HeroCard` on the Accounts page, matching the Home screen header.
  - Allows users to instantly hide or reveal all sensitive account balances and category subtotals directly from the Accounts screen with one tap.
  - Perfectly synchronized with the global `hideBalanceProvider` and fully localized in English and Indonesian.

---

## [1.11.0] - 2026-11-01

### Added
- **Categorized & Sub-Categorized Account Architecture:**
  - Grouped all user accounts into dedicated categories by type: **Commercial Bank**, **Digital Bank**, **E-Wallet**, and **Cash**.
  - Added stylish section headers for each active category displaying category icon, category title, account count badge, and real-time category subtotal.
  - Automatically sorts accounts within each category by balance descending, placing primary high-balance accounts at the top.
  - Clean, frictionless user experience without manual drag handles (Opsi A).
  - Empty categories with zero accounts are automatically hidden to keep the layout clean and compact.
  - Full bilingual localization: English ("Commercial Bank", "Digital Bank", "E-Wallet", "Cash") and Indonesian ("Bank Konvensional", "Bank Digital", "E-Wallet", "Tunai").

---

## [1.10.0] - 2026-11-01

### Added
- **Drag-and-Drop Custom Account Ordering:**
  - Added interactive drag-and-drop reordering for accounts in the Accounts page using `SliverReorderableList` and `ReorderableDragStartListener`.
  - Added intuitive drag grip handles (`Icons.drag_indicator_rounded`) when multiple accounts exist, allowing effortless position customization.
  - Tapping cards continues to smoothly open account editing without touch conflicts.
  - Custom display order is stored in `SharedPreferences` (`pref_wallet_order`) without requiring SQLite schema alterations, maintaining 100% offline-first reliability.
  - Custom ordering automatically synchronizes across all application touchpoints, including the "Your accounts" list, the Home screen account chips, and wallet selection in transaction forms.
  - Added bilingual localization for the drag-to-reorder action hint (*"Drag to reorder"* / *"Tahan & geser untuk urutkan"*).

---

## [1.9.2] - 2026-11-01

### Fixed
- **Accurate Total Balance Calculation:**
  - Resolved balance discrepancy where `Total Balance` included phantom amounts from deleted or orphaned legacy wallets.
  - Constrained `totalCurrentBalanceProvider` to strictly calculate the sum of active wallets displayed in "Your accounts".

### Changed
- **Streamlined Account Balance Experience:**
  - Simplified label from "Starting balance" to "Balance", prefilling the current real-time balance when editing an existing account.
  - Automatically calculates initial offset when adjusting account balances, keeping transaction ledgers consistent while instantly updating the account to the user's entered balance.
  - Prevented orphaned transactions by dynamically defaulting new transactions to the primary active wallet instead of hardcoded fallbacks.

---

## [1.9.1] - 2026-11-01

### Changed
- **Home Header Layout Optimization:**
  - Placed conversational time-based greeting (*Selamat pagi* / *Good morning*) on the top line in a subtle style, followed by the user's name prominently displayed on the second line.
  - Eliminated redundant "Hello," prefix and emojis, providing full horizontal width so long names never get truncated.
- **Unified Period Switcher Across Main Tabs:**
  - Relocated the date range switcher on the Transactions page into the curved Deep Forest `pageAppBar` header (`bottomHeight: 44`), perfectly standardizing header height and date navigation across Transactions, Budget, and Insights.
  - Formatted active custom date range filter as a white chip within the header.

---

## [1.9.0] - 2026-11-01

### Added
- **Dedicated Accounts & Wallets Management (`AccountsPage`):**
  - Introduced an all-in-one accounts hub showing total balance, account types (Cash, Bank, Digital Bank, E-Wallet), individual balances, and recent transfer history.
  - Added inter-account transfer modal bottom sheet (`showTransferSheet`) with fee handling and custom transfer notes.
  - Added account editing and non-destructive archiving (`showAccountForm`).
- **3-Tab Deterministic Financial Insights:**
  - Restructured Insights into 3 intuitive tabs: Overview (Ringkasan), Categories (Kategori), and Trend (Tren).
  - Overview tab highlights hero period delta, period comparison, smart recommendations, daily/weekly expense distribution, and top 3 categories.
  - Categories tab features needs vs wants breakdown, category progress bars, and expense composition pie chart.
  - Trend tab includes 6-period historical trend bar chart and a comprehensive income vs expense period breakdown table (`_TrendTable`).
- **Transaction Summary Tiles & Empty State Improvements:**
  - Added quick-glance Total Income and Total Expense `_SummaryTile` widgets on the Transactions page.
  - Added encouraging `EmptyStateCard` with positive action buttons for empty periods.

### Changed
- **Curved Sheet Header Architecture:**
  - Integrated Deep Forest top sheet edges with smooth 28px bottom radii across Home, Budget, and Insights screens.
  - Embedded `PeriodSwitcher(onDark: true)` directly into page app bar headers for seamless period navigation.
  - Modernized quick action buttons with refined circular container styling on the Home page.
  - Added savings percentage indicator badge to the Home balance card.

---

## [1.8.7] - 2026-10-30

### Added
- **Monthly Start Day (Payday Cycle Configuration):**
  - Added "Monthly Start Day" option in Preferences (Settings), allowing users to pick any day from 1 to 28 (e.g. Payday on the 25th).
  - Updated `Period.containing`, `Period.shift`, and budget period key generation (`2026-10-25`) to accurately compute custom monthly salary cycles (e.g. `25 Oct – 24 Nov 2026`).
  - Added local persistence and cloud synchronization (`pref_first_day_of_month`) in `AppPrefs` and Firestore user preferences.
- **Synchronized Global Balance Masking:**
  - Integrated `hideBalanceProvider` into both the Home overview card and the "Wallets & Accounts" horizontal carousel cards.
  - Hiding or showing balance on the Home card now instantaneously masks/unmasks all wallet balances (`Rp ••••••`), ensuring complete privacy across the interface.

### Changed
- **Unified Signature Botanical Forest Theme:**
  - Standardized Wall o' Pay into an exclusive, curated Signature Botanical Forest visual identity instead of generic light/dark toggles.
  - Crafted an elevated, nature-inspired palette combining Night Pine Charcoal (`#101713`), Velvet Forest card surfaces (`#18221C`), Deep Forest accents (`#234B3B`), and soft Sage (`#A9C5B1`).
  - Updated Theme settings preview card displaying the signature aesthetic badge.

---

## [1.8.6] - 2026-10-30

### Fixed
- **Budget Zeroing & Cloud Sync Reversion Prevention:**
  - Resolved issue where setting the total budget to 0 on the Budget page reverted back to the previous amount (e.g. Rp 1.000.000) upon triggering "Sync Cloud" or "Send to Cloud".
  - Replaced Firestore document map merge (`SetOptions(merge: true)`) in `uploadToCloud` with clean document replacement, preventing deleted or zeroed period budget keys from lingering in Firestore.
  - Implemented local `_kUpdated` timestamp tracking in `BudgetRuleNotifier` and conflict resolution in `applyRemoteData` so older cloud snapshots never overwrite fresh local user budget changes.
  - Explicitly stored zero amounts (`0`) for zeroed period keys across state, SharedPreferences, and Firestore.

---

## [1.8.5] - 2026-10-30

### Added
- **Manual Cloud Sync Operations (Send to Cloud & Fetch from Cloud):**
  - Added dedicated manual action buttons in Settings under *Cloud Sync & Storage*:
    - **Send to Cloud (Upload)**: Forces an immediate push of all local SQLite records (wallets, categories, transactions, budgets, savings goals, recurring rules, debts, templates, user profile, budget configuration, and preferences) to Firebase Firestore with an item count confirmation toast.
    - **Fetch from Cloud (Download)**: Pulls all remote records from Firestore into the local device database.
    - **Sync Now (Two-Way)**: Executes complete bidirectional synchronization.
  - Enhanced real-time sync status indicator with active, syncing, and error state chips alongside last-synced timestamp display.
- **In-App Version Changelog & Release Notes Viewer:**
  - Added an interactive Version Changelog sheet in Settings (*About & Updates*) displaying recent release highlights, patch notes, and version history.
  - Designed with full offline availability, categorized change badges (`ADDED`, `CHANGED`, `FIXED`), and complete bilingual (English/Indonesian) support matching app design tokens.

---

## [1.8.4] - 2026-10-30

### Fixed
- **CI Build Pipeline & Maven Central Rate-Limiting:**
  - Resolved `HTTP 429 Too Many Requests` error from Maven Central (`repo.maven.apache.org`) on GitHub Actions Ubuntu runners during Gradle dependency resolution (`dev.flutter.flutter-plugin-loader` & Kotlin BOM).
  - Configured Google Cloud's official high-performance Maven Central mirror (`https://maven-central.storage-download.googleapis.com/maven2/`) with primary priority in `android/settings.gradle.kts` and `android/build.gradle.kts`.
  - Integrated `gradle/actions/setup-gradle@v4` into `.github/workflows/release.yml` for automated caching of Gradle wrappers and dependency artifacts.
  - Added an automated retry loop (up to 3 attempts with 15s backoff) for the release APK compilation step in CI to guard against transient network glitches.

---

## [1.8.3] - 2026-10-30

### Fixed
- **Permanent Account Deletion & Complete Cloud/Local Data Wipe:**
  - Resolved issue where deleting an account failed to release the username reservation or erase financial data from Firestore and local storage.
  - Implemented direct document deletion by ID for `usernames/{username}` across multiple fallback sources (known username, `user.displayName`, root user document, and index query), guaranteeing that deleted usernames can immediately be registered again.
  - Enhanced `AutoSyncService.wipeCloudUserData()` with batched deletion (`WriteBatch`), 15s timeouts, and snake_case + camelCase collection coverage across all subcollections (`categories`, `wallets`, `transactions`, `budgets`, `savingsGoals`, `recurringRules`, `debts`, `txTemplates`, `pendingTransactions`, `meta`).
  - Added `ProfileController.clearLocal()` to erase cached profile nicknames and avatars from SharedPreferences upon logout or account deletion.
  - Re-ordered the account deletion flow to ensure cloud and local wiping succeed while still fully authenticated before invoking `user.delete()`.
- **Wallet & Account Multi-Language Localization:**
  - Resolved issue where Wallets & Accounts balance cards showed Indonesian names ("Rekening Utama", "Bank Digital", "Tunai") even when English was selected.
  - Standardized default wallet seeds to English keys (`Main Account`, `Digital Bank`, `Cash`, `E-Wallet`) and added an automatic SQLite self-healing update in `beforeOpen`.
  - Added dynamic bi-directional English-to-Indonesian and Indonesian-to-English translation mapping in `AppStrings.tr()` for default wallet names so both new and existing local databases render seamlessly in English or Indonesian.

---

## [1.8.2] - 2026-10-30

### Fixed
- **Authentication & Sign Out Execution Pipeline:**
  - Resolved issue where pressing "Log out" failed to sign out the user. The previous implementation executed `Navigator.popUntil((r) => r.isFirst)` prematurely and threw an unhandled `SqliteException` during `resetAllData()`, aborting before `FirebaseAuth.instance.signOut()` was ever reached.
  - Refactored `_signOut()` in `SettingsPage` to show a non-dismissible loading indicator (`Logging out...`), perform database reset and cache clearing safely inside defensive `try ... catch` blocks, and pop back to `AuthGate` only after `FirebaseAuth.instance.signOut()` completes.
- **SQLite Database Migration & Self-Healing:**
  - Fixed missing Drift table creation in `onUpgrade` for `debts` and `tx_templates` introduced in v1.8.0.
  - Bumped database schema version to 8 with automated migration for existing installations.
  - Added self-healing `CREATE TABLE IF NOT EXISTS` checks in `beforeOpen` for `debts` and `tx_templates` to ensure zero database crashes across all update pathways.
  - Wrapped `delete(debts)` and `delete(txTemplates)` in `resetAllData()` defensively.

---

## [1.8.1] - 2026-10-30

### Fixed
- **Insight Tab Multi-Language Localization:**
  - Resolved issue where the Financial Insight tab remained in Indonesian even when the application language was switched to English.
  - Replaced all Indonesian string literals in `InsightsPage` and `InsightEngine` with standard English translation keys, and populated comprehensive Indonesian translations in `l10n_extra.dart`.
- **Multi-Device Budget & Cloud Synchronization:**
  - Fixed sync initiation bug where `AutoSyncService` failed to launch when a user logged in or cold booted because sync was only checked once in `HomePage.initState()`. Added reactive `currentUserProvider` listeners in `HomeShell` and post-frame callback triggers.
  - Added `applyRemoteData` to `BudgetRuleNotifier` and `AppPrefsController` to immediately ingest real-time Firestore snapshots for `budgetConfig` and `preferences` without redundant network roundtrips.
  - Resolved `Budget` SQLite uniqueness and resurrection issues: when re-setting a budget with an amount > 0, `deletedAt` is now properly reset to null, and duplicate entries with conflicting IDs are defensively merged.
  - Integrated `debts` and `txTemplates` into SQLite `syncTables`, manual backup/restore, cloud wiping, and local database resetting.

---

## [1.8.0] - 2026-10-30

### Added
- **Debts & Bill Splitting Module (`DebtsPage`):**
  - Track money lent to and borrowed from contacts with due dates, notes, and remaining balance tracking.
  - Record partial or full debt repayments with automatic optional sync to transaction history.
  - Interactive Bill Splitting calculator to divide restaurant, travel, or group expenses fairly with automatic debt item generation.
- **Exportable PDF Financial Statement Reports (`ReportService` & `ReportDialog`):**
  - Generate and share comprehensive, beautifully formatted PDF financial reports for any custom date range or calendar month.
  - Detailed reporting includes net cashflow summary, category spending breakdown, wallet balances, and full transaction tables.
- **Local Push Notifications & Automated Budget Alerts (`NotificationService`):**
  - Integrated local notification engine using `flutter_local_notifications` and `timezone`.
  - Configurable daily reminder nudge at a user-selected time to record daily spending.
  - Real-time budget threshold warnings when a category exceeds 80% and 100% of its budgeted allowance.
- **Quick Transaction Templates:**
  - Save frequently logged transactions as quick templates with one tap from the transaction sheet.
  - Single-click quick action chips at the top of the transaction form to instantaneously pre-fill recurring expenses.
- **Need vs. Want Tracking & Insight Integration:**
  - Added optional Need/Want classification to all expense entries.
  - Enhanced the Insight tab with a dedicated "Needs vs. Wants" visual distribution bar and automated smart spending health recommendations.
- **Transactions Date Range Filter:**
  - Added custom date range filtering on the Transactions page alongside the existing search query filter.
- **More Hub Navigation (`MorePage`):**
  - Centralized Quick Hub accessible directly from the Home screen quick actions, linking Transfers, Debts & Splits, Recurring, Insight, PDF Reports, and Settings.
- **Budget Rollover Support:**
  - Preference setting to automatically carry over leftover unspent budget from previous periods into the current active period.
- **Interactive First-Launch Onboarding (`OnboardingGate` & `OnboardingPage`):**
  - Intuitive initial walkthrough allowing new users to set initial cash balances and configure primary preferences.

### Changed
- Upgraded Drift SQLite schema to version 7 with support for `Debts`, `TxTemplates`, and transaction `needWant` attributes.
- Enabled Android core library desugaring for notification scheduling across all Android API levels.

---

## [1.7.0] - 2026-10-30

### Added
- **New Financial Insight Tab:**
  - Replaced the low-usage standalone "Target" tab in the bottom navigation bar with a dedicated, comprehensive **Insight** tab. (Savings goals remain fully managed under the Budget tab's "Savings & Goals" bucket for 100% backward compatibility and zero data loss).
  - Designed in Wall o' Pay's signature dark aesthetic, Deep Forest green hero cards, bright typography, and minimalist financial charts.
  - **Period Financial Summary (Income, Expense, Net Difference):**
    - High-contrast HeroCard presenting total income, total expenditure, and net surplus or deficit alongside savings rate percentage.
  - **Period-over-Period Spending Comparison:**
    - Dynamic comparison comparing current spending vs previous period (week or month), highlighting percentage changes, delta amounts saved or increased, and contextual encouragement.
  - **Interactive Expense Trend Chart:**
    - Custom minimalist bar chart (`fl_chart`) with touch tooltips and background guide rods, displaying daily spend distributions in weekly mode and weekly intervals in monthly mode, accompanied by run-rate averages.
  - **Top Spending Categories Breakdown:**
    - Ranked leaderboard of highest expenditure categories with category badges, amounts, transaction frequencies, share percentages, and period-over-period shift indicators.
  - **Smart Financial Insights Engine:**
    - Deterministic analytic generator computing real-time actionable findings: category spend surges/drops, single largest transactions, peak spending days, and cashflow health assessments.
  - **Low-Data Friendly State:**
    - Informative onboarding card when fewer than 3 expense transactions exist, inviting users to record transactions rather than rendering empty or broken charts.

---

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
