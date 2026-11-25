# Changelog 📋

All notable changes to the **Wall o' Pay** modern & offline-first personal financial management project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2026-11-25

### Added
- **Global Multi-Currency Support (IDR Default + 6 Global Currencies):**
  - Added `AppCurrency` registry in `lib/core/format.dart` supporting `IDR` (`Rp`, default), `USD` (`$`), `EUR` (`€`), `GBP` (`£`), `SGD` (`S$`), `MYR` (`RM`), and `JPY` (`¥`) with locale-aware thousand separators, compact chart/chip abbreviations, dynamic quick-amount chips, and dynamic admin fee presets without breaking existing SQLite data.
  - Added `currencyCode` persistence in `AppPrefs` (`lib/data/prefs.dart`), JSON backup export/import, Cloud Firestore preference sync, and owner-scoped validation in `firestore.rules`.
  - Added Currency selector in `SettingsPage` and `OnboardingPage` (Step 1), and expanded `TransactionParser.extractAmount` to parse both Indonesian (`Rp`/`IDR`) and global currency formats (`$`, `USD`, `EUR`, `GBP`, `SGD`, `MYR`, `RM`, `JPY`).
- **Bilingual (`EN | ID`) & Multi-Currency Landing Page (`docs/`):**
  - Added an accessible `EN | ID` language toggle (defaulting to `EN`) in the landing page header/mobile drawer and an interactive `IDR · Rp | USD · $` currency preview toggle synced across the phone mockups, Android widgets showcase, and live budget calibrator.

## [3.1.4] - 2026-11-25

### Changed
- **Landing Page Multi-Device Responsive & Motion Audit (`docs/`):**
  - Audited and refined `docs/index.html`, `docs/style.css`, and `docs/script.js` across mobile (`320px–480px`), tablet (`640px–1024px`), and desktop (`1025px–1440px+`) viewports.
  - Expanded the mobile/tablet navigation drawer breakpoint to `<= 960px` with origin-aware transitions, accessible `44×44px` touch targets on calibrator tick buttons, a skip-to-content link, `<main>` landmark, `aria-live="polite"`, and `tabular-nums` on dynamic financial readouts.
  - Replaced continuous infinite pulse/float animations and static-card hover lifts with a one-time hero entrance animation and tactile readout morph transitions.

## [3.1.3] - 2026-11-25

### Added
- **ABI-Aware In-App Updates & Landing Page Notice:**
  - Exposed Android `Build.SUPPORTED_ABIS` via `MainActivity` and updated `UpdateCheckerService` to automatically select the matching per-ABI APK (`arm64-v8a`, `armeabi-v7a`, or `x86_64`) with safe fallback to `Wall_o_Pay.apk`.
  - Updated `docs/script.js` to deterministically prefer `Wall_o_Pay.apk` (`arm64-v8a`) and added an ABI compatibility note linking to GitHub Releases on `docs/index.html` for 32-bit and emulator users.

## [3.1.2] - 2026-11-25

### Changed
- **Tablet & Landscape Responsive Layout:**
  - Switched `HomeShell` automatically from `BottomAppBar` to a compact `NavigationRail` on landscape/medium widths (`>= 600dp`) and an extended `NavigationRail` on tablets/desktops (`>= 900dp`), with a centered `maxWidth: 920` content shell.
  - Constrained modal bottom sheets globally to `maxWidth: 640` and centered the `AuthPage` form within `maxWidth: 520` on wide screens.
  - Replaced fixed column counts in the profile avatar and frame customizer grids with adaptive `SliverGridDelegateWithMaxCrossAxisExtent` layouts.

## [3.1.1] - 2026-11-25

### Changed
- **APK Size Optimization (`--split-per-abi` & Asset Compression):**
  - Enabled `--split-per-abi` in the release workflow so each Android architecture (`arm64-v8a`, `armeabi-v7a`, `x86_64`) ships in its own slim APK, with `Wall_o_Pay.apk` defaulting to `arm64-v8a`.
  - Compressed and downscaled oversized image assets across `assets/` (from 42.97 MB down to 7.38 MB, saving 35.59 MB / 82.8%) without altering visual fidelity or asset paths.

## [3.1.0] - 2026-11-25

### Added
- **Full Vice City Sunset Design Asset Suite (59 Production Assets):**
  - **Wendy Financial Companion:** High-fidelity 3D mascot integration across Daily Financial Pulse card with 10 interactive expression states and localized velocity tips.
  - **Wendy Chibi Avatar Picker:** 12-sticker chibi avatar picker in `ProfilePage` for app-wide user profile personalization.
  - **3D Financial Props & Milestone Poses:** Deployed dedicated 3D props and companion poses across 50/30/20 Smart Pools, Bank & Cash accounts, Savings Target goals, Debt settlement celebrations, and Report Export workflows.
  - **New 3D Wendy Companion Launcher Icons:** Multiplatform icon suite across Android, iOS, Web, and Windows with sunset city skyline and neon 3D glowing "Wall o' Pay" wordmark.
- **Enhanced Mascot Showcase:** Dedicated companion card in About Wall o' Pay sheet with sunset panorama and official brand identity.

### Changed
- **Unified Typography System:** Upgraded typography to `Outfit` (editorial & tabular financial figures), `Inter` (product UI & body), and `JetBrains Mono` (status telemetry & tags) across both Flutter app and landing page.
- **Web Landing Page Complete Polish (`docs/`):**
  - Upright zero-tilt interactive phone mockups with realistic data, mini-stat strip, SVG trajectory chart, and GPU-accelerated progress bars.
  - Vice City Sunset horizon atmosphere with OLED midnight gradient (`#070B14`), warm sunset magenta & cyan rim lighting, atmospheric vignettes, and streamlined wordmark header/footer.
  - Multi-resolution downsampled favicons (16×16 to 192×192) for sharp cross-browser display.

### Fixed
- **UI/UX Contrast & Accessibility (WCAG AA):**
  - Calibrated contrast for buttons, chips, segmented selectors, input helper text, and navigation bars.
  - Expanded touch targets to 48×48dp, disambiguated icons, and added comprehensive `Semantics` and `prefers-reduced-motion` compliance.

## [3.0.20] - 2026-11-25

### Changed
- **Landing Page Favicon Update (`docs/`):**
  - Replaced `docs/favicon.ico`, `docs/favicon.png`, `docs/apple-touch-icon.png`, and `docs/images/icon.png` with `assets/new_asset/props/prop_11.png` using calibrated transparent margins and multi-resolution Lanczos downsampling (16×16, 32×32, 48×48, 180×180, 192×192).

## [3.0.19] - 2026-11-25

### Changed
- **Key Art Tonal Blending & Edge Vignette (`docs/style.css`):**
  - Added an atmospheric inset edge vignette overlay (`.key-art-media-wrap::after`), calibrated image saturation/brightness (`saturate(0.86) brightness(0.90) contrast(1.04)`), and softened the card border with a sunset halo so the banner blends naturally into the dark OLED canvas.

## [3.0.18] - 2026-11-25

### Changed
- **Key Art Showcase Refinement (`docs/index.html`, `docs/style.css`):**
  - Balanced headline line wrapping (`text-wrap: balance`, wider header container) to prevent orphan words, equalized vertical section padding, removed the redundant caption bar under the banner, and removed misleading hover lift/zoom from the non-interactive key art frame.

## [3.0.17] - 2026-11-25

### Fixed
- **UI/UX Contrast, Touch Targets & Accessibility:**
  - Improved WCAG AA contrast for `onPrimary`, selected `SegmentedButton`, selected `Chip` labels (`AppColors.midnightNavy` on `sunsetMagenta`), inactive bottom navigation items, and input hint/helper text (`lib/core/theme.dart`, `lib/core/widgets.dart`, `lib/app.dart`).
  - Expanded `_HomeHeader` action button touch targets to `48×48dp` (`lib/features/home/home_page.dart`) and disambiguated the date-range filter icon from the cashflow calendar icon in `TransactionsPage` (`lib/features/transactions/transactions_page.dart`).
  - Added `Semantics`, `MergeSemantics`, `ExcludeSemantics`, `SemanticsService.announce`, and `MediaQuery.disableAnimationsOf` support across navigation, transaction rows, decorative backdrops, and `SplashPage`.
- **App Launcher Icon & Brand Logo Update:**
  - Updated the multiplatform app launcher icon (`assets/images/app_launcher_icon.png`) and the in-app brand logo (`assets/images/logo.png`).

## [3.0.16] - 2026-11-25

### Changed
- **Unified Typography System (`Outfit` + `Inter` + `JetBrains Mono`):**
  - Upgraded both the Flutter application (`lib/core/theme.dart`) and the GitHub Pages landing page (`docs/index.html`, `docs/style.css`) from `Space Grotesk` / `IBM Plex Mono` to `Outfit` (editorial display & tabular financial figures), `Inter` (product UI & body), and `JetBrains Mono` (status metadata & telemetry).

## [3.0.15] - 2026-11-25

### Changed
- **Vice City Sunset Horizon Atmosphere (`docs/style.css`):**
  - Enriched the landing page background with warm Sunset Magenta, Sunset Orange, and Golden Amber horizon lighting balanced against Electric Cyan coastal reflections, plus warm-tinted horizontal gridlines and sunset-rimmed alternating section bands.

## [3.0.14] - 2026-11-24

### Changed
- **Landing Page Atmospheric Background & Section Rhythm (`docs/style.css`):**
  - Replaced the flat `#090D16` canvas with an OLED midnight gradient (`#070B14`), a subtle 48px architectural grid masked radially toward the viewport center, and stronger Sunset Magenta / Electric Cyan atmospheric horizon lighting.
  - Added full-bleed alternating elevated surface bands with crisp top/bottom hairline borders across `#interactive`, `#architecture`, and `#art-direction` for clear visual hierarchy.

## [3.0.13] - 2026-11-24

### Changed
- **Landing Page Interactive Phone Mockup Redesign (`docs/`):**
  - Rebuilt the dual phone hardware mockups in the Interactive Engine section (`docs/index.html`, `docs/style.css`, `docs/script.js`) with an upright, zero-tilt staggered-depth composition so both screens remain 100% legible without clipped text.
  - Replaced emoji status and navigation icons with crisp inline SVGs, added `tabular-nums` alignment, a 3-column mini-stat strip, two realistic recent activity rows, an SVG area-line trajectory chart, and a 3-bar allocation/telemetry breakdown card to eliminate empty screen voids.
  - Added GPU-accelerated `scaleX` progress bars and subtle materializing (`opacity` + `translateY` + `blur`) mode-switch transitions respecting `prefers-reduced-motion`.

## [3.0.12] - 2026-11-24

### Changed
- **Landing Page Favicon Suite Upgrade:**
  - Upgraded the official GitHub Pages landing page favicon and bookmark icons across `docs/favicon.ico`, `docs/favicon.png`, `docs/apple-touch-icon.png`, and `docs/images/icon.png` using `assets/new_asset/props/prop_05.png`.
  - Processed with calibrated transparent margins and multi-resolution downsampling (16x16, 32x32, 48x48, 180x180, and 192x192) for sharp, high-contrast display across all desktop browsers and mobile homescreen shortcuts.

## [3.0.11] - 2026-11-24

### Added
- **New 3D Wendy Companion App Icon & Multiplatform Launcher Suite:**
  - Upgraded application launcher icons across Android (`mipmap-*`), iOS (`Assets.xcassets`), Web (`web/icons/`), Windows (`app_icon.ico`), and web landing page (`docs/images/logo.png`, `icon.png`, `apple-touch-icon.png`, `favicon.ico`).
  - Features the high-fidelity 3D Wendy financial companion illustration with tropical sunset city skyline, sunglasses, smartphone, financial growth indicator, gold coins, and 3D glowing neon "Wall o' Pay" wordmark.

### Changed
- **Web Landing Page Brand Simplification:**
  - Streamlined both the header navigation bar and the footer on the GitHub Pages website (`docs/index.html`) by removing the adjacent emblem icon, highlighting the custom 3D glowing script wordmark cleanly.
- **Companion Experience & Onboarding Alignment:**
  - Enlarged Wendy companion avatars to half-body/bust portraits in `DailyFinancialPulseCard` and Settings Cloud Sync card for clear facial expressions.
  - Streamlined onboarding guidance flow to exclusively showcase the mascot companion on the initial Welcome screen, relocating auxiliary milestone poses to empty state illustrations across Accounts and Recurring features.
  - Enhanced Splash Screen with the official glossy neon 3D script wordmark.

## [3.0.10] - 2026-11-24

### Added
- **Full Vice City Sunset Design Asset Suite Integration (59/59 Assets):**
  - Systematically integrated all 59 production design assets across 7 distinct categories (expressions, poses, props, chibi stickers, UI illustrations, background, and custom typography).
  - **Wendy Chibi Avatar Picker:** Added a 12-sticker chibi avatar picker directly in `ProfilePage`, allowing users to select official Wendy stickers as their app-wide profile avatar.
  - **10-Expression Interactive Advice Carousel:** Upgraded `DailyFinancialPulseCard` with an interactive 10-expression advice sheet and localized financial velocity tips from Wendy.
  - **3D Financial Props:** Integrated specialized props for 50/30/20 Smart Pools (Needs, Wants, Savings), Bank & Cash account category headers, savings target coins & piggy bank, net worth vitality diamond, calculator badge, receipt attachment tag, and hardware keystore & biometric indicators.
  - **Workflow Milestone Poses:** Deployed specialized Wendy companion poses for Cash & Allowance onboarding, PDF report export, calculator helper, cloud sync status, debt settlement celebration, destructive erase confirmation dialog, and empty search filters.
  - **Official Wendy Mascot Showcase:** Added a dedicated mascot companion showcase card in the "About Wall o' Pay" sheet with custom Vice City background and neon script wordmark.

### Changed
- **Asset Optimization:** Excluded raw unoptimized collage sheets (`packs/` and `character/`), saving over 7.28 MB of APK package bloat while ensuring 100% purposeful utilization of all component assets.

## [3.0.9] - 2026-11-24

### Changed
- **Official Companion Mascot Renamed to Wendy:**
  - Formally updated the official name of the financial companion mascot to **Wendy** across the web landing page (hero alt, mockup profile, Key Art badge) and within the mobile app (Daily Financial Pulse advice sheets and localized strings).

## [3.0.8] - 2026-11-24

### Changed
- **Horizontal Glossy Script Wordmark Upgrade:**
  - Upgraded landing page brand logotype in navigation and footer to the horizontal glossy neon 3D script wordmark (`logo_wordmark_glossy_neon.png`).
  - Optimized scaling and bounds to deliver significantly larger, crisper, and more prominent brand legibility across all desktop and mobile viewports.

## [3.0.7] - 2026-11-24

### Changed
- **Web Brand Wordmark Typography:**
  - Upgraded the plain text "Wall o' Pay" in the landing page floating header and footer to the custom high-DPI tropical neon script wordmark (`logo_wordmark.png`).
- **Hero Dashboard Clean Layout:**
  - Removed the floating `0ms Local SQLite Calibrated` badge overlay beside the Olivia companion mascot for a cleaner and more focused hero visual presentation.

## [3.0.6] - 2026-11-24

### Added
- **Dynamic Mascot Companion Reactions:**
  - Integrated dynamic Olivia companion mascot expressions into `DailyFinancialPulseCard` (`expression_01.png` for safe velocity, `expression_03.png` for caution pace, `expression_06.png` for limit approaching).
  - Tapping the companion avatar opens an interactive localized financial wellness bottom sheet with personalized velocity insights and budget advice.
- **Goal Celebration Mascot Modal:**
  - Added celebratory Chibi cheering mascot modal (`chibi_01.png`) when tapping completed savings goals on `GoalsPage`.
- **Interactive Companion Avatar on Web Mockup:**
  - Added reactive Olivia Chibi avatars to the interactive cashflow command engine on the landing page (`docs/`), syncing companion expressions dynamically with each mode tab (`pulse`, `pools`, `rapid`, `debt`).
- **Tropical Neon Wordmark Signature:**
  - Integrated the custom Vice City Sunset tropical neon wordmark into the "About Wall o' Pay" sheet.

## [3.0.5] - 2026-11-24

### Added
- **Custom Neon Wordmark & Typography Suite:**
  - Standardized and bundled custom neon logotypes in `assets/new_asset/custom_text/` (`logo_wordmark_glossy_neon.png` and `logo_wordmark_tropical_neon.png`).
  - Upgraded core app branding `assets/images/logo_wordmark.png` to the new Vice City Sunset tropical neon logotype, replacing legacy botanical assets.
  - Registered `assets/new_asset/custom_text/` in `pubspec.yaml`.

## [3.0.4] - 2026-11-24

### Added
- **Vice City Sunset Key Art Showcase & Social Previews:**
  - Integrated high-impact Vice City Sunset key art banner into `README.md` and Open Graph/Twitter Social Cards (`docs/images/og_banner.jpg`).
  - Added responsive frosted-glass Key Art showcase section on the landing page (`docs/`) following `taste-skill` (anti-slop layout), `ui-ux-pro-max` (mobile focal alignment), and `design-motion-principles` (Jakub Krehel tactile hover elevation & ambient glow).
- **Olivia Mascot & UI State Illustrations Suite:**
  - Standardized and bundled high-fidelity asset suite under `assets/new_asset/` (`ui/`, `character/`, `sticker/`, `poses/`, `expression/`, `props/`, `background/`).
  - Integrated `empty_wallet.png`, `empty_budget.png`, `no_data_state.png`, and `weekly_monthly_summary.png` into `resolveEmptyIllustration` across core empty states.
  - Added `onboarding_welcome.png` greeting mascot illustration on step 0 of onboarding.
  - Enhanced `_CompletedGoalCard` with celebratory `savings_achieved.png` achievement badge.
  - Added companion mascot health indicator (`dashboard_greeting.png` and `budget_warning.png`) to `DailyFinancialPulseCard`.

### Changed
- **Asset Pipeline Optimization & Standardization:**
  - Renamed all 63 raw asset files to idiomatic `snake_case` without spaces or special characters.
  - Downscaled oversized images (max 640px for UI/characters, 1280px for background) and applied PNG compression, reducing total bundle size from 31.49 MB to 13.46 MB (~57% savings).
  - Isolated root master packs into `packs/` archive directory outside the APK asset bundle.

## [3.0.3] - 2026-11-24

### Added
- **Hero Olivia Companion Mascot:**
  - Integrated high-resolution cutout illustration of financial companion mascot **Olivia** into the landing page Hero section (`docs/`).
  - Added Vice City Sunset ambient aura halo (`#FB7185` and `#38BDF8`), gentle floating animations, and interactive hover elevation.
  - Fully responsive on mobile and tablet with automatic vestibular accessibility under `prefers-reduced-motion`.

## [3.0.2] - 2026-11-24

### Fixed
- **Landing Page Data Export Badge Collision:**
  - Resolved class collision where data export chips (`PDF Reports`, `CSV Spreadsheets`, `Encrypted JSON`) mistakenly inherited `.app-version-tag`, causing them to be overwritten by GitHub Release API polling.
  - Introduced dedicated `.feature-badge-pill` class with high-contrast Vice City Sunset styling.
  - Implemented SemVer comparison guards in `docs/script.js` preventing release badge regressions when local codebase version is ahead of GitHub published releases.

## [3.0.1] - 2026-11-24

### Changed
- **Landing Page Redesign & Modernization:**
  - Overhauled GitHub Pages landing page (`docs/`) utilizing the tripartite frontend engineering stack: `ui-ux-pro-max`, `taste-skill`, and `design-motion-principles`.
  - Streamlined information architecture from 9 sprawling sections down to 6 high-impact, cohesive sections with disciplined 1-screen desktop viewport rhythm.
  - Purged legacy botanical tokens and class names, unifying the design system under high-contrast Vice City Sunset tokens with full WCAG AA contrast compliance.
  - Replaced native unicode emojis with crisp inline SVG vector iconography across all cards, chips, and app frames.
  - Implemented smooth spatial crossfade transitions across the interactive showcase panels with Jakub Krehel polish and Emil Kowalski restraint.
  - Enhanced touch targets (minimum 44x44px) and added full `prefers-reduced-motion` vestibular accessibility.

## [3.0.0] - 2026-11-21

### Added
- **Vice City Sunset Design System:**
  - Complete visual transformation centered on Slate Navy (`#0F172A`), Deep Navy (`#1E293B`), Sunset Rose (`#FB7185`), Sunset Amber (`#FBBF24`), Neon Cyan (`#38BDF8`), and Warm Emerald (`#10B981`).
  - Overhauled typography system utilizing Space Grotesk (headings and tabular figures), Inter (body readability), and IBM Plex Mono (metadata).
  - Integrated the iconic Neon Sunset Wallet "W" Emblem across all app launchers (Android adaptive mipmaps, iOS AppIcons, Web manifest/icons, Windows desktop).
  - 160-icon custom 3D transparent icon library across all primary and secondary navigation, categories, forms, filters, and settings.
  - 6 custom tropical neon empty-state illustrations for transactions, budgets, savings/goals, analytics, search, and notifications.
  - Panoramic coastal sunset skyline canopies and user profile card with authentic circular Vice City avatar frame.
- **Cloud Firestore Security Rules (`firestore.rules`):**
  - Added version-controlled Cloud Firestore Security Rules enforcing owner-only access (`request.auth.uid == uid`) across `/users/{uid}`, `/users/{uid}/meta/{docId}`, and all 15 synced financial subcollections with strict schema validation.
  - Protected `/usernames/{username}` against unauthenticated bulk enumeration or hijacking.

### Fixed
- **App PIN Lock & Keystore Security Hardening:**
  - Enforced full local SQLite data and cache wipe on Forgot PIN reset while preserving cloud-synced PIN until password re-authentication.
  - Migrated brute-force lockout counters (`fails`, `lockoutTier`, `lockoutUntil`) to `FlutterSecureStorage` (Android Keystore / iOS Keychain) with backward clock-tampering protection.
  - Enforced private notification visibility with redacted counterparty names and amounts for lock-screen debt due reminders.
- **Export, Sync & Reliability Hardening:**
  - Neutralized CSV formula injection triggers (`=`, `+`, `-`, `@`, `\t`, `\r`) with leading single quotes.
  - Restricted `_purgeLocalSensitiveFiles` to safe receipt directories, clamped far-future `updatedAt` timestamps, and added Android Share Intent stream copy bounds (10 MB cap).
  - Restricted in-app update URLs to official HTTPS GitHub release domains and added CI signing guards.

## [2.17.14] - 2026-11-21

### Changed
- **Vice City Sunset Branding Transition:**
  - Replaced remaining Botanical / Glasshouse branding in `AboutWallOPaySheet` (`lib/features/settings/about_sheet.dart`) and `lib/core/l10n.dart` with Vice City Sunset brand lore and philosophy.
  - Updated user-facing financial recap notification labels (`SettingsPage` and `NotificationService`) from `Harvest recap notifications` / `Weekly Harvest Review` / `Monthly Harvest Review` to `Financial recap notifications` / `Weekly Financial Review` / `Monthly Financial Review`.
  - Updated `README.md`, `ARCHITECTURE.md`, `AGENTS.md`, and `pubspec.yaml` description to reflect the Vice City Sunset theme and current typography/color tokens.

## [2.17.13] - 2026-11-21

### Added
- **Firestore Security Rules (`firestore.rules`):**
  - Added version-controlled Cloud Firestore Security Rules enforcing owner-only access (`request.auth.uid == uid`) across `/users/{uid}`, `/users/{uid}/meta/{docId}`, and all 15 synced financial subcollections, schema/length validation, a Base64 avatar size limit (`<= 800,000` chars), and protection against unauthenticated bulk enumeration or hijacking on `/usernames/{username}`.

### Fixed
- **App PIN Lock & Authentication Hardening:**
  - **Forgot PIN Reset Wipe & Deferred Cloud Reset (`LockScreen._forgot`, `AutoSyncService`):** Resetting a forgotten PIN while logged in now wipes all local SQLite data, local caches, and sync cursors before signing out (preventing access to the previous user's local data via Guest Mode), preserves the PIN in Cloud Firestore until the owner re-authenticates with their account password, and automatically syncs the active PIN across the user's devices.
  - **Hardware Keystore Lockout & Clock-Rollback Guard (`Lock`):** Migrated brute-force lockout counters (`fails`, `lockoutTier`, `lockoutUntil`) to `FlutterSecureStorage` (Android Keystore / iOS Keychain) with a backward clock-tampering guard and clamped remote `updatedAt` timestamps on PIN cloud sync.
  - **Sign-Up Guest Data Merge Prompt (`AuthPage`):** Prompted users with the "Keep Guest Data?" dialog during both account registration and login when local Guest Mode transactions exist, and ensured `AutoSyncService` clears `current_sync_user_id` only after `resetAllData()` completes.
- **Data Export, Sync, Share Intent, & Updater Hardening:**
  - **CSV Formula Injection Prevention (`ExportService`):** Sanitized exported CSV cells starting with formula triggers (`=`, `+`, `-`, `@`, `\t`, `\r`) with a leading single quote (`'`).
  - **Remote Sync & JSON Backup Validation (`AppDatabase`):** Clamped far-future `updatedAt` timestamps (`clampRemoteUpdatedAt`), validated non-negative bounded amounts, stripped unsafe `receiptPath` references, and restricted `_purgeLocalSensitiveFiles` to only delete files inside `shared_receipts/` or temporary cache directories (`isSafeReceiptDeletionPath`).
  - **Android Share Intent Stream Guard (`MainActivity.kt`):** Added a 10 MB stream copy cap and blocked `file://` URIs targeting the app's own internal sandbox directory.
  - **Lock-Screen Debt Notification Redaction (`NotificationService`):** Set `NotificationVisibility.private` and redacted counterparty names and Rupiah amounts from debt due notifications whenever `hideBalance`, App PIN Lock, or Privacy Shield is active.
  - **Updater URL Validation & CI Signing Guard (`UpdateCheckerService`, `release.yml`):** Restricted in-app update URLs to official HTTPS GitHub release domains (`isTrustedReleaseUrl`), enforced mandatory release keystore presence in GitHub Actions, and enabled Dart symbol obfuscation (`--obfuscate --split-debug-info`).

## [2.17.12] - 2026-11-21

### Changed
- **Landing Page Vice City Sunset Theme Alignment:**
  - Aligned `docs/style.css`, `docs/index.html`, and `docs/script.js` with the application's Vice City Sunset palette (`#0F172A`, `#1E293B`, `#243044`, `#FB7185`, `#38BDF8`, `#FBBF24`) and typography (`Space Grotesk`, `Inter`, `IBM Plex Mono`), preserving the existing layout structure.
  - Added the blurred coastal sunset hero background (`docs/images/hero-sunset.jpg`) and replaced remaining Enchanted Glasshouse / botanical references with Vice City Sunset copy and styling.

## [2.17.11] - 2026-11-21

### Fixed
- **Daily Financial Pulse Traffic-Light Color Hierarchy:**
  - Updated `DailyFinancialPulseCard` Safe tier and `_DailyPulseGuideSheet` Phase 1 ("Safe Financial Health") & Safe Daily Quota value from Rose (`colors.primary`) to Warm Emerald (`colors.income`), establishing clear traffic-light semantics: Green (Safe) → Orange (Caution) → Coral Rose (Limit).
  - Softened the card's top-left radial/linear tint opacity so Slate Navy card surfaces remain calm and readable.

## [2.17.10] - 2026-11-21

### Changed
- **Profile Avatar Frame Upgrade:**
  - Replaced `frame_vice_city.png` (and `frame_glasshouse.png`) with the new `1024x1024 RGBA` Vice City Sunset circular profile border featuring tropical palm silhouette, coastal skyline, and neon sunset rim lighting.

## [2.17.9] - 2026-11-21

### Fixed
- **Functional Empty State Illustration Mapping:**
  - Changed `EmptyStateCard` default icon from `Icons.eco_outlined` to `Icons.receipt_long_outlined` so empty transaction screens on Home and Transactions render the Wallet & Falling Coins illustration (`empty_transactions.png`) instead of the Savings Jar.
  - Added `Icons.search_off_rounded` to `resolveEmptyIllustration` so filtered/search empty states in Transactions render `empty_search.png`.
  - Added `Icons.repeat_rounded` / `Icons.event_repeat` to `resolveEmptyIllustration` so empty recurring schedule lists render `empty_notifications.png`.
  - Updated Insights empty states ("Record a few more transactions" and "No recap activity yet") to render `empty_analytics.png`.

## [2.17.8] - 2026-11-21

### Changed
- **Transparent App Launcher Icon & Brand Emblem:**
  - Replaced the square-backed launcher icon with the transparent-background Vice City Sunset "W" wallet & palm emblem (`1024x1024 RGBA`), matching the clean floating launcher style of the previous theme.
  - Regenerated all Android mipmaps, iOS AppIcons, Web icons, and Windows app icon via `flutter_launcher_icons`, and aligned native splash background color to Slate Navy (`#0F172A`).

## [2.17.7] - 2026-11-21

### Fixed
- **Eliminated Remaining Default Icon Leaks Across All Secondary & Core Views:**
  - **More Features (`MorePage`)**: Replaced all 9 default Material menu icons (Accounts, Transfer balance, Debts & splits, Budget, Goals, Recurring, Categories, PDF report, Settings) with custom neon 3D icons via `viceCityAssetForIcon`.
  - **Settings (`SettingsPage`)**: Replaced remaining default icons for Carry over unused budget, Daily reminder, Recap notifications, Guest Mode (Offline), Sign In / Create Account, and Cloud Sync/Upload/Download buttons.
  - **About Wall o' Pay (`AboutWallOPaySheet`)**: Replaced all 6 default Material icons across Brand Lore cards and Core Principles rows with custom assets (`security_shield`, `growth_plant`, `star`, `palm_tree`, `database`, `cloud_sync`).
  - **Insights (`InsightsPage`)**: Replaced default Material icons on Monthly Summary Income/Expense pills, Monthly Financial Review banner & modal, Trend comparison notice, Smart Insight cards, and empty-state prompt.
  - **Categories & Recurring**: Upgraded the category icon picker (`CategoriesPage`) and recurring schedule tiles (`RecurringPage`) to display custom 3D icons instead of Material defaults.

## [2.17.6] - 2026-11-21

### Added
- **Full 160-Icon Compressed Set Integration & Re-Audit:**
  - Mapped distinct, dedicated 3D icons from `assets/icon-compress/` to every transaction category (`food_basket`, `coffee_cup`, `bus`, `car`, `plane`, `wifi`, `smartphone`, `laptop`, `cart`, `gift_box`, `ticket`, `headphones`, `fitness_activity`, `medical_cross`, `users_group`, `wallet_cash`, `coin_stack`, `bank_building`, `mobile_banking`, `contactless_pay`, `cash`, `receipt`).
  - Replaced remaining default Material icons across Home (`visibility` eye/eye_off, pending recurring alarm clock, account quick-bar avatars), Transactions (PDF/CSV export icons, calendar range chip, net flow receipt, calendar header), Security (biometric fingerprint, change PIN password), Debts (split bill users group), Budget (`TotalBudgetDialog` calculator), and Goals (`savings_goal` replacing legacy `eco_outlined`).

## [2.17.5] - 2026-11-20

### Added
- **Deep Custom Icon Integration Across Settings, Home, & Transactions:**
  - Upgraded Settings menu tiles (Notifications, Security & PIN, Backup & Sync, Categories, Android Widgets, and About) and module switches (Goals, Debts, Recurring, Transfers, and Budgets) with custom Vice City 3D icons.
  - Upgraded Home `BalanceCard` income and expense flow badges with custom growth and minus assets.
  - Upgraded Daily Financial Pulse card tier badges and the comprehensive guide sheet with pulse gauge and health growth assets.
  - Upgraded Transactions page filter bar dropdowns (Accounts wallet, Categories diamond, and Need/Want budget pie chart) and Accounts page category headers.

## [2.17.4] - 2026-11-20

### Changed
- **Theme Refinement (Sunset Elegance — Arah A):**
  - Elevated app canvas from crushed dark navy (`#070D2B`) to refined modern Slate Navy (`#0F172A`), softened card surfaces to Slate 800 (`#1E293B`), and tuned borders and containers for high-contrast, eye-friendly readability.
  - Replaced harsh electric synthwave magenta with warm Sunset Rose / Coral (`#FB7185`) and Sunset Amber (`#FBBF24`), harmonizing directly with tropical sunset sky tones.
  - Shifted income indicators from cyan to warm emerald (`#10B981` / `#34D399`), restoring universal financial intuition (Income = Green, Expense = Coral Rose) on dark surfaces.
  - Modernized legacy branding strings in Insights and localization to "Financial Health Score" and "Financial Review / Recap".

## [2.17.3] - 2026-11-20

### Added
- **Comprehensive Custom Icon System Integration:**
  - Replaced standard Flutter Material icons across all primary views with custom transparent icons from `assets/icon-compress/` / `assets/icons/vice_city/`.
  - Upgraded Home header buttons (Settings gear and More Features diamond), Transactions header (Cashflow calendar, Date range, and Export card), Transactions search field, Transaction filter chips (All, Expense, Income, Transfer), and cashflow summary cards.
  - Upgraded Budget action buttons (Set budget gear, Add total budget, and Savings goals target), budget pillar category icons (Needs home, Wants gift, and Savings piggy bank), and Insights header/vitality badges.

## [2.17.2] - 2026-11-20

### Fixed
- **Residual Botanical Foliage & Ivy Removal:**
  - Fully eliminated legacy botanical fronds, hanging corner leaves, ivy vines, and greenhouse glass arches in `BotanicalCanopyPainter`, `BotanicalHeroCardPainter`, and `BotanicalBackgroundPainter`.
  - Replaced decorative vector drawings with sleek Vice City Sunset radial glows and subtle neon contour accents.

### Changed
- **Prominent 4-Page Vertical Sunset Background Integration:**
  - Activated the portrait Vice City coastal skyline sunset backdrop (`vice_city_vertical_bg.jpg`) across `_Sheet` in `HomePage` and `BotanicalBackgroundSheet` in `TransactionsPage`, `BudgetPage`, and `InsightsPage`.
  - Refined the header canopy gradient scrim from 65%-94% down to 15%-55% opacity, making the vibrant twilight sky and skyline prominent while keeping typography legible.

## [2.17.1] - 2026-11-20

### Fixed
- **Native & Flutter Splash Screen Palette Consistency:**
  - Replaced legacy botanical green (`#10251F`) with Midnight Navy (`#070D2B`) in Android native launch theme (`colors.xml`) and Flutter `SplashPage`, eliminating startup color flashes.
  - Removed botanical leaf silhouette custom paintings in favor of sleek neon arc waves and subtle starlight motes.

### Added
- **4 Main Pages Header Canopy (Concept A):**
  - Integrated portrait Vice City sunset backdrop (`vice_city_vertical_bg.jpg`) into the top header canopy of Home, Transactions, Budget, and Insights screens.
  - Maintained complete layout integrity with dark navy content sheets sliding smoothly over the canopy.
- **Settings Profile Card & Transparent Frame:**
  - Redesigned user profile card in `SettingsPage` with coastal sunset skyline landscape (`coastal_sunset_bg.jpg`) and Neon Edge Highlight border.
  - Integrated authentic circular Vice City profile frame (`frame_vice_city.png`) with alpha-transparency center.
- **Typography & Iconography Refinement:**
  - Upgraded font styling to Space Grotesk (headings and tabular financial figures), Inter (body readability), and IBM Plex Mono (metadata).
  - Integrated 25 compressed transparent 512x512 icons into internal icon assets.

## [2.17.0] - 2026-11-20

### Added
- **Vice City Sunset Visual Rebranding (Balanced Intensity):**
  - Implemented the complete Vice City Sunset design system centered on Midnight Navy (`#070D2B`), Deep Navy (`#101A3A`), Sunset Magenta (`#FF2E93`), Coral Pink (`#FF5B78`), Sunset Orange (`#FF8A36`), Golden Yellow (`#FFD166`), and Neon Cyan (`#20D9E8`).
  - Integrated the iconic `Neon Sunset Wallet W Emblem` as the primary brand logo, splash combination logo, and Android/iOS/Web app icons.
  - Sliced and mapped 30 individual icons from the `Miami Sunset Finance Icon Set` into `assets/icons/vice_city/` and integrated them across bottom navigation, category badges, transaction forms, date pickers, filters, and settings.
  - Sliced and integrated 6 contextual illustrations from `Tropical Neon Finance Empty States` into `assets/illustrations/` for empty transactions, empty budgets, empty savings/goals, empty analytics/insights, empty search, and empty notifications.
  - Integrated `Midnight Neon Arc Waves` and `Neon Sunset Over Coastal Skyline` background assets across splash, authentication, lock screen, and onboarding flows.

### Changed
- **Navigation & Components Overhaul:**
  - Modernized bottom navigation bar with active Golden Yellow & Neon Cyan indicators and floating action button with vibrant Sunset Magenta-to-Orange gradient and neon halo.
  - Refined `HeroCard`, `AppCard`, `CategoryBadge`, and `_HomeContentSheet` surfaces with deep navy backdrop, specular border outlines, and subtle glow shadows.
  - Upgraded custom painters (`BotanicalCanopyPainter`, `BotanicalHeroCardPainter`, `BotanicalBackgroundPainter`) to render coastal palms, sunset rays, and neon arc waves.

## [2.16.2] - 2026-11-15

### Fixed
- **Startup, Security Lock & Lifecycle Stability:**
  - Replaced overlay stacking in `LockGate` with exclusive lock gating so `HomeShell` and background side effects do not mount or run behind `LockScreen` before PIN/biometric verification.
  - Resolved race conditions across multi-account lock loading (`Lock.ensureLocalLoaded`, serialized `loadForUser`), coalesced cloud PIN syncs, awaited legacy lock migration before reading secrets, and removed Quick Action lock bypasses.
- **Recurring Transactions & Two-Way Cloud Synchronization:**
  - Added single-flight concurrency protection (`_inFlightChecks`) and intra-transaction pending-item idempotency in `RecurringService.checkAndGenerateDue` to prevent duplicate recurring entries, while pruning redundant callers in `OnboardingGate` and `_pushLocalOnly`.
  - Upgraded `AutoSyncService.startSync` to `Future<void>` with session epochs, account-switch guards, coalesced `triggerTwoWaySync`, reference-counted serialized remote writes, `Firebase.apps` safety checks, and complete `stopSync()` cleanup.
- **Profile, Initialization & App Shortcut Reliability:**
  - Added safe Base64 profile decoding and corrupt avatar fallback rendering in `ProfileController` and `UserAvatar` without deleting stored user data.
  - Eliminated double `SplashPage` rendering in `AuthGate`, resolved per-user startup locale formatting and normalized remote locale codes, prevented `UpdateCheckerService` lock listener leaks, and added bounded timeouts to `OnboardingGate`.
  - Hardened Android App Shortcuts (`SHORTCUT_EXPENSE`, `SHORTCUT_INCOME`, `SHORTCUT_TRANSFER`) and `ShareService` across cold and warm starts with atomic `consumeSharedData`, launcher/history intent filtering, early listener registration, sequential draining, and frame scheduling via `ensureVisualUpdate()`.

## [2.16.1] - 2026-11-14

### Removed
- **Android Home Screen Widgets Integration:**
  - Removed all 6 Android `AppWidgetProvider` implementations (`QuickFinanceWidgetProvider`, `DailyPulseWidgetProvider`, `QuickActionWidgetProvider`, `FavoriteTemplatesWidgetProvider`, `BudgetGuardrailWidgetProvider`, `GoalsAndBillsWidgetProvider`), `QuickTransactionActivity`, `WidgetDatabaseHelper`, `WidgetSnapshotStore`, `WidgetMidnightWorker`, and all widget XML/layout/drawable/string/color resources.
  - Removed `androidx.work:work-runtime-ktx` dependency from Android Gradle configuration and cleaned widget receivers and activities from `AndroidManifest.xml`.
  - Removed `com.example.wall_o_pay/widget` platform channel, `QuickWidgetService`, `WidgetHubSheet`, widget sync hooks across `HomeShell` and `TransactionForm`, and widget-exclusive localization keys while preserving app launcher shortcuts, Share Intent handling, and core financial features.

## [2.16.0] - 2026-11-12

### Added
- **Home Screen Widget Glass Style Presets (`Deep` / `Frosted` / `Clear`):**
  - Added selectable background translucency presets synced from **Settings -> Android Home Widgets** (`setWidgetGlassStyle`) across all 6 Enchanted Glasshouse Home Screen widgets (`WidgetSnapshotStore.resolveBackgroundRes`).
- **Live Mini-Previews & Module Guardrails in Widget Hub (`WidgetHubSheet`):**
  - Added real-time data-backed mini-previews inside each of the 6 widget cards reacting live to Glass Style presets and balance-privacy masking.
  - Added smart module-disabled warning banners with one-tap **Enable** shortcuts when required backing modules (`budget`, `goals`, `recurring`) are turned off.
- **Static Launcher Previews (`android:previewImage`):**
  - Added crisp static `preview_widget_*.png` assets across all 6 `*_widget_info.xml` manifests for Android 8–11 and third-party launchers alongside Android 12+ `previewLayout`.

### Changed
- **Widget Touch Feedback, Targets & Quick Privacy Toggle:**
  - Upgraded all Home Screen widget interactive buttons and template chips to native Material `<ripple>` feedback and enlarged `Goals & Bills` inline goal-switcher touch target to `28dp × 28dp`.
  - Enabled one-tap balance privacy masking toggle directly from the `Quick Action Bar` balance pill (`ACTION_BAR_TOGGLE_PRIVACY`).
  - Added an automatic 15-second alarm-based auto-dismiss (`ACTION_AUTO_DISMISS_FEEDBACK`) for the `One-Tap Favorites` Undo confirmation banner so it cleanly returns to template chips.

## [2.15.0] - 2026-11-12

### Added
- **Android Home Screen Widget Ecosystem — Phase 3 (`GoalsAndBillsWidgetProvider`, In-App Widget Hub):**
  - Added **Goals & Upcoming Bills** Home Screen widget (`2×2` & `4×2` responsive layouts) showing active `SavingsGoal` progress with an inline goal switcher (`↻`), upcoming/overdue expense `RecurringRule` & `PendingTransaction` bills with live midnight countdowns, privacy masking, and lock-aware deep links (`route_goals`, `route_recurring`).
  - Added **Android Home Widgets Hub** (`WidgetHubSheet`) inside **Settings -> Preferences**, listing all 6 Enchanted Glasshouse widgets with live active instance counts, one-tap Home Screen pinning (Android 8.0+ via `AppWidgetManager.requestPinAppWidget`), and instant snapshot sync.

## [2.14.0] - 2026-11-12

### Added
- **Android Home Screen Widget Ecosystem — Phase 2 (`FavoriteTemplatesWidgetProvider`, `BudgetGuardrailWidgetProvider`, `widget_route` Deep Linking):**
  - Added **One-Tap Favorites** Home Screen widget (`4×1` & `4×2` responsive layouts) backed by `tx_templates`, allowing one-tap instant transaction recording offline into SQLite (`need_want` preserved) with an immediate confirmation banner and one-tap **Undo** (`softDeleteTransaction`).
  - Added **Budget Guardrail** Home Screen widget (`2×2` & `4×2` responsive layouts) displaying active-period remaining budget, usage percentage with tier alerts (*Safe* / *Near 85%+* / *Over 100%*), top 3 critical expense categories with progress bars, rollover carryover support, and full balance-privacy masking.
  - Added secure `widget_route` deep-link routing (`tab_home`, `tab_transactions`, `tab_budget`, `tab_insight`, `new_transaction`) in `MainActivity.kt` and `quick_widget_service.dart`, queueing navigation until `LockGate` (PIN / biometrics) is unlocked.

## [2.13.0] - 2026-11-12

### Added
- **Android Home Screen Widget Ecosystem — Phase 1 (`DailyPulseWidgetProvider`, `QuickActionWidgetProvider`, `WidgetSnapshotStore`, `WidgetMidnightWorker`):**
  - Added **Daily Pulse & Balance** Home Screen widget (`2×2` & `4×2` responsive layouts) styled in Enchanted Glasshouse glassmorphism, displaying the safe daily spending quota, progress bar & today's expense, health tier badge (*Safe* / *Caution* / *Limit*), total balance, remaining period days, one-tap `+` quick entry, and a direct privacy eye toggle synced with the app.
  - Added **Quick Action Bar** Home Screen widget (`2×1` & `4×1` responsive layouts) with balance pill and one-tap **Income**, **Expense**, and **Transfer** triggers launching `QuickTransactionActivity`.
  - Added `WidgetSnapshotStore` shared snapshot bridge (`updateWidgetSnapshot`, `consumeNativeHideBalance` in `quick_widget_service.dart` & `MainActivity.kt`) and `WidgetMidnightWorker` (`WorkManager`) to automatically refresh daily quotas and spent totals at midnight when widgets are active.

## [2.12.0] - 2026-11-12

### Added
- **Wave 1 — Transaction Efficiency (`TransactionForm`, `TransactionParser`, `ShareService`, `TransactionTile`):**
  - Added compact wallet balance subtitles (`compactRupiah`, respecting balance privacy mode) directly inside `AppChip` wallet selectors in `TransactionForm`.
  - Enabled full shared-text prefill (`parseSharedText` extracting type, category ID, amount, and cleaned merchant note) for incoming Android shares via `ShareService`.
  - Added one-tap `"Record again"` duplication (`showDuplicateTransactionForm`) from transaction long-press on Home/Transactions tiles and the Edit transaction header, while surfacing `"Save as template"` outside expandable details.
- **Wave 2 — Budget Continuity & Clarity (`BudgetPage`, `BudgetRule`, `NotificationService`):**
  - Added a one-tap `"Copy from {period}"` banner inside `BudgetPage` (`copyFromPeriod` in `BudgetRuleNotifier`) whenever the active period has no budget configured and the previous period does, copying both the 50/30/20/custom pool and category limits.
  - Updated `checkBudgetAfterExpense` to account for active category rollover carryover (`rolloverEnabled`) and emit 80%/100% threshold alerts for configured total budget pools (`totalBudgetPool`).
- **Wave 3 — Insights Drill-Down, Pulse Shortcuts & Export Polish (`InsightsPage`, `DailyFinancialPulseCard`, `TransactionsPage`, `HomePage`):**
  - Made `SmartInsightItem` cards interactive in `InsightsPage`, tapping opens a transaction drill-down modal filtered by category, need/want tag, peak spending day, micro purchases, or largest transaction.
  - Made the scheduled upcoming bills reserve row in `DailyFinancialPulseCard` tappable to jump directly to `RecurringPage`.
  - Added an **Export** (`PDF report` / `CSV`) menu inside the `TransactionsPage` AppBar and surfaced the reusable `GuestBackupNudgeBanner` on `HomePage` for guest accounts meeting the local backup threshold.

### Changed
- **Consistent Thousands Input Formatting (`TotalBudgetDialog`, `CategoryBudgetSheet`):**
  - Applied `amountFormatters()` (`ThousandsInputFormatter`) and `formatThousands` initial formatting across all total budget and category limit inputs.

### Fixed
- **Default Transfer Wallets Pre-Selection (`TransactionForm`):**
  - Fixed `resolveTransferWallets` validation in `_save()` so default displayed source and destination transfer wallets save directly without re-tapping wallet chips.
- **PDF Transfer Formatting (`ReportService`):**
  - Fixed `TxType.transfer` rows in generated PDF tables to format with `<-> ` instead of `-`.

## [2.11.1] - 2026-11-12

### Added
- **Final Release Hardening & UI Verification (`test/phase5_final_polish_test.dart`):**
  - Added widget smoke tests covering `InsightsPage` (*Net Worth & Vitality Score* card + breakdown sheet), `GoalsPage` (goal savings pace chips & *Use pace* quick-fill), `SettingsPage` (`Harvest recap notifications` toggle in Indonesian locale), and EN/ID localization key verification.

### Changed
- **Documentation & Landing Page Synchronization (`docs/index.html`, `README.md`, `ARCHITECTURE.md`):**
  - Aligned security references with `2,048-iteration salted HMAC-SHA256 (v2)`, typography with `Outfit & DM Sans`, and feature highlights covering Net Worth & Vitality Score, Weekly/Monthly Harvest Recaps, Goal Savings Pace, Custom Split Bills, and Active Modules.
- **Repository Hygiene (`.gitignore`):**
  - Ignored `/android/build/` local Gradle build output directory.

## [2.11.0] - 2026-11-12

### Added
- **Net Worth & Glasshouse Vitality Score (`InsightsPage`, `InsightEngine`):**
  - Added unified `NetWorthSummary` (`Liquid Assets + Receivables - Liabilities`, tracking `allocatedGoalReserve` separately to avoid double-counting) and deterministic 0–100 `VitalityScoreSummary` across 4 normalized pillars (*Savings Rate*, *Budget Discipline*, *Needs vs Wants Balance*, and *Debt Cushion*) inside `InsightsPage` Overview and its breakdown sheet.
- **Goal Savings Pace & Projection (`GoalsPage`):**
  - Added `computeGoalPace` for active goals with target dates, showing status pills (*On Track*, *Behind Schedule*, *Due Today*, *Overdue*), recommended weekly/monthly contribution pace, and a one-tap *"Use pace"* fill chip inside the *Add funds* dialog.
- **Contextual Harvest Recap Notifications (`SettingsPage`, `NotificationService`):**
  - Added the `Harvest recap notifications` toggle in **Budget & reminders** (synced via `FeaturePrefs` and `AppPrefs`) that alerts once per newly completed period when an unseen recap with recorded activity is ready to review.
- **Automated CI Quality Gate (`.github/workflows/release.yml`):**
  - Enforced `flutter analyze --no-pub` and `flutter test --no-pub` in the GitHub Actions release pipeline prior to APK compilation.

## [2.10.0] - 2026-11-12

### Added
- **Weekly & Monthly Financial Recap (`InsightsPage`):**
  - Added `InsightEngine.computeRecap` and the **Glasshouse Harvest Review** modal bottom sheet accessible from the `InsightsPage` header and Overview banner, allowing instant switching between completed Weekly and Monthly recaps (income, expenses, net savings rate, Needs vs Wants split, top 3 categories, biggest saving & surge highlights, and Savings Goals progress).
- **Interactive Category & Chart Drill-Down (`InsightsPage`):**
  - Made top category rows and `ExpensePieChart` sections/legend pills tappable to inspect the underlying period transactions directly via `TransactionTile` drill-down sheets.
- **Flexible PDF/CSV Exports & Guest Backup Nudge (`SettingsPage`, `ReportService`, `ExportService`):**
  - Added account (`walletId`) filtering to PDF reports and both date-range + account filtering with enriched 8-column export (`Date,Type,Category,Wallet,ToWallet,NeedWant,Amount,Note`) to CSV export.
  - Added an unobtrusive Guest Mode JSON backup reminder inside `SettingsPage` when local transactions reach 10+ without a recent backup (>14 days).
- **Custom (Non-Equal) Split Bill (`DebtsPage`):**
  - Added **Equal Split** / **Custom Split** mode toggle on `_SplitSheet` with pre-filled per-friend amount fields, live user-share calculation, and validation (`computeCustomSplit`).
- **Modular Features & Active Modules Manager (`ModulePrefs`):**
  - Activated `modulePrefsProvider` inside `SettingsPage` (**Active Modules & Features** with **All Features** / **Minimalist** presets and 5 toggles), wiring visibility cleanly into `MorePage`, `HomeShell` navigation bar, `TransactionForm` transfer type, and `HomePage`.
- **Incremental Cloud Sync Pull Cursor (`AutoSyncService`):**
  - Persisted per-user `sync_pull_cursor_<uid>` with a 30s clock-skew overlap buffer for incremental Firestore queries (`where('updatedAt', isGreaterThan: ...)`) while keeping full sync escapes (*Fetch from Cloud* / initial sync) and automatic cursor cleanup on logout, account deletion, or account switch.

## [2.9.1] - 2026-11-12

### Removed
- **Simplified Home Screen Layout (`HomePage`):**
  - Removed the 4-button Home Quick Actions row (`Transfer`, `Recurring`, `Debts`, `Goals`) to keep the Home dashboard clean, focused, and efficient, as these destinations remain directly accessible from the transaction action bar and dedicated navigation hubs.

## [2.9.0] - 2026-11-12

### Added
- **SQL Multi-Filter Transaction Search & Net Summary (`TransactionsPage`):**
  - Extended `AppDatabase.watchSearchTransactions` with SQL-level `walletId` (including incoming `toWalletId` transfers), `categoryId`, `needWant`, localized `matchedCategoryIds`, and expanded result window (`limit = 250`).
  - Added Needs/Wants filter dropdown chip, one-tap search clear (`x`), clear *"Searching across all dates"* header badge, result count + **Net flow** summary strip, and actionable *"Clear filters"* empty state CTA.
- **Pending Recurring Confirmation Queue & Full Lifecycle Control (`RecurringPage` & `HomePage`):**
  - Added Drift schema v9 (`PendingTransactions`) so due recurring schedules queue for user review with **Confirm**, **Edit & Confirm** (override amount/wallets/note), and **Skip** (with Undo) both on the Home banner and top of `RecurringPage`.
  - Added editing (`updateRecurringRule`), `TxType.transfer` recurring schedules (`toWalletId`), **Record now**, **Skip next due**, and soft-delete with **Undo** (`restoreRecurringRule`).
  - Included unconfirmed pending expense items in `upcomingRecurringExpenseProvider` so Daily Financial Pulse stays accurate until confirmed or skipped.
- **Itemized Debt Payment History (`DebtsPage`):**
  - Added Drift schema v9 (`DebtPayments`) recording every installment with optional linked wallet transaction, live **Payment History** section on `_DebtDetail`, and safe delete + **Undo** (`deleteDebtPayment` / `restoreDebtPayment`) keeping paid totals and wallet balances synchronized.
- **Home Quick Actions & Actionable Empty States:**
  - Added compact Home Quick Actions strip (**Transfer**, **Recurring** with live pending badge, **Debts**, **Goals**) plus unified `EmptyStateCard` CTAs on `DebtsPage` and `GoalsPage`.
- **Backup, Cloud Sync & Strict Firestore Validation (`schemaVersion => 9`):**
  - Added `debtPayments` and `pendingTransactions` to JSON backup export/import, real-time `CloudSync`, legacy pre-v1.11.15 `pending_transactions` upgrade guard, and strict exact-field `firestore.rules` validators.

## [2.8.0] - 2026-11-12

### Added
- **Daily Financial Pulse Breakdown & Scheduled Bill Awareness:**
  - Added a pure `calculateDailyPulse` engine incorporating active upcoming recurring expenses (`upcomingRecurringExpenseProvider`) and total account balance fallback when period income and budgets are not yet set.
  - Added an interactive *"How your quota is calculated"* breakdown card inside the Daily Financial Pulse guide bottom sheet showing funding basis, upcoming scheduled bills deducted, remaining days, and safe daily quota.
- **Debt Record Editing & Dedicated Full-Settlement Flow:**
  - Added `AppDatabase.updateDebt` and an inline edit button on debt detail sheets so amount, direction, counterparty, due date, and notes can be modified anytime.
  - Replaced the ambiguous *"Mark as fully paid"* dialog with a dedicated full-settlement confirmation prompt that settles the exact remaining balance cleanly.
- **System Categories for Admin Fees & Savings Flows:**
  - Seeded fixed-ID system categories (`cat-exp-admin` *Admin Fee*, `cat-exp-savings` *Savings Deposit*, and `cat-inc-savings` *Savings Withdrawal*) automatically in `beforeOpen` without altering database schema version, mapping savings deposits directly to the 50/30/20 Savings pillar.
- **Template Management & Phase 1 Regression Tests:**
  - Added discoverable one-tap delete icons (`onDeleted`) and long-press delete confirmation on quick transaction templates in `TransactionForm`.
  - Added comprehensive unit and integration tests for `needWant` persistence, custom payday monthly chart bucketing, `DailyFinancialPulse` edge cases, recurring upcoming deductions, `updateDebt`, and `deleteTemplate`.

### Changed
- **Unified Account Transfer Flow:**
  - Consolidated `AccountsPage` transfers onto `showTransactionForm(context, initialType: TxType.transfer)` (matching `MorePage`) and removed the redundant `TransferSheet` modal, bringing admin fees, receipts, and wallet selection cleanly into one flow.
- **Enchanted Glasshouse Color Token Cleanup:**
  - Replaced remaining hardcoded Material colors (`Colors.green`, `Colors.red.shade800`, `0xFF1E4238`, `0xFFE65100`, `0xFFD65D5D`) across Settings and Pulse UI with canonical `AppColors` tokens.

### Fixed
- **Need/Want Persistence on Transaction Save & Edit:**
  - Fixed `AppDatabase.addTransaction` and `AppDatabase.updateTransaction` silently dropping `_needWant` selected in `TransactionForm`, restoring accurate Needs vs. Wants 50/30/20 analysis.
- **Custom Payday (`firstDayOfMonth`) Consistency:**
  - Passed `firstDayOfMonth` into `SelectedAnchor.step()`, `OnboardingPage` initial budgets, and `checkBudgetAfterExpense()` budget threshold notifications.
  - Fixed `InsightEngine.computeChartPoints` monthly bucketing so custom payday periods spanning across two calendar months slice expenses accurately into 7-day intervals starting from `period.start`.
- **Accidental Duplicate Admin Fee Prevention:**
  - Disabled re-creating secondary admin fee transactions when editing existing transactions or transfers in `TransactionForm`.
- **False `Limit` Pulse State:**
  - Prevented `DailyFinancialPulseCard` from falsely showing *"Limit"* on initial purchases made before salary/income arrives when users have positive account balances or active period budgets.

## [2.7.3] - 2026-11-12

### Fixed
- **Android Gradle Plugin (AGP) Compatibility for Latest Flutter Stable:**
  - Upgraded `com.android.application` plugin in `android/settings.gradle.kts` from `9.1.0` to `9.1.1` to meet the latest Flutter `stable` SDK minimum AGP requirement and fix GitHub Actions release APK builds.

## [2.7.2] - 2026-11-12

### Changed
- **Quick Finance Widget Enchanted Glasshouse Redesign:**
  - Redesigned the Android Home Screen Widget (`widget_quick_finance.xml`) and matching floating `QuickTransactionActivity` dialog (`dialog_quick_transaction.xml`) to fully match the main application's **Enchanted Glasshouse** design system.
  - Applied layered Deep Forest Botanical glassmorphism surfaces (`HeroCard` `#26503E` -> `#132B21` diagonal emerald-to-moss backdrop, emerald aurora glow top-right, specular glass sheen, `24dp` Dew Mint refraction rim, and translucent `18dp` inner `AppCard` surface) plus subtle vaulted conservatory arch and botanical leaf accents (`widget_botanical_canopy`, `widget_botanical_corner`).
  - Unified the Income, Expense, and Transfer type selector into an authentic `SegmentedButton`-style pill track (`#8010251F`, `16dp` radius) featuring **Emerald Leaf** (`#39745A`) active fills with `Dew Mint` (`#D5E8DC`) specular borders and crisp vector flow/swap icons instead of plain ASCII characters.
  - Styled header controls with a frosted circular `Open App` glass button (`_HomeHeader` parity), frosted glass balance pill, tabular figures (`tnum`) across monetary values and `+10k`/`+20k`/`+50k`/`+100k` `AppChip`/`_QuickAmountChip` pills, `AppCard`-style category and wallet selector pills with vector icons, and dynamic **TransactionForm** semantic Save CTA gradients (Expense rose-crimson, Income emerald, Transfer ocean teal) framed by `1.2dp` Dew Mint glass rims.

## [2.7.1] - 2026-11-12

### Fixed
- **Quick Finance Widget Direct Launch & MIUI / Android BAL Compatibility:**
  - Replaced `PendingIntent.getBroadcast` trampoline dispatches (`WIDGET_OPEN_DETAIL`, `WIDGET_OPEN_APP`) with direct `PendingIntent.getActivity` bindings to `QuickTransactionActivity` and `MainActivity`, resolving background activity launch blocks (`Abort background activity starts` / MIUI `MIUIOP`) when opening the floating dialog or app from the Home Screen widget.
  - Bound the entire nominal row (`widget_nominal_row`), nominal display (`widget_queued_amount`), and `Detail` button directly to `QuickTransactionActivity` while keeping preset chips, category/account cyclers, clear button, and `Save Transaction` in-widget.
  - Added `MY_PACKAGE_REPLACED`, `BOOT_COMPLETED`, and `LOCALE_CHANGED` broadcast handling plus `onEnabled`/`onRestored` hooks so active widget instances rebind automatically after app updates, device restarts, or launcher restoration without getting stuck on the static placeholder view.
  - Consolidated `updateWidget()` queries into a single read-only SQLite snapshot (`WidgetDatabaseHelper.loadWidgetSnapshot`) and synchronous `.commit()` persistence, and synced `QuickTransactionActivity` directly with live `SharedPreferences` state and proper `adjustResize` keyboard handling.

## [2.7.0] - 2026-11-12

### Added
- **Direct Home Screen Recording for Quick Finance Widget (Option C):**
  - Added full 100% in-widget transaction entry (`QuickFinanceWidgetProvider` + `WidgetDatabaseHelper`) directly to the local Drift SQLite database (`wall_o_pay.sqlite`) without opening the main Wall o' Pay application.
  - Added quick nominal preset chips (`+10k`, `+20k`, `+50k`, `+100k`) with clear (`✕`) button, live queued nominal counter, and one-tap interactive cyclers for Income/Expense categories and Source/Destination wallets fetched dynamically from SQLite.
  - Added a translucent floating Quick Transaction dialog (`QuickTransactionActivity`) launched over the home screen wallpaper via the `Detail` button or by tapping the nominal area, providing numeric Rupiah-formatted keyboard input, full Category and Wallet spinners, and optional transaction description.
  - Implemented strict transaction validation (`amount > 0`, active account/category existence checks, source != destination wallet validation on Transfer), duplicate-tap save protection, instant recalculated balance header update, and inline success/error banner feedback.
  - Implemented seamless two-way synchronization (`checkNativeWidgetDbDirty` & `consumeNativeDbDirty` via `com.example.wall_o_pay/widget`), automatically triggering Drift table stream updates (`db.markTablesUpdated`) and Cloud Sync when the main app resumes or starts.
  - Enhanced adaptive layout responsiveness across compact, medium, and expanded home screen launcher grid sizes without text truncation or clipping.

## [2.6.0] - 2026-11-12

### Added
- **Quick Finance Android Home Screen Widget (Enchanted Glasshouse):**
  - Integrated a dedicated Android Home Screen App Widget (`QuickFinanceWidgetProvider`) allowing users to record Income, Expense, or Transfer transactions instantly from their home screen.
  - Implemented authentic Enchanted Glasshouse visual design identity: Deep Moss Shadow canvas (`#10251F`), glass refraction border (`#2A4D3E`), transparent card surfaces, Soft Ivory (`#F7F8F4`) typography, and tailored botanical highlights (`#38B271` for Income, `#D64545` for Expense, `#00897B` for Transfer).
  - Responsive layout supporting compact (2x2), medium (4x2), and expanded launcher dimensions with dynamic header, real-time balance display, interactive category segmented selector, and quick record button.
  - Full privacy mode integration (`hideBalance`) dynamically masking sensitive account totals with `Rp ••••••••` on the widget surface when privacy sensor is enabled.
  - Seamless two-way data synchronization via `QuickWidgetService` and MethodChannel (`com.example.wall_o_pay/widget`), updating home screen widget balance and state on any transaction mutation, balance recalculation, or app lifecycle resume.
  - Interactive hybrid flow: in-widget category switcher coupled with direct intent dispatching (`QUICK_WIDGET_INCOME`, `QUICK_WIDGET_EXPENSE`, `QUICK_WIDGET_TRANSFER`) straight to `TransactionForm`, bypassing PIN lock delay and splash delay for immediate transaction entry.

## [2.5.6] - 2026-11-11

### Changed
- **Freeform Transparent Android Home Screen Launcher Icon (Nesty Style):**
  - Removed `mipmap-anydpi-v26/ic_launcher.xml` and omitted adaptive background/foreground configuration, mirroring the exact architecture from the **Nesty** project.
  - Generates standalone transparent `mipmap-*/ic_launcher.png` icons directly from `assets/images/logo.png`, allowing Android and OEM launchers (such as Xiaomi/POCO Launcher) to render the authentic Enchanted Glasshouse logo directly on the wallpaper with zero background plates, masks, or container boxes.
- **Enchanted Glasshouse Typography & Asset Hygiene:**
  - Standardized `FilledButton` theme in `theme.dart` to strictly use `DM Sans` (`GoogleFonts.dmSans`), eliminating residual `PlusJakartaSans` font warnings.
  - Removed unneeded `Plus Jakarta Sans` font import from `docs/index.html` to reduce web font payload.
  - Purged obsolete legacy hybrid logo assets (`logo_hybrid.png` and `logo_hybrid_foreground.png`) from the repository, saving ~1.28 MB.
  - Hardened `.gitignore` to explicitly prevent unintended commit of `.env` configuration files.

## [2.5.5] - 2026-11-11

### Changed
- **Transparent Android Launcher Icons & Adaptive Layer Optimization:**
  - Replaced the dark green background container box with transparent background configuration (`#00000000`) for Android adaptive icons in `pubspec.yaml` and `res/values/colors.xml`.
  - Utilized authentic transparent PNG assets (`assets/images/logo_foreground.png` for adaptive foreground and `assets/images/logo.png` for legacy mipmaps) preserving full alpha channels and original Enchanted Glasshouse brand identity.
  - Added calibrated `adaptive_icon_foreground_inset: 10` to guarantee 0.0% icon clipping across all Android OEM mask profiles (circular, squircle, and rounded rectangular shapes) while maintaining maximum symbol scale.
  - Regenerated all Android launcher icon mipmap drawables across all standard density buckets (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Preserved solid opaque background for iOS launcher icons (`remove_alpha_ios: true`) in strict compliance with Apple App Store submission standards.

## [2.5.4] - 2026-11-11

### Added
- **Enchanted Glasshouse Profile Card for Settings Page:**
  - Designed and implemented a bespoke botanical glassmorphism profile card (`_GlasshouseProfileCard` in `SettingsPage`) featuring a horizontal layout with rounded corners (22px).
  - Integrated circular user avatar with botanical glass frame, clean **Outfit SemiBold** user name typography, **DM Sans** email/handle, a frosted emerald glass "Personal Account" badge, and an edit profile action button in the top right.
  - Crafted `_ProfileCardGlassPainter` featuring specular diagonal glass sheen, subtle greenhouse architectural mullion lines, and subtle botanical corner accents.
  - Generated high-resolution frontal UI concept render artifact with neutral dark background.

## [2.5.3] - 2026-11-11

### Changed
- **Enchanted Glasshouse App Launcher Icons & Web Favicons:**
  - Regenerated all multi-platform launcher icons across Android (`mipmap` and adaptive icons with `#10251F` background), iOS (`AppIcon.appiconset`), Windows, and Web.
  - Generated crisp multi-resolution favicons (`favicon.ico` 16/32/48/64px, `favicon.png` 32x32px), `apple-touch-icon.png` (180x180px), and `images/icon.png` (192x192px) for the documentation and landing page (`docs/`).

## [2.5.2] - 2026-11-11

### Changed
- **Minimalist Clean 3D Botanical Navigation Bar:**
  - Removed the rectangular glass pill container border around active tabs in `HomeShell` (`lib/app.dart`), giving the 3D icons breathing room and creating a cleaner, more spacious layout.
  - Active tabs smoothly illuminate to full brilliance (`opacity: 1.0`) with `AnimatedOpacity` and bold `dewMint` labels, while passive tabs rest gently at `opacity: 0.38` with muted `freshSage` labels.

## [2.5.1] - 2026-11-11

### Changed
- **Unified 100% 3D Botanical Glasshouse Navigation Bar:**
  - Modernized the bottom navigation bar (`HomeShell` in `lib/app.dart`) to feature consistent bespoke 3D botanical glass icons across all states (Home, Transactions, Budget, and Insights), eliminating the mix between flat Material line icons and 3D icons.
  - Added translucent, glowing `dewMint` active pill indicators (`AppColors.dewMint.withValues(alpha: 0.14)` background and `0.32` specular border) with smooth curves and animations when switching tabs.
  - Set passive tabs to softly muted `opacity: 0.38` with `freshSage` labels, highlighting the active tab with full `opacity: 1.0` and vivid `dewMint` typography.

## [2.5.0] - 2026-11-11

### Added
- **Enchanted Glasshouse Visual Identity Splash Screen:**
  - Introduced new dedicated Splash Screen module (`SplashPage` & `GlasshouseCombinationLogo` in `lib/features/splash/splash_page.dart`) capturing the modern minimalist, botanical glassmorphism design ethos.
  - Implemented vector **Combination Logo** featuring a modern lancet greenhouse architectural arch, frosted emerald glass facets with specular glare, mullion iron framing, and a thriving botanical sprout with radiant dew droplet at its core.
  - Integrated high-contrast typography hierarchy with **Outfit SemiBold** for the "Wall o' Pay" title and **DM Sans Regular** for the signature tagline "Grow Your Financial Habits." (with bilingual translation in Indonesian: "Tumbuhkan Kebiasaan Finansialmu.").
  - Added minimalist glowing `dewMint` loading indicator capsule providing smooth feedback during cold-start initialization.
  - Designed `EnchantedGlasshouseBackgroundPainter` with deep `mossShadow` / `glasshouseGreen` radial canvas, subtle conservatory ceiling trusses, animated natural sunbeam light rays, edge-framed emerald & sage foliage silhouettes, and floating ethereal dew motes.
  - Added native dark launch background configuration for Android (`launch_background.xml` & `colors.xml` with `#10251F`) and iOS (`LaunchScreen.storyboard` with `#10251F`) to eliminate blank/white screen flicker during Flutter engine cold boot.
  - Built comprehensive widget test suite in `test/splash_screen_test.dart` verifying combination logo rendering, typography, multilingual translation, and seamless completion lifecycle.

### Changed
- Refactored `_Root` in `lib/app.dart` to use silky smooth fade transitions (`AnimatedSwitcher` with `Curves.easeOutCubic`) upon splash sequence completion, while preserving zero-wait bypass for pending share shortcuts.

## [2.4.13] - 2026-11-11

### Changed
- **Phase 7 UI Redesign: Profile, Settings, Security, & Onboarding:**
  - Modernized **Profile Screen** (`ProfilePage`) with dark moss card surfaces, specular `dewMint` highlights, glowing camera action badge with `AppColors.glasshouseGreen`, and polished WhatsApp-style photo bottom sheet with circular `dewMint` action containers.
  - Refined **About Wall o' Pay Modal** (`AboutWallOPaySheet`) with botanical glasshouse identity, dark moss background (`AppColors.mossShadow`), specular `dewMint` top border, glowing botanical logo container, high-contrast typography, and redesigned principle and metadata cards.
  - Upgraded **Settings Screen** (`SettingsPage`) and **More Hub** (`MorePage`) with high-contrast `UserAvatar` glass frame, specular border icon badges, high-contrast text hierarchies (`AppColors.softIvory` / `AppColors.freshSage`), and glowing `dewMint` forward chevrons.
  - Enhanced **Security Screen** (`SecurityPage`) and **Lock Screen** (`LockScreen`) with specular bordered biometric containers, high-contrast PIN keypad with translucent circular borders (`Colors.white.withValues(alpha: 0.22)`), and elevated "Change PIN" outline action buttons.
  - Polished **Auth Screen** (`AuthPage`) and **Onboarding Flow** (`OnboardingPage`) with botanical green CTA buttons (`AppColors.glasshouseGreen`), `dewMint` accent outlines, high-contrast step indicators, and guest mode actions.

## [2.4.12] - 2026-11-11

### Fixed
- **Consistent Account & Wallet Glasshouse 3D Icons:**
  - Resolved icon discrepancy in "Accounts & Wallets" (`AccountsPage`) where Digital Bank was showing default Material outline icons while other account kinds displayed bespoke 3D botanical glass icons.
  - Registered `digital`, `bank`, `ewallet`, `cash`, `smartphone`, `devices`, and `wallet` keys in `glasshouseCategoryAssets` and `categoryIcons`.
  - Expanded `glasshouseAssetForIcon` to map `Icons.smartphone_outlined`, `Icons.devices`, `Icons.devices_other`, and `Icons.devices_other_outlined` to `bills.png`, and `Icons.wallet` / `Icons.wallet_outlined` to `wallet.png`.
  - Updated `AccountForm` so that Digital Bank sets `smartphone` icon key, and modernized `Recent transfers` list tile leading icon with a 3D glass `CategoryBadge`.

## [2.4.11] - 2026-11-11

### Changed
- **Phase 6 UI Redesign: Financial Utilities & Supporting Modules:**
  - Modernized **Accounts Page** (`AccountsPage`) with `_AccountCategoryHeader` glowing mint icons and distinct category count pills, tabular subtotal and balance figures, and transfer cards with teal styling (`#5EEAD4`).
  - Refined **Categories Page** (`CategoriesPage`) with delicate `borderOutline` dividers, high-contrast category titles, and rounded bottom sheet with specular borders and elevated `dewMint` buttons.
  - Upgraded **Debts & Splits Page** (`DebtsPage`) with SegmentedButton specular toggles, high-contrast settled and left badges (`incomeOnDark` / `softIvory`), and overdue alerts.
  - Polished **Savings Goals Page** (`GoalsPage`) with tabular progress typography, `dewMint` deposit buttons, and completed goal badges.
  - Enhanced **Recurring & Subscriptions Page** (`RecurringPage`) with glowing schedule icons, tabular income/expense figures, and tactile switch toggles.

## [2.4.10] - 2026-11-11

### Changed
- **Phase 5 UI Redesign: Insights Page & Custom Chart Styling:**
  - Upgraded Net Balance Hero Card with glowing surplus/deficit pill badges, tabular currency typography (`context.moneyStyle(fontSize: 30)`), and elevated translucent emerald `_SummarySubBox` metric containers.
  - Modernized `_PeriodComparisonCard` with high-contrast `AppColors.cardSurface` glass background, dynamic reduction savings badges, and glowing trend icons.
  - Enhanced SegmentedButton tab switcher (Overview, Categories, Trend) with `dewMint` specular highlights and high-contrast labels.
  - Transformed `PeriodExpenseBarChart` with dark glass tooltips, tabular currency formatting, glowing mint touch selection states, and delicate refractions.
  - Refined `TrendBarChart` with high-contrast `incomeOnDark` and `expenseOnDark` color styling and glowing dot legends.
  - Polished `_NeedsWantsCard` with dual rounded progress segments, vibrant emerald and warm amber jewel tones, and tabular figures.
  - Redesigned `_TopCategoryRow` with distinct rank pill containers, tabular percentages, and high-contrast category spending metrics.
  - Upgraded `_SmartInsightCard` and `_TrendTable` with rounded glass surfaces and specular dividers.

## [2.4.9] - 2026-11-10

### Changed
- **Phase 4 UI Redesign: Budget Page & 50/30/20 Pillars:**
  - Upgraded Total Budget Hero Card with tabular currency typography (`context.moneyStyle(fontSize: 26)`), `dewMint` specular edit action, and dual-state `AppProgressBar`.
  - Added elevated 50/30/20 preview container with jeweled 3-color ratio bar (`#38B271` Needs, `#E8A33D` Wants, `#5EEAD4` Savings) and glowing dot legends with tabular numbers.
  - Refined Rollover Banner with `mossShadow` frosted container, `dewMint` circular icon, and tabular currency carryover badge.
  - Transformed `BudgetPillarCard` with glowing circular bucket icons, `AppColors.softIvory` headings, `expenseOnDark` over-budget alerts, `dewMint` carryover badges, and delicate specular borders.
  - Redesigned `CategoryBudgetSheet` with `mossShadow` glass background, top specular border, glowing drag handle, and elevated `dewMint` save button.
  - Polished `TotalBudgetDialog` with glass container styling, modernized 50/30/20 vs custom nominal segmented toggle, tabular numeric inputs, and clear allocation status pill.

## [2.4.8] - 2026-11-10

### Changed
- **Phase 3 UI Redesign: Transactions Page & Interactive Cashflow Telemetry:**
  - Redesigned search bar with frosted glass surface, `freshSage` search icon, and high-contrast hint text.
  - Upgraded transaction type filter chips (**All**, **Expense**, **Income**, **Transfer**) with tactile contextual icons and glowing emerald selection states.
  - Enhanced Account and Category filter dropdown buttons with rounded translucent glass containers, `dewMint` specular borders, and active status indicators.
  - Added a dedicated "Clear filters" action pill with soft berry/ruby border when filters are active.
  - Transformed date grouping headers with dynamic daily net cashflow badges (`+Rp ...` in `incomeOnDark` or `-Rp ...` in `expenseOnDark`) for effortless scanning.
  - Upgraded `_SummaryTile` metrics cards with circular glowing containers and tabular figures.
  - Polished interactive `_CashflowCalendarCard` with highlighted current day border, emerald selected day pill, and glowing dual-color cashflow indicator dots.
  - Refined `TransactionTile` and `TransactionGroupCard` with high-contrast text, `dewMint` receipt indicators, and delicate pine dividers.

## [2.4.7] - 2026-11-10

### Changed
- **Scoped Atmospheric Canopy & Botanical Background Exclusively to Primary Navigation Tabs:**
  - Reserved the atmospheric canopy header (`glasshouse_bg.jpg`, `#0D1D17` to `#142B22` gradient, `BotanicalCanopyPainter`) and rich `BotanicalBackgroundSheet` exclusively for the 4 core primary tabs (**Home**, **Transactions**, **Budget**, and **Insights**).
  - Introduced `secondaryAppBar` for secondary and nested detail screens (`AccountsPage`, `CategoriesPage`, `DebtsPage`, `GoalsPage`, `MorePage`, `ProfilePage`, `RecurringPage`, `SecurityPage`, `SettingsPage`), featuring clean and minimalist flat styling on `mossShadow` canvas without decorative photo overlays or leaf clutter.
  - Removed `BotanicalBackgroundSheet` from secondary sub-pages and auth/onboarding screens, ensuring peaceful, clutter-free focus on utilities, settings, and form controls.

## [2.4.6] - 2026-11-10

### Changed
- **Atmospheric Header Canopy Depth & Content Boundary Separation:**
  - Darkened the header backdrop gradient across `HomePage` and `pageAppBar` (`AppColors.headerCanopyTop = #0D1D17` to `AppColors.headerCanopyBottom = #142B22`) to provide distinct atmospheric depth and visual separation between the header area and the main content sheet.
  - Enhanced title, profile avatar, and action button readability against the nocturnal conservatory canopy.
  - Accentuated the specular curved `dewMint` boundary line on the sheet top.

## [2.4.5] - 2026-11-10

### Changed
- **Harmonized Enchanted Glasshouse Header & Atmospheric Background Across All Pages:**
  - Upgraded `pageAppBar` with sunlit conservatory backdrop (`glasshouse_bg.jpg`), subtle dual gradient overlay (`#23483B`), and delicate `BotanicalCanopyPainter` overlay identical to `HomePage`.
  - Upgraded `BotanicalBackgroundSheet` with the multi-stop vertical gradient (`#163228` down to `#0C1914`), 10% opacity conservatory watermark, and the full 30+ precision leaves, ivy garlands, glasshouse arch geometry, and dewdrops.
  - Wrapped `CategoriesPage`, `ProfilePage`, `RecurringPage`, `SecurityPage`, and `AuthPage` with `BotanicalBackgroundSheet`, and upgraded `CategoriesPage` to `pageAppBar` with high-contrast tab indicators.

## [2.4.4] - 2026-11-10

### Changed
- **Phase 2 UI Redesign: Add / Edit Transaction Modal & Glass Keypad:**
  - Upgraded `CalculatorSheet` with the Enchanted Glasshouse aesthetic: high-contrast formula (`freshSage`) and display result (`incomeOnDark`), frosted glass keypad buttons with specular highlights, emerald containers for arithmetic operators, and soft berry tint for the Clear action.
  - Enhanced `TransactionForm` modal bottom sheet with 28px top rounded border and specular `#2A4D3E` edge, luminous amount field with tabular figures, illuminated `Rp ` prefix, and 3D glasshouse calculator launcher icon.
  - Upgraded `AppChip` across the design system to seamlessly render 3D glasshouse icon assets for categories and wallets with glowing emerald selection states.
  - Redesigned quick amount chips, more details toggles, date picker tiles, and receipt attachment cards with translucent glass surfaces.
  - Enhanced global `segmentedButtonTheme`, `chipTheme`, and `bottomSheetTheme` in `ThemeData` to enforce unified glasshouse styling.

## [2.4.3] - 2026-11-10

### Changed
- **High-Precision Botanical Foliage & Conservatory Backdrop:**
  - Redesigned `BotanicalBackgroundPainter` with 30+ meticulously detailed ovate botanical leaves featuring sharp apexes, central midribs, and symmetrical lateral veins.
  - Implemented cascading conservatory ivy garlands in upper corners, rich clustered understory foliage in lower corners, and reflective dewdrops.
  - Integrated authentic photorealistic conservatory foliage and vaulted columns from `glasshouse_bg.jpg` at 10% opacity into the main dashboard sheet.

## [2.4.2] - 2026-11-10

### Changed
- **Atmospheric Glasshouse Background (Option C):**
  - Replaced solid background canvas with an atmospheric multi-stop vertical gradient (`#163228` emerald mist to `#0C1914` moss shadow) and enhanced top specular glass border (`dewMint`).
  - Redesigned `BotanicalBackgroundPainter` with soft radial sunbeam light glow, conservatory vaulted glass arch geometry (`dewMint`), and calibrated botanical leaf silhouettes with delicate leaf rib details.
  - Aligned `_SheetEdge` on page AppBars to share the new specular edge and ambient emerald mist tone.

## [2.4.1] - 2026-11-10

### Changed
- **Phase 1 UI Redesign Benchmark (Dashboard / Home):**
  - Enhanced `HomePage` header with frosted glass action buttons for settings and more features.
  - Upgraded `DailyFinancialPulseCard` to match `AppCard`'s translucent emerald glass depth, specular `dewMint` highlights, and inner status ambient glow.
  - Polished `_FlowTile` with high-contrast semantic income and expense indicators, and refreshed `_AccountsQuickBar` with deep translucent container styling.
  - Refined `PeriodSwitcher`, `PeriodTypeToggle`, and `SectionHeader` with glass styling and consistent typography.

## [2.4.0] - 2026-11-10

### Added
- **Enchanted Glasshouse Visual Identity:**
  - Remade the botanical aesthetic into a modern enchanted conservatory with translucent glassmorphic surfaces, specular glass highlights, 24 bespoke 3D botanical glass icons (`assets/icons/glasshouse/`), and vaulted glasshouse architectural accents.
- **Atmospheric Conservatory Lock Screen & Glass Avatar Frame:**
  - Implemented serene glasshouse background with ambient lighting on `LockScreen` (`assets/images/glasshouse_bg.jpg`) and an intricate botanical glass wreath frame for user profile photos (`assets/images/frame_glasshouse.png`).
- **New Glasshouse Mark & Wordmark Branding:**
  - Designed and bundled the official Enchanted Glasshouse logo mark (protective glasshouse dome, flourishing coin stack pedestal, and orbiting enchanted light ring) across the application and landing page.

### Changed
- **Refined Glasshouse Typography & Palette:**
  - Integrated `GoogleFonts.outfit` for display/headings and `GoogleFonts.dmSans` with tabular figures for financial metrics, alongside the new Enchanted Glasshouse palette (`glasshouseGreen`: `#23483B`, `emeraldLeaf`: `#39745A`, `freshSage`: `#A9C5B1`, `dewMint`: `#D5E8DC`, `softIvory`: `#F7F8F4`, and `mossShadow`: `#10251F`).
- **Brand Lore & Tagline Alignment:**
  - Updated the signature brand quote in the About Sheet to reflect the Enchanted Glasshouse philosophy: *"Small steps, nurtured consistently, create meaningful growth."*

## [2.3.0] - 2026-11-10

### Changed
- **Focused Botanical Forest Identity:** Retired Cyberpunk theme mode and the in-app aesthetic switcher to unify Wall o' Pay 100% around the signature **Botanical Forest** visual identity (`Plus Jakarta Sans` typography with tabular figures, organic rounded geometry, and emerald/sage canvas decorations).
- **Backward-Compatible Sync & Backup Handling:** Cloud preference sync (`AppPrefsController.applyRemoteData`) and JSON backup imports (`importPreferences`) continue to accept and cleanly ignore legacy `themePreset` and `cyberpunkUnlocked` keys from older releases (`<= v2.2.0`).

### Removed
- Removed Cyberpunk color tokens, custom HUD painters (`CyberHeroCardPainter`, `CyberCanopyPainter`, `CyberBackgroundPainter`), `ShareTechMono` / `Rajdhani` theme styling, dual-theme localization maps (`_cyberId` / `_cyberEn`), About-sheet theme confirmation dialog, and unused `logo_cyberpunk.png` image assets.

## [2.2.0] - 2026-11-07

### Added
- **Android Home Screen Quick Shortcuts:**
  - Added dynamic launcher quick actions (**Add Expense**, **Add Income**, **Transfer Funds** in English & Indonesian) when long-pressing the Wall o' Pay home screen icon, opening `TransactionForm` immediately without splash delay or PIN/Biometric friction while keeping the underlying dashboard locked.
- **Streamlined Note Field on Main Transaction Form:**
  - Moved the **Note (optional)** input out of the collapsible *More details* section directly onto the primary `TransactionForm` for faster everyday logging.
- **On-Demand Interactive Cashflow Calendar (`TransactionsPage`):**
  - Added a toggleable Cashflow Calendar view in the Transactions tab header showing daily income and expense indicator dots across the active period, with one-tap date filtering and zero impact on initial page load.
- **Smart Split Bill Wallet Integration (`DebtsPage`):**
  - Enhanced the Split Bill sheet (`showSplitSheet`) with payment account (`Wallet`) selection and a toggle between recording **My share only** or **Full bill paid by me** as an expense transaction alongside friend debt entries.
- **Frequent Small Purchases ("Latte Factor") Insight (`InsightEngine`):**
  - Added deterministic detection for recurring micro-purchases (`<= Rp 50.000`, `>= 3x` per period) in the Insights tab, highlighting total accumulated spending and the dominant category.

## [2.1.2] - 2026-11-07

### Changed
- **Android Performance, Startup & APK Size Optimization:**
  - **Parallel Cold Start & Lightweight Timezones:** Switched from `timezone/data/latest_all.dart` to `latest_10y.dart` and parallelized independent startup tasks (`initializeDateFormatting`, `SharedPreferences`, `Firebase`, `NotificationService`, and `UpdateCheckerService`) via `Future.wait`, reducing cold-start latency.
  - **Lazy Tab Mounting in `HomeShell`:** Deferred instantiation of non-initial navigation tabs (`TransactionsPage`, `BudgetPage`, `InsightsPage`) inside `IndexedStack` until first visited, significantly reducing initial frame widget tree and stream overhead.
  - **Batched GPU Path Rendering:** Consolidated grid and scanline drawing loops in `CyberHeroCardPainter` and `CyberBackgroundPainter` into single `Path` draw calls to lower GPU command buffer overhead.
  - **SQL-Aggregated Wallet Balances & Category Usage:** Added `watchWalletNetFlows()` (`UNION ALL` + `GROUP BY` SQL aggregation) and SQL `COUNT(*)` in `categoryUsageCounts()` inside `AppDatabase`, eliminating the need to load all historical transactions into Dart memory to compute current wallet balances.
  - **Asset Bundling & Compression Optimization:** Losslessly compressed brand PNG assets and excluded unused `logo_hybrid.png` (1.56 MB) from the runtime asset bundle.

## [2.1.1] - 2026-11-07

### Fixed
- **Restored Authentic v1.11 Botanical Brand Launcher Icon:**
  - Restored the original, authentic Botanical Forest brand icon artwork directly from version 1.11 (`v1.11.38`) across all platforms (Android, iOS, Web PWA, Windows, and Landing Page).
  - Resolved root cause of shrinking home screen icons by removing `<inset android:inset="16%"/>` from `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, restoring standard 1:1 full-canvas rendering without artificial scaling artifacts.

## [2.1.0] - 2026-11-07

### 🌟 Visual Polish, HUD Telemetry & Profile Studio (Minor Feature Release)
Version 2.1.0 delivers major functional and aesthetic upgrades to Wall o' Pay — introducing a full-featured WhatsApp-style profile photo cropper and viewer, advanced sci-fi HUD chamfered geometry and monospace financial typography for Cyberpunk mode, an intentional minimalist theme switcher in About Wall o' Pay, full-bleed launcher icons, and comprehensive bilingual localization hardening.

### Added
- **WhatsApp-Style Profile Photo Studio & Interactive Cropper:**
  - Implemented an interactive circular photo cropper (`ProfilePhotoCropPage`) launching upon photo selection, featuring a circular viewfinder mask, rule-of-thirds grid, corner framing brackets, pinch-to-zoom/pan gestures, 90° rotation, and crisp 512×512 rendering.
  - Implemented full-screen interactive profile photo viewer (`ProfilePhotoViewPage`) with pinch-to-zoom, pan, and smooth Hero animation from the avatar.
  - Added WhatsApp-style bottom modal sheet with direct Camera (`ImagePicker.camera`) and Gallery (`ImagePicker.gallery`) options, view full-screen, and safe deletion confirmation.
- **Cyberpunk HUD Chamfered Geometry & Sci-Fi Telemetry:**
  - Integrated `GoogleFonts.shareTechMono` with tabular figures across all financial metrics and numeric values in Cyberpunk mode, preserving elegant `Plus Jakarta Sans` for Botanical mode.
  - Introduced authentic beveled sci-fi geometry (`BeveledRectangleBorder`) across cards (`HeroCard`, `AppCard`), dialogs, snackbars, floating action buttons, chips, and PIN pad keycaps.
  - Implemented smooth financial counter roll-up animation (`AnimatedMoneyCounter`) on the home dashboard.
  - Added horizontal CRT scanlines, crosshair reticle markers (`+`), atmospheric radial glows (`CyberBackgroundPainter`), and breathing radar pulses (`_PulsingBeacon`) on `DailyFinancialPulseCard`.
  - Upgraded user avatar in Cyberpunk mode with a chamfered HUD profile badge and tactical ID micro-telemetry.
- **Discreet Theme Switcher in "About Wall o' Pay":**
  - Integrated a minimalist theme toggle badge (`[ 🌿 Botanical ⇄ ]` / `[ ⚡ Cyberpunk ⇄ ]`) inside the About sheet, featuring an immersive contextual warning dialog before switching visual modes.
  - Streamlined primary Settings page by removing redundant theme toggles, keeping dual aesthetics as an intentional discovery feature.
- **Expanded Automated Test Suite:**
  - Added extensive test suites for profile photo crop/view interactions (`test/profile_photo_test.dart`), theme typography & HUD token systems (`test/theme_test.dart`), and about sheet theme switching (`test/about_sheet_test.dart`), bringing total automated test coverage to **82 passing tests (100%)**.

### Changed
- **Botanical Full-Bleed Adaptive Launcher Icon:**
  - Scaled Android adaptive icon foreground layer (`assets/images/logo_foreground.png`) to optimal full-bleed dimensions with a solid botanical forest background (`#11392E`), eliminating dark margins and preventing launcher shrinking across Samsung One UI, Google Pixel, and Xiaomi.
  - Provided a modernized multi-resolution web favicon and touch icon suite (`favicon.ico`, `favicon.png`, `apple-touch-icon.png`, PWA 192/512).
- **Web Landing Page & Showcase Modernization (`docs/`):**
  - Updated web showcase, CSS styling, and live previews to reflect the latest profile photo studio, monospace HUD typography, and theme toggle interactions.

### Fixed
- **Exhaustive Bilingual Localization & Terminology Standards:**
  - Standardized bottom navigation labels (`Insight` -> `Analisis`), page titles (`Financial Insights` -> `Analisis Finansial`), period budgets (`This Month's Budget` -> `Anggaran Bulan Ini`), transaction filters, and account/category dropdown selectors in Debts & Goals dialogs.
  - Localized Netrunner greeting headers, time cycle badges, exit dialogs, and Daily Financial Pulse spending phase guides into authentic Indonesian and English.
- **Elimination of Theme Color Leaks:**
  - Fixed hardcoded Botanical green/mint tokens across lock screen PIN indicators, settings action dialogs, and budget tags when running in Cyberpunk mode.

---

## [2.0.0] - 2026-11-06

### 🌟 A New Era of Wall o' Pay (Major Milestone Release)
Version 2.0 marks the start of a new chapter for Wall o' Pay — bringing a complete dual-design identity with the **Cyberpunk Neo-Tokyo** theme, hardware-backed **Universal Biometric Unlock**, key-stretched security architecture, and high-framerate 60/120 FPS rendering across all screens.

### Added
- **Dual Visual Identity & Cyberpunk Neo-Tokyo Theme:**
  - Introduced the **Cyberpunk Neo-Tokyo** theme as a first-class visual experience alongside the organic **Botanical Garden** theme.
  - Deep OLED midnight canvas (`#0D0F18`), high-voltage cyan accents (`#00F0FF`), and neon telemetry glowing cards.
  - Added custom circuit canopy canvases, grid painters, and futuristic brand badges.
  - Designed the **Hybrid App Identity** uniting botanical leaf motifs with glowing cyber circuits across launcher icons and web showcase assets.
- **Universal Biometric Unlock (Fingerprint & Face Recognition):**
  - Integrated device-level biometric authentication (`local_auth`) seamlessly alongside the 6-digit App PIN Lock, automatically adapting to devices with Fingerprint only, Face Unlock only, or both.
  - Added automatic biometric prompt on `LockScreen` launch and a dedicated biometric quick-trigger button on `PinPad`.
  - Added **Biometric Unlock** toggle in `SecurityPage` with hardware enrollment verification and per-account local persistence.
- **Hardware-Backed Secret Isolation (`FlutterSecureStorage`):**
  - Migrated PIN hashes, salts, and lockout states out of plaintext storage into Android Keystore (`EncryptedSharedPreferences`) and iOS Keychain with seamless automatic migration for existing accounts.
- **Firestore Security Rules (`firestore.rules`):**
  - Implemented strict owner-only access controls for `/users/{uid}` and all financial subcollections, restricting `/usernames/{username}` against unauthenticated bulk enumeration.

### Changed
- **Security Hardening & Anti-Data-Leakage Architecture:**
  - **Key-Stretched PIN Hashing (`v2` HMAC-SHA256):** Upgraded PIN hashing from single-pass SHA-256 to 2,048-iteration salted HMAC-SHA256 with seamless on-unlock auto-upgrade from legacy `v1` hashes.
  - **Persistent Brute-Force PIN Lockout:** Moved PIN failure tracking and lockout timers (`30s` -> `120s` -> `300s` exponential backoff) into persistent encrypted storage (`Lock`) so lockouts cannot be bypassed by force-closing the app.
  - **Sensitive File Purge on Logout / Data Reset:** `AppDatabase.resetAllData()`, `ExportService`, and `ReportService` now automatically delete local receipt image attachments, `shared_receipts`, and temporary `.csv`/`.json`/`.pdf` export files after sharing or logging out.
  - **Android Backup & Signing Protection:** Disabled unencrypted OS auto-backup (`android:allowBackup="false"`) in `AndroidManifest.xml`, untracked release signing credentials from Git (`key.properties` & `*.jks`), and added GitHub Secrets support to `.github/workflows/release.yml`.
- **60/120 FPS Rendering & Scroll Performance Optimization:**
  - Fixed `shouldRepaint` on all 6 custom decorative painters (`BotanicalCanopyPainter`, `BotanicalHeroCardPainter`, `BotanicalBackgroundPainter`, `CyberHeroCardPainter`, `CyberCanopyPainter`, `CyberBackgroundPainter`) and wrapped static vector canvases in `RepaintBoundary` (`isComplex: true`) to eliminate redundant GPU rasterization on every frame.
  - Replaced full-screen `ShaderMask(blendMode: BlendMode.dstIn)` on `HomePage` with a lightweight top fade overlay, eliminating offscreen `saveLayer` frame drops during scrolling.
  - Converted `TransactionsPage` to lazy `CustomScrollView` + `SliverList.builder` with 150ms search input debounce and cached `MemoryImage` avatar providers in `ProfileState`.
- **Modernized Landing Page & Interactive Documentation (`docs/`):**
  - Updated showcase to demonstrate the dual design language (Cyberpunk & Botanical) with live preview cards, direct download links, and synchronized specifications.

---

## [1.11.38] - 2026-11-05

### Added
- **Comprehensive Architecture Guide (`ARCHITECTURE.md`) & Codebase Documentation:**
  - Created `ARCHITECTURE.md` mapping the entire `lib/` directory (`core/`, `data/`, `features/`), reactive data flow (Flutter UI ↔ Riverpod ↔ Drift SQLite ↔ Firebase Cloud Sync), startup gate pipeline, and core financial formulas.
  - Added library-level and class/function-level Bahasa Indonesia docstrings (`///`) across all modules in `lib/` to support learning and long-term maintenance.

---

## [1.11.37] - 2026-11-05

### Changed
- **Settings Page Colorful Icon Badges & Divider Alignment:**
  - Upgraded all list tiles and switches across `SettingsPage` (**Budget & reminders**, **Security**, **Manual Backup & Export**, **Data**, **Account**, and **About & Support**) with rounded color-coded icon badges (`iconBadge`) and aligned dividers (`indent: 68`) to match the modern visual aesthetic of `MorePage`.

---

## [1.11.36] - 2026-11-05

### Changed
- **More Features Page Architecture & Visual Upgrade:**
  - Redesigned `MorePage` into 3 categorized functional cards: **Money & Wallets** (Accounts, Transfer, Debts), **Planning & Goals** (Budget, Savings Goals, Recurring), and **Tools & Settings** (Categories, PDF Report, Settings).
  - Enhanced list tiles with rounded container badges, curated category icon tinting, and dividers for improved visual hierarchy.
- **Full-Spectrum Botanical Ambient Background across All Sub-Pages:**
  - Extended `BotanicalBackgroundSheet` to `MorePage`, `AccountsPage`, `SettingsPage`, `DebtsPage`, and `GoalsPage`, ensuring unified botanical depth and emerald glow throughout the entire application navigation.

---

## [1.11.35] - 2026-11-05

### Changed
- **Bottom FAB Scroll Spacing & Listview Padding Polish:**
  - Increased bottom scroll padding on primary feeds (Home, Transactions, Budget, and Insights) from `24-32px` to `96px` so the docked center `+` Floating Action Button never obscures the bottom-most list items or daily allowance status.
- **Global Botanical Ambient Background Across All Tabs:**
  - Wrapped content sheets in `TransactionsPage`, `BudgetPage`, and `InsightsPage` with `BotanicalBackgroundSheet`, ensuring consistent soft emerald radial glow and ambient leaf contours across all tabs.
- **Budget Pulse Card Over-Budget Clarity:**
  - Redesigned period budget tracker in `DailyFinancialPulseCard` with high-contrast `AppColors.expenseOnDark` color coding and explicit deficit amount labeling (`{pct}% used (Over by {amount})` / `{pct}% terpakai (Lewat {amount})`), eliminating guesswork when limits are exceeded.
- **App Exit Dialog Theme Polish:**
  - Refined app exit confirmation dialog styling with `AppColors.sage` icon accent and crisp white button typography, improving visibility on dark surfaces.

---

## [1.11.34] - 2026-11-05

### Added
- **Signature Botanical Forest Canopy & Watermark Effects:**
  - Added vector-based botanical foliage decorations rendered with zero-overhead `CustomPainter`:
    - **Header Canopy:** Rendered subtle curving leaves and stem silhouettes (`BotanicalCanopyPainter`) in the app bar across all sub-pages and the home header.
    - **Balance Card Ambient Glow & Contour Texture:** Replaced literal leaf watermark inside `HeroCard` with an elegant, modern emerald aurora radial glow and delicate circular growth/topographic contour rings (`BotanicalHeroCardPainter`), keeping numeric figures crisp and readable.
    - **Background Glow & Ambient Silhouettes:** Enhanced the main sheet background (`BotanicalBackgroundPainter`) with a gentle emerald radial glow and ultra-low opacity leaf accents.

---

## [1.11.33] - 2026-11-05

### Added
- **Home Balance Card Accounts Shortcut & Quick Preview Bar:**
  - Added an interactive navigation affordance to the **Total Balance** title with a trailing chevron icon `›`, allowing users to open the Accounts & Wallets page directly with one tap.
  - Added a compact **Accounts Quick Bar** immediately beneath the Income and Expense metrics on the home card. Displays overlapping color-coded avatar icons for active accounts, an account count summary with primary wallet names, and a quick shortcut into Account Management. If no accounts are set up yet, presents a clean, tap-to-add action button.
  - Added bilingual localization strings (`1 Account` / `1 Akun`, `{count} Accounts` / `{count} Akun`, `Add accounts & wallets` / `Tambah akun & rekening`) in both English and Indonesian.

---

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
