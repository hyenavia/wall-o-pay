/**
 * Wall o' Pay — Landing Page Interactive Logic
 * Concept adapted from Lunera | Signature Vice City Sunset Theme
 *
 * Features:
 * - Bilingual Support (EN default | ID) with instant 0ms switch & localStorage persistence
 * - Interactive Multi-Currency Preview (IDR primary | USD global) across Mockups, Widgets & Calibrator
 * - Dynamic Greeting & Live Time in Phone Mockup
 * - Interactive Cashflow Command Engine Switcher (Pulse, Pools, Rapid, Debt)
 * - Interactive Daily Budget Pulse Calibrator (Real-Time Income Slider)
 * - GitHub Releases API Version Sync with Direct APK Asset Resolution
 * - Active ScrollSpy & Header Elevation
 * - Accessible Mobile Navigation Drawer
 */

const REPO_NAME = "hyenavia/wall-o-pay";
const APP_VERSION = "3.2.0";

let activeLang = "en";
let activeCurrency = "IDR";
let activeMode = "pulse";
let activeCalibratorStep = 2;

const I18N = {
  en: {
    skipLink: "Skip to main content",
    navHome: "Home",
    navCapabilities: "Capabilities",
    navInteractive: "Interactive",
    navWidgets: "Widgets",
    navArchitecture: "Architecture",
    navFaq: "FAQ",
    downloadApkShort: "Download APK",
    heroKicker: `Version ${APP_VERSION} · 100% Offline-First Finance`,
    heroTitle: 'Grow Better<br><em class="hero-title-accent">Financial Habits.</em>',
    heroLead:
      "A personal finance fortress engineered for steady growth. Instant 0ms local SQLite writes, autonomous 50/30/20 budget pools, and multi-currency support (IDR & 6 global currencies)—safeguarded by biometric Keystore security.",
    heroExploreBtn: "Explore Architecture",
    abiNote:
      'Default APK targets Android 64-bit (<code>arm64-v8a</code>). Using a 32-bit device or emulator? <a href="https://github.com/hyenavia/wall-o-pay/releases/latest" target="_blank" rel="noopener">Choose another ABI on GitHub Releases</a>.',
    proofZeroTelemetry: "Zero Telemetry",
    proofSqlite: "0ms Drift SQLite",
    proofGlobal: "IDR & Global Currencies",
    proofOpenSource: "Free & Open Source",
    cap1Title: "0ms Drift SQLite Engine",
    cap1Desc: "Pure offline-first architecture with instant sub-millisecond local queries.",
    cap2Title: "Hardware Keystore Shield",
    cap2Desc: "2,048-iteration salted HMAC-SHA256 & biometric unlock in Android sandbox.",
    cap3Title: "50/30/20 Smart Pools",
    cap3Desc: "Autonomous distribution into Needs, Wants, and Savings with monthly rollover.",
    cap4Title: "Sovereign Data Vault",
    cap4Desc: "Zero ads, zero trackers, and free unmetered PDF, CSV & JSON statement exports.",
    trackEyebrow: "✦ Interactive Engine ✦",
    trackTitle: "Command Your Flow, <em>In Real-Time</em>",
    trackLead:
      "Tap any mode below or switch currency to see how Wall o' Pay calculates and protects your financial horizon without leaving the page.",
    trackEngineKicker: "Adaptive Cashflow Engine",
    modePulseName: "Daily Pulse Radar",
    modePulseDetail: "Safe spending speed",
    modePoolsName: "50/30/20 Pools",
    modePoolsDetail: "Autonomous rollover",
    modeRapidName: "Rapid 5s Logging",
    modeRapidDetail: "Inline arithmetic math",
    modeDebtName: "Debt & Split Bills",
    modeDebtDetail: "Due date payoff alerts",
    trackFeat1Title: "Dynamic Spending Pulse",
    trackFeat1Desc:
      "Dynamically calibrates your daily limit based on remaining month days and fixed obligations.",
    trackFeat2Title: "Built in Indonesia, Ready Everywhere",
    trackFeat2Desc:
      "Starts in Rupiah (IDR) and Indonesian or English, with instant switching to USD, EUR, GBP, SGD, MYR, and JPY.",
    widgetsEyebrow: "✦ Glanceable Offline Care ✦",
    widgetsTitle: "Glanceable Numbers, <em>Right on Your Screen</em>",
    widgetsLead:
      "Command your cashflow without unlocking the full app. Native Android Home Screen widgets powered by Wall o' Pay's instant local Drift SQLite database.",
    w1Brand: "DAILY PULSE RADAR",
    w1Status: "Safe",
    w1DialSub: "SAFE TODAY",
    w1Foot: "Remaining November Quota",
    w2Brand: "QUICK 5s LOG",
    w2Status: "0ms Local",
    w2Item1: "☕ Dining & Coffee",
    w2Item2: "🛒 Supermarket Needs",
    w2Foot: "Tap icon on home screen to log in 5s",
    w3Brand: "50/30/20 ALLOCATION",
    w3Status: "Balanced",
    w3Needs: "Needs (50%)",
    w3NeedsPct: "62% spent",
    w3Wants: "Wants (30%)",
    w3WantsPct: "40% spent",
    w3Savings: "Savings (20%)",
    w3SavingsPct: "85% saved",
    archEyebrow: "✦ Architectural Integrity ✦",
    archTitle: "Engineered for <em>Zero Compromise</em>",
    archLead:
      "Test drive our live budget calibrator below, or explore the cryptographic fortress shielding your financial privacy.",
    calBadge: "Live Calibrator",
    calTitle: "Calibrate Your Daily Safe Velocity",
    calDailyLabel: "Daily Safe Pulse",
    calNeedsLabel: "Needs (50%)",
    calSavingsLabel: "Savings (20%)",
    bentoKeyTitle: "Hardware Biometric Keystore",
    bentoKeyDesc:
      "PIN never stored in plaintext. Key-stretched with 2,048-iteration salted HMAC-SHA256 inside Android Keystore hardware.",
    bentoSqlTitle: "Zero Cloud Latency",
    bentoSqlDesc:
      "Drift SQLite compiles straight into native C SQLite bindings. Reads and writes take less than 0.2ms.",
    bentoExportTitle: "Free Export & Global Multi-Currency",
    bentoExportDesc:
      "Built with Indonesian Rupiah (IDR) as primary and ready for global users with USD, EUR, GBP, SGD, MYR, and JPY display—plus unlimited PDF, CSV, and JSON backups with zero paywalls.",
    badgePdf: "PDF Reports",
    badgeCsv: "CSV Spreadsheets",
    badgeJson: "JSON Backup",
    faqEyebrow: "✦ The Wall o' Pay Lore ✦",
    faqTitle: "Clear Answers.<br><em>Zero Surprises.</em>",
    faqQuote:
      "“A protective financial fortress where every payment you make and save is nurtured to grow into a brighter tomorrow.”",
    faqSub:
      "Wall o' Pay is open-source, offline-first, and completely free of predatory trackers or forced cloud subscriptions.",
    faqQ1: "Is Wall o' Pay completely free and ad-free?",
    faqA1:
      "Yes. Wall o' Pay is 100% open-source under the MIT License—there are no ads, no trackers, no subscriptions, and zero paywalls on PDF, CSV, or JSON exports.",
    faqQ2: "Does it work completely without an internet connection?",
    faqA2:
      "Yes. Wall o' Pay uses an offline-first Drift SQLite engine, so logging transactions, checking your Daily Financial Pulse, and reviewing analytics work instantaneously with 0ms latency even in airplane mode.",
    faqQ3: "Can I use currencies other than Indonesian Rupiah (IDR)?",
    faqA3:
      "Yes. While IDR (Rp) is the primary default, you can switch anytime in Settings or Onboarding to USD ($), EUR (€), GBP (£), SGD (S$), MYR (RM), or JPY (¥) with matching number separators and quick-amount presets—all 100% offline.",
    faqQ4: "How are my PIN and biometric credentials protected?",
    faqA4:
      "Your PIN is never saved in plaintext—it is protected with 2,048-iteration salted HMAC-SHA256 hashing within the Android Keystore hardware module, alongside native biometric fingerprint and face unlock.",
    faqQ5: "Why is it distributed as a direct APK via GitHub Releases?",
    faqA5:
      "Direct distribution via GitHub Releases allows anyone to inspect the source code, verify builds, and install updates immediately without corporate app store delays.",
    artEyebrow: "✦ Vice City Sunset Aesthetic ✦",
    artTitle: 'Signature Atmosphere.<br><em class="hero-title-accent">Built For Focus &amp; Financial Peace.</em>',
    artLead:
      "A neon-infused sanctuary engineered with 1980s synthwave nostalgia and cutting-edge offline computing.",
    ctaEyebrow: "✦ Sovereign Financial Sanctuary ✦",
    ctaTitle: 'Start Growing Your<br><em class="hero-title-accent">Financial Future.</em>',
    ctaLead:
      "Make every financial decision count with Wall o' Pay. 100% private, offline-first, and beautifully engineered for daily peace of mind.",
    viewReleaseNotes: "View Release Notes",
    footerTagline:
      "Your money, under your control. A modern, offline-first personal finance application crafted in Indonesia with global multi-currency support.",
    footerNavTitle: "Navigation",
    footerInteractive: "Interactive Engine",
    footerWidgets: "Android Widgets",
    footerCommunityTitle: "Open Source & Community",
    footerGithub: "GitHub Repository",
    footerChangelog: "Changelog",
    footerLicense: "MIT License",
    footerFeedback: "Feedback Form"
  },
  id: {
    skipLink: "Lewati ke konten utama",
    navHome: "Beranda",
    navCapabilities: "Keunggulan",
    navInteractive: "Interaktif",
    navWidgets: "Widget",
    navArchitecture: "Arsitektur",
    navFaq: "FAQ",
    downloadApkShort: "Unduh APK",
    heroKicker: `Versi ${APP_VERSION} · Keuangan 100% Offline-First`,
    heroTitle: 'Bangun Kebiasaan<br><em class="hero-title-accent">Finansial Sehat.</em>',
    heroLead:
      "Benteng keuangan pribadi untuk pertumbuhan stabil. Tulis SQLite lokal 0ms, pos anggaran 50/30/20 otomatis, dan dukungan multi-mata uang (IDR & 6 mata uang global)—dilindungi keamanan biometrik Keystore.",
    heroExploreBtn: "Jelajahi Arsitektur",
    abiNote:
      'APK bawaan menargetkan Android 64-bit (<code>arm64-v8a</code>). Memakai perangkat 32-bit atau emulator? <a href="https://github.com/hyenavia/wall-o-pay/releases/latest" target="_blank" rel="noopener">Pilih ABI lain di GitHub Releases</a>.',
    proofZeroTelemetry: "Tanpa Telemetri",
    proofSqlite: "0ms Drift SQLite",
    proofGlobal: "IDR & Mata Uang Global",
    proofOpenSource: "Gratis & Open Source",
    cap1Title: "Mesin Drift SQLite 0ms",
    cap1Desc: "Arsitektur offline-first murni dengan kueri lokal sekejap di bawah 1 milidetik.",
    cap2Title: "Perisai Hardware Keystore",
    cap2Desc: "Hash HMAC-SHA256 2.048 iterasi & kunci biometrik aman di sandbox Android.",
    cap3Title: "Pos Pintar 50/30/20",
    cap3Desc: "Pembagian otomatis ke Kebutuhan, Keinginan, dan Tabungan dengan rollover.",
    cap4Title: "Brankas Data Berdaulat",
    cap4Desc: "Bebas iklan, bebas pelacak, dan ekspor laporan PDF, CSV & JSON tanpa batas.",
    trackEyebrow: "✦ Mesin Interaktif ✦",
    trackTitle: "Kendalikan Arus Kas, <em>Secara Nyata</em>",
    trackLead:
      "Ketuk mode di bawah atau ganti mata uang untuk melihat bagaimana Wall o' Pay menghitung dan menjaga batas aman harian Anda.",
    trackEngineKicker: "Mesin Arus Kas Adaptif",
    modePulseName: "Radar Nadi Harian",
    modePulseDetail: "Laju belanja aman",
    modePoolsName: "Pos 50/30/20",
    modePoolsDetail: "Rollover otomatis",
    modeRapidName: "Catat Cepat 5 Detik",
    modeRapidDetail: "Kalkulator langsung",
    modeDebtName: "Utang & Patungan",
    modeDebtDetail: "Pengingat jatuh tempo",
    trackFeat1Title: "Nadi Belanja Dinamis",
    trackFeat1Desc:
      "Menyesuaikan kuota harian otomatis berdasarkan sisa hari periode dan tagihan rutin.",
    trackFeat2Title: "Karya Indonesia, Siap Global",
    trackFeat2Desc:
      "Hadir dengan Rupiah (IDR) dan Bahasa Indonesia/Inggris, serta mendukung USD, EUR, GBP, SGD, MYR, dan JPY.",
    widgetsEyebrow: "✦ Informasi Sekilas Offline ✦",
    widgetsTitle: "Angka Penting, <em>Langsung di Layar Utama</em>",
    widgetsLead:
      "Pantau arus kas tanpa membuka penuh aplikasi. Widget layar utama Android bertenaga database lokal Drift SQLite.",
    w1Brand: "RADAR NADI HARIAN",
    w1Status: "Aman",
    w1DialSub: "AMAN HARI INI",
    w1Foot: "Sisa Kuota November",
    w2Brand: "CATAT CEPAT 5 DETIK",
    w2Status: "0ms Lokal",
    w2Item1: "☕ Kopi & Makan",
    w2Item2: "🛒 Belanja Kebutuhan",
    w2Foot: "Ketuk ikon di layar utama untuk catat 5 detik",
    w3Brand: "ALOKASI 50/30/20",
    w3Status: "Seimbang",
    w3Needs: "Kebutuhan (50%)",
    w3NeedsPct: "62% terpakai",
    w3Wants: "Keinginan (30%)",
    w3WantsPct: "40% terpakai",
    w3Savings: "Tabungan (20%)",
    w3SavingsPct: "85% tersimpan",
    archEyebrow: "✦ Integritas Arsitektur ✦",
    archTitle: "Dirancang Tanpa <em>Kompromi</em>",
    archLead:
      "Uji kalibrator anggaran di bawah ini, atau lihat benteng kriptografi yang melindungi privasi keuangan Anda.",
    calBadge: "Kalibrator Langsung",
    calTitle: "Kalibrasi Batas Aman Harian Anda",
    calDailyLabel: "Nadi Aman Harian",
    calNeedsLabel: "Kebutuhan (50%)",
    calSavingsLabel: "Tabungan (20%)",
    bentoKeyTitle: "Biometric Hardware Keystore",
    bentoKeyDesc:
      "PIN tidak pernah disimpan sebagai teks polos. Di-hash 2.048 iterasi salted HMAC-SHA256 di modul Android Keystore.",
    bentoSqlTitle: "Nol Latensi Cloud",
    bentoSqlDesc:
      "Drift SQLite dikompilasi langsung ke binding C SQLite native. Baca dan tulis data kurang dari 0,2ms.",
    bentoExportTitle: "Ekspor Gratis & Multi-Mata Uang Global",
    bentoExportDesc:
      "Dibuat di Indonesia dengan IDR sebagai utama dan siap dipakai secara global (USD, EUR, GBP, SGD, MYR, JPY)—lengkap dengan ekspor PDF, CSV, dan JSON gratis.",
    badgePdf: "Laporan PDF",
    badgeCsv: "Spreadsheet CSV",
    badgeJson: "Cadangan JSON",
    faqEyebrow: "✦ Kisah Wall o' Pay ✦",
    faqTitle: "Jawaban Jelas.<br><em>Tanpa Kejutan.</em>",
    faqQuote:
      "“Benteng keuangan yang melindungi setiap pengeluaran dan tabungan Anda agar tumbuh menuju masa depan yang lebih cerah.”",
    faqSub:
      "Wall o' Pay bersifat open-source, offline-first, dan sepenuhnya bebas dari pelacak maupun langganan paksa.",
    faqQ1: "Apakah Wall o' Pay benar-benar gratis dan bebas iklan?",
    faqA1:
      "Ya. Wall o' Pay 100% open-source berlisensi MIT—tanpa iklan, tanpa pelacak, tanpa langganan, dan ekspor PDF, CSV, maupun JSON gratis selamanya.",
    faqQ2: "Apakah aplikasi tetap berjalan penuh tanpa koneksi internet?",
    faqA2:
      "Ya. Mesin Drift SQLite offline-first membuat pencatatan transaksi, Radar Nadi Harian, dan analitik bekerja instan 0ms bahkan dalam mode pesawat.",
    faqQ3: "Apakah bisa memakai mata uang selain Rupiah (IDR)?",
    faqA3:
      "Ya. Meski IDR (Rp) menjadi default utama, Anda bisa beralih kapan saja di Pengaturan atau Onboarding ke USD ($), EUR (€), GBP (£), SGD (S$), MYR (RM), atau JPY (¥) secara offline.",
    faqQ4: "Bagaimana PIN dan biometrik saya diamankan?",
    faqA4:
      "PIN tidak pernah disimpan polos—melainkan di-hash dengan salted HMAC-SHA256 2.048 iterasi di Android Keystore bersama kunci sidik jari dan wajah.",
    faqQ5: "Mengapa dirilis sebagai APK langsung di GitHub Releases?",
    faqA5:
      "Distribusi langsung melalui GitHub Releases memudahkan siapa pun meninjau kode sumber, memverifikasi build, dan mengunduh pembaruan secara instan.",
    artEyebrow: "✦ Estetika Vice City Sunset ✦",
    artTitle: 'Atmosfer Khas.<br><em class="hero-title-accent">Untuk Fokus &amp; Ketenangan Finansial.</em>',
    artLead:
      "Ruang visual bernuansa synthwave 1980-an yang dipadukan dengan komputasi offline modern.",
    ctaEyebrow: "✦ Benteng Finansial Pribadi ✦",
    ctaTitle: 'Mulai Bangun<br><em class="hero-title-accent">Masa Depan Finansial.</em>',
    ctaLead:
      "Jadikan setiap keputusan finansial lebih terarah bersama Wall o' Pay. 100% privat, offline-first, dan dirancang untuk ketenangan harian.",
    viewReleaseNotes: "Lihat Catatan Rilis",
    footerTagline:
      "Uang Anda, kendali Anda. Aplikasi keuangan pribadi offline-first yang dibuat di Indonesia dengan dukungan multi-mata uang global.",
    footerNavTitle: "Navigasi",
    footerInteractive: "Mesin Interaktif",
    footerWidgets: "Widget Android",
    footerCommunityTitle: "Open Source & Komunitas",
    footerGithub: "Repositori GitHub",
    footerChangelog: "Catatan Perubahan",
    footerLicense: "Lisensi MIT",
    footerFeedback: "Formulir Masukan"
  }
};

const MODE_DATA = {
  IDR: {
    en: {
      pulse: {
        cardLabel: "Active Safe Daily Quota",
        amount: "Rp 145.000",
        amountSub: "/ day safe to spend",
        badgeText: "Safe Speed",
        badgeClass: "badge-safe",
        meterScale: 0.38,
        meterGradient: "linear-gradient(90deg, var(--emerald), var(--neon-cyan))",
        stats: [
          { label: "Remaining", val: "Rp 4.35M", pos: false },
          { label: "Cycle", val: "18 Days", pos: false },
          { label: "Buffer", val: "+14.2%", pos: true }
        ],
        txTitle: "Primary Salary (Cashflow In)",
        txSub: "Direct Deposit • Today",
        txAmount: "+Rp 8.500.000",
        txIsPositive: true,
        tx2Title: "Morning Espresso & Oat",
        tx2Sub: "Wants Pool • 08:24",
        tx2Amount: "-Rp 34.000",
        tx2IsPositive: false,
        dockTab: "home",
        card2Label: "Monthly Safe Velocity",
        card2Value: "62% Remaining",
        card2Sub: "Steady surplus momentum",
        chartLine: "M0,58 Q40,48 80,36 T160,26 T220,14",
        chartArea: "M0,58 Q40,48 80,36 T160,26 T220,14 L220,72 L0,72 Z",
        chartDotX: 165,
        chartDotY: 25,
        breakdown: [
          { label: "Needs Pool", val: "50%", scale: 0.5 },
          { label: "Wants Pool", val: "30%", scale: 0.3 },
          { label: "Savings Reserve", val: "20%", scale: 0.2 }
        ],
        mascotAvatar: "images/chibi/chibi_01.png"
      },
      pools: {
        cardLabel: "Monthly Pool Allocation",
        amount: "Rp 8.500.000",
        amountSub: "Needs (50%) · Wants (30%) · Savings (20%)",
        badgeText: "Autonomous",
        badgeClass: "badge-pools",
        meterScale: 0.5,
        meterGradient: "linear-gradient(90deg, var(--sunset-magenta) 50%, var(--neon-cyan) 80%, var(--emerald) 100%)",
        stats: [
          { label: "Needs", val: "Rp 4.25M", pos: false },
          { label: "Wants", val: "Rp 2.55M", pos: false },
          { label: "Saved", val: "Rp 1.70M", pos: true }
        ],
        txTitle: "Emergency Reserve Deposit",
        txSub: "Savings Pool (20%) • Automatic",
        txAmount: "+Rp 1.700.000",
        txIsPositive: true,
        tx2Title: "Monthly Fiber & Utilities",
        tx2Sub: "Needs Pool (50%) • Auto-Logged",
        tx2Amount: "-Rp 420.000",
        tx2IsPositive: false,
        dockTab: "budget",
        card2Label: "Needs Pool Exhaustion",
        card2Value: "62% Spent",
        card2Sub: "Groceries & utilities on track",
        chartLine: "M0,54 Q55,44 105,34 T175,28 T220,20",
        chartArea: "M0,54 Q55,44 105,34 T175,28 T220,20 L220,72 L0,72 Z",
        chartDotX: 135,
        chartDotY: 31,
        breakdown: [
          { label: "Needs Utilized", val: "62%", scale: 0.62 },
          { label: "Wants Utilized", val: "41%", scale: 0.41 },
          { label: "Savings Locked", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_03.png"
      },
      rapid: {
        cardLabel: "Instant SQLite Transaction",
        amount: "-Rp 28.000",
        amountSub: "Built-in Math: 18000 + 10000",
        badgeText: "0ms Written",
        badgeClass: "badge-fast",
        meterScale: 0.18,
        meterGradient: "linear-gradient(90deg, var(--sunset-orange), var(--sunset-magenta))",
        stats: [
          { label: "Write", val: "0.12 ms", pos: true },
          { label: "Vault", val: "Receipt", pos: false },
          { label: "Sync", val: "Offline", pos: false }
        ],
        txTitle: "Coffee & Pastry",
        txSub: "Food & Dining • Photo Receipt Vault",
        txAmount: "-Rp 28.000",
        txIsPositive: false,
        tx2Title: "Commuter Rail Top-Up",
        tx2Sub: "Transport • Inline Calc",
        tx2Amount: "-Rp 50.000",
        tx2IsPositive: false,
        dockTab: "tx",
        card2Label: "Local Database Write Time",
        card2Value: "0.12 ms",
        card2Sub: "Zero cloud wait • Encrypted",
        chartLine: "M0,48 Q45,52 95,40 T165,30 T220,18",
        chartArea: "M0,48 Q45,52 95,40 T165,30 T220,18 L220,72 L0,72 Z",
        chartDotX: 110,
        chartDotY: 38,
        breakdown: [
          { label: "SQLite Commit", val: "0.12ms", scale: 0.92 },
          { label: "AES Keystore", val: "Active", scale: 1.0 },
          { label: "Cloud Queue", val: "0 Pending", scale: 0.12 }
        ],
        mascotAvatar: "images/chibi/chibi_04.png"
      },
      debt: {
        cardLabel: "Active Receivables & Debts",
        amount: "Rp 1.250.000",
        amountSub: "3 settled · 1 pending due in 4 days",
        badgeText: "Due Alert",
        badgeClass: "badge-due",
        meterScale: 0.75,
        meterGradient: "linear-gradient(90deg, var(--neon-cyan), var(--amber))",
        stats: [
          { label: "Settled", val: "3 / 4", pos: true },
          { label: "Next Due", val: "4 Days", pos: false },
          { label: "Owed", val: "Rp 350K", pos: true }
        ],
        txTitle: "Dinner Party Split (Sarah)",
        txSub: "Custom Split Bill • Pending Due",
        txAmount: "+Rp 350.000",
        txIsPositive: true,
        tx2Title: "Studio Gear Installment",
        tx2Sub: "Auto-Payoff • Settled",
        tx2Amount: "-Rp 450.000",
        tx2IsPositive: false,
        dockTab: "goals",
        card2Label: "Payoff Countdown",
        card2Value: "4 Days Left",
        card2Sub: "Lock-screen due reminder set",
        chartLine: "M0,62 Q50,52 100,38 T170,22 T220,12",
        chartArea: "M0,62 Q50,52 100,38 T170,22 T220,12 L220,72 L0,72 Z",
        chartDotX: 195,
        chartDotY: 16,
        breakdown: [
          { label: "Sarah Split", val: "75%", scale: 0.75 },
          { label: "Alex Split", val: "100%", scale: 1.0 },
          { label: "Team Lunch", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_08.png"
      }
    },
    id: {
      pulse: {
        cardLabel: "Kuota Aman Harian Aktif",
        amount: "Rp 145.000",
        amountSub: "/ hari aman dibelanjakan",
        badgeText: "Laju Aman",
        badgeClass: "badge-safe",
        meterScale: 0.38,
        meterGradient: "linear-gradient(90deg, var(--emerald), var(--neon-cyan))",
        stats: [
          { label: "Tersisa", val: "Rp 4,35jt", pos: false },
          { label: "Siklus", val: "18 Hari", pos: false },
          { label: "Buffer", val: "+14,2%", pos: true }
        ],
        txTitle: "Gaji Utama (Arus Masuk)",
        txSub: "Transfer Masuk • Hari Ini",
        txAmount: "+Rp 8.500.000",
        txIsPositive: true,
        tx2Title: "Kopi Susu Pagi",
        tx2Sub: "Pos Keinginan • 08:24",
        tx2Amount: "-Rp 34.000",
        tx2IsPositive: false,
        dockTab: "home",
        card2Label: "Kecepatan Aman Bulanan",
        card2Value: "62% Tersisa",
        card2Sub: "Momentum surplus stabil",
        chartLine: "M0,58 Q40,48 80,36 T160,26 T220,14",
        chartArea: "M0,58 Q40,48 80,36 T160,26 T220,14 L220,72 L0,72 Z",
        chartDotX: 165,
        chartDotY: 25,
        breakdown: [
          { label: "Pos Kebutuhan", val: "50%", scale: 0.5 },
          { label: "Pos Keinginan", val: "30%", scale: 0.3 },
          { label: "Cadangan Tabungan", val: "20%", scale: 0.2 }
        ],
        mascotAvatar: "images/chibi/chibi_01.png"
      },
      pools: {
        cardLabel: "Alokasi Pos Bulanan",
        amount: "Rp 8.500.000",
        amountSub: "Kebutuhan (50%) · Keinginan (30%) · Tabungan (20%)",
        badgeText: "Otomatis",
        badgeClass: "badge-pools",
        meterScale: 0.5,
        meterGradient: "linear-gradient(90deg, var(--sunset-magenta) 50%, var(--neon-cyan) 80%, var(--emerald) 100%)",
        stats: [
          { label: "Kebutuhan", val: "Rp 4,25jt", pos: false },
          { label: "Keinginan", val: "Rp 2,55jt", pos: false },
          { label: "Tabungan", val: "Rp 1,70jt", pos: true }
        ],
        txTitle: "Setoran Dana Darurat",
        txSub: "Pos Tabungan (20%) • Otomatis",
        txAmount: "+Rp 1.700.000",
        txIsPositive: true,
        tx2Title: "Internet & Utilitas Bulanan",
        tx2Sub: "Pos Kebutuhan (50%) • Otomatis",
        tx2Amount: "-Rp 420.000",
        tx2IsPositive: false,
        dockTab: "budget",
        card2Label: "Pemakaian Pos Kebutuhan",
        card2Value: "62% Terpakai",
        card2Sub: "Belanja & tagihan terkendali",
        chartLine: "M0,54 Q55,44 105,34 T175,28 T220,20",
        chartArea: "M0,54 Q55,44 105,34 T175,28 T220,20 L220,72 L0,72 Z",
        chartDotX: 135,
        chartDotY: 31,
        breakdown: [
          { label: "Kebutuhan Terpakai", val: "62%", scale: 0.62 },
          { label: "Keinginan Terpakai", val: "41%", scale: 0.41 },
          { label: "Tabungan Terkunci", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_03.png"
      },
      rapid: {
        cardLabel: "Transaksi SQLite Instan",
        amount: "-Rp 28.000",
        amountSub: "Hitung Langsung: 18000 + 10000",
        badgeText: "0ms Tersimpan",
        badgeClass: "badge-fast",
        meterScale: 0.18,
        meterGradient: "linear-gradient(90deg, var(--sunset-orange), var(--sunset-magenta))",
        stats: [
          { label: "Tulis", val: "0.12 ms", pos: true },
          { label: "Brankas", val: "Struk", pos: false },
          { label: "Mode", val: "Offline", pos: false }
        ],
        txTitle: "Kopi & Roti Pagi",
        txSub: "Makan & Minum • Foto Struk",
        txAmount: "-Rp 28.000",
        txIsPositive: false,
        tx2Title: "Isi Ulang KRL Commuter",
        tx2Sub: "Transportasi • Kalkulator",
        tx2Amount: "-Rp 50.000",
        tx2IsPositive: false,
        dockTab: "tx",
        card2Label: "Kecepatan Tulis Lokal",
        card2Value: "0.12 ms",
        card2Sub: "Tanpa tunggu cloud • Terenkripsi",
        chartLine: "M0,48 Q45,52 95,40 T165,30 T220,18",
        chartArea: "M0,48 Q45,52 95,40 T165,30 T220,18 L220,72 L0,72 Z",
        chartDotX: 110,
        chartDotY: 38,
        breakdown: [
          { label: "Commit SQLite", val: "0.12ms", scale: 0.92 },
          { label: "AES Keystore", val: "Aktif", scale: 1.0 },
          { label: "Antrean Cloud", val: "0 Pending", scale: 0.12 }
        ],
        mascotAvatar: "images/chibi/chibi_04.png"
      },
      debt: {
        cardLabel: "Piutang & Tagihan Aktif",
        amount: "Rp 1.250.000",
        amountSub: "3 lunas · 1 jatuh tempo 4 hari lagi",
        badgeText: "Pengingat",
        badgeClass: "badge-due",
        meterScale: 0.75,
        meterGradient: "linear-gradient(90deg, var(--neon-cyan), var(--amber))",
        stats: [
          { label: "Lunas", val: "3 / 4", pos: true },
          { label: "Tempo", val: "4 Hari", pos: false },
          { label: "Piutang", val: "Rp 350rb", pos: true }
        ],
        txTitle: "Patungan Makan Malam (Sarah)",
        txSub: "Split Bill Kustom • Menunggu",
        txAmount: "+Rp 350.000",
        txIsPositive: true,
        tx2Title: "Cicilan Perangkat Kerja",
        tx2Sub: "Bayar Otomatis • Lunas",
        tx2Amount: "-Rp 450.000",
        tx2IsPositive: false,
        dockTab: "goals",
        card2Label: "Hitung Mundur Pelunasan",
        card2Value: "4 Hari Lagi",
        card2Sub: "Pengingat lokal aktif",
        chartLine: "M0,62 Q50,52 100,38 T170,22 T220,12",
        chartArea: "M0,62 Q50,52 100,38 T170,22 T220,12 L220,72 L0,72 Z",
        chartDotX: 195,
        chartDotY: 16,
        breakdown: [
          { label: "Patungan Sarah", val: "75%", scale: 0.75 },
          { label: "Patungan Alex", val: "100%", scale: 1.0 },
          { label: "Makan Tim", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_08.png"
      }
    }
  },
  USD: {
    en: {
      pulse: {
        cardLabel: "Active Safe Daily Quota",
        amount: "$42",
        amountSub: "/ day safe to spend",
        badgeText: "Safe Speed",
        badgeClass: "badge-safe",
        meterScale: 0.38,
        meterGradient: "linear-gradient(90deg, var(--emerald), var(--neon-cyan))",
        stats: [
          { label: "Remaining", val: "$1,250", pos: false },
          { label: "Cycle", val: "18 Days", pos: false },
          { label: "Buffer", val: "+14.2%", pos: true }
        ],
        txTitle: "Primary Salary (Cashflow In)",
        txSub: "Direct Deposit • Today",
        txAmount: "+$2,500",
        txIsPositive: true,
        tx2Title: "Morning Espresso & Oat",
        tx2Sub: "Wants Pool • 08:24",
        tx2Amount: "-$6",
        tx2IsPositive: false,
        dockTab: "home",
        card2Label: "Monthly Safe Velocity",
        card2Value: "62% Remaining",
        card2Sub: "Steady surplus momentum",
        chartLine: "M0,58 Q40,48 80,36 T160,26 T220,14",
        chartArea: "M0,58 Q40,48 80,36 T160,26 T220,14 L220,72 L0,72 Z",
        chartDotX: 165,
        chartDotY: 25,
        breakdown: [
          { label: "Needs Pool", val: "50%", scale: 0.5 },
          { label: "Wants Pool", val: "30%", scale: 0.3 },
          { label: "Savings Reserve", val: "20%", scale: 0.2 }
        ],
        mascotAvatar: "images/chibi/chibi_01.png"
      },
      pools: {
        cardLabel: "Monthly Pool Allocation",
        amount: "$2,500",
        amountSub: "Needs (50%) · Wants (30%) · Savings (20%)",
        badgeText: "Autonomous",
        badgeClass: "badge-pools",
        meterScale: 0.5,
        meterGradient: "linear-gradient(90deg, var(--sunset-magenta) 50%, var(--neon-cyan) 80%, var(--emerald) 100%)",
        stats: [
          { label: "Needs", val: "$1,250", pos: false },
          { label: "Wants", val: "$750", pos: false },
          { label: "Saved", val: "$500", pos: true }
        ],
        txTitle: "Emergency Reserve Deposit",
        txSub: "Savings Pool (20%) • Automatic",
        txAmount: "+$500",
        txIsPositive: true,
        tx2Title: "Monthly Fiber & Utilities",
        tx2Sub: "Needs Pool (50%) • Auto-Logged",
        tx2Amount: "-$115",
        tx2IsPositive: false,
        dockTab: "budget",
        card2Label: "Needs Pool Exhaustion",
        card2Value: "62% Spent",
        card2Sub: "Groceries & utilities on track",
        chartLine: "M0,54 Q55,44 105,34 T175,28 T220,20",
        chartArea: "M0,54 Q55,44 105,34 T175,28 T220,20 L220,72 L0,72 Z",
        chartDotX: 135,
        chartDotY: 31,
        breakdown: [
          { label: "Needs Utilized", val: "62%", scale: 0.62 },
          { label: "Wants Utilized", val: "41%", scale: 0.41 },
          { label: "Savings Locked", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_03.png"
      },
      rapid: {
        cardLabel: "Instant SQLite Transaction",
        amount: "-$12",
        amountSub: "Built-in Math: 7 + 5",
        badgeText: "0ms Written",
        badgeClass: "badge-fast",
        meterScale: 0.18,
        meterGradient: "linear-gradient(90deg, var(--sunset-orange), var(--sunset-magenta))",
        stats: [
          { label: "Write", val: "0.12 ms", pos: true },
          { label: "Vault", val: "Receipt", pos: false },
          { label: "Sync", val: "Offline", pos: false }
        ],
        txTitle: "Coffee & Pastry",
        txSub: "Food & Dining • Photo Receipt Vault",
        txAmount: "-$12",
        txIsPositive: false,
        tx2Title: "Metro Transit Pass",
        tx2Sub: "Transport • Inline Calc",
        tx2Amount: "-$25",
        tx2IsPositive: false,
        dockTab: "tx",
        card2Label: "Local Database Write Time",
        card2Value: "0.12 ms",
        card2Sub: "Zero cloud wait • Encrypted",
        chartLine: "M0,48 Q45,52 95,40 T165,30 T220,18",
        chartArea: "M0,48 Q45,52 95,40 T165,30 T220,18 L220,72 L0,72 Z",
        chartDotX: 110,
        chartDotY: 38,
        breakdown: [
          { label: "SQLite Commit", val: "0.12ms", scale: 0.92 },
          { label: "AES Keystore", val: "Active", scale: 1.0 },
          { label: "Cloud Queue", val: "0 Pending", scale: 0.12 }
        ],
        mascotAvatar: "images/chibi/chibi_04.png"
      },
      debt: {
        cardLabel: "Active Receivables & Debts",
        amount: "$320",
        amountSub: "3 settled · 1 pending due in 4 days",
        badgeText: "Due Alert",
        badgeClass: "badge-due",
        meterScale: 0.75,
        meterGradient: "linear-gradient(90deg, var(--neon-cyan), var(--amber))",
        stats: [
          { label: "Settled", val: "3 / 4", pos: true },
          { label: "Next Due", val: "4 Days", pos: false },
          { label: "Owed", val: "$85", pos: true }
        ],
        txTitle: "Dinner Party Split (Sarah)",
        txSub: "Custom Split Bill • Pending Due",
        txAmount: "+$85",
        txIsPositive: true,
        tx2Title: "Studio Gear Installment",
        tx2Sub: "Auto-Payoff • Settled",
        tx2Amount: "-$120",
        tx2IsPositive: false,
        dockTab: "goals",
        card2Label: "Payoff Countdown",
        card2Value: "4 Days Left",
        card2Sub: "Lock-screen due reminder set",
        chartLine: "M0,62 Q50,52 100,38 T170,22 T220,12",
        chartArea: "M0,62 Q50,52 100,38 T170,22 T220,12 L220,72 L0,72 Z",
        chartDotX: 195,
        chartDotY: 16,
        breakdown: [
          { label: "Sarah Split", val: "75%", scale: 0.75 },
          { label: "Alex Split", val: "100%", scale: 1.0 },
          { label: "Team Lunch", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_08.png"
      }
    },
    id: {
      pulse: {
        cardLabel: "Kuota Aman Harian Aktif",
        amount: "$42",
        amountSub: "/ hari aman dibelanjakan",
        badgeText: "Laju Aman",
        badgeClass: "badge-safe",
        meterScale: 0.38,
        meterGradient: "linear-gradient(90deg, var(--emerald), var(--neon-cyan))",
        stats: [
          { label: "Tersisa", val: "$1,250", pos: false },
          { label: "Siklus", val: "18 Hari", pos: false },
          { label: "Buffer", val: "+14,2%", pos: true }
        ],
        txTitle: "Gaji Utama (Arus Masuk)",
        txSub: "Transfer Masuk • Hari Ini",
        txAmount: "+$2,500",
        txIsPositive: true,
        tx2Title: "Kopi Susu Pagi",
        tx2Sub: "Pos Keinginan • 08:24",
        tx2Amount: "-$6",
        tx2IsPositive: false,
        dockTab: "home",
        card2Label: "Kecepatan Aman Bulanan",
        card2Value: "62% Tersisa",
        card2Sub: "Momentum surplus stabil",
        chartLine: "M0,58 Q40,48 80,36 T160,26 T220,14",
        chartArea: "M0,58 Q40,48 80,36 T160,26 T220,14 L220,72 L0,72 Z",
        chartDotX: 165,
        chartDotY: 25,
        breakdown: [
          { label: "Pos Kebutuhan", val: "50%", scale: 0.5 },
          { label: "Pos Keinginan", val: "30%", scale: 0.3 },
          { label: "Cadangan Tabungan", val: "20%", scale: 0.2 }
        ],
        mascotAvatar: "images/chibi/chibi_01.png"
      },
      pools: {
        cardLabel: "Alokasi Pos Bulanan",
        amount: "$2,500",
        amountSub: "Kebutuhan (50%) · Keinginan (30%) · Tabungan (20%)",
        badgeText: "Otomatis",
        badgeClass: "badge-pools",
        meterScale: 0.5,
        meterGradient: "linear-gradient(90deg, var(--sunset-magenta) 50%, var(--neon-cyan) 80%, var(--emerald) 100%)",
        stats: [
          { label: "Kebutuhan", val: "$1,250", pos: false },
          { label: "Keinginan", val: "$750", pos: false },
          { label: "Tabungan", val: "$500", pos: true }
        ],
        txTitle: "Setoran Dana Darurat",
        txSub: "Pos Tabungan (20%) • Otomatis",
        txAmount: "+$500",
        txIsPositive: true,
        tx2Title: "Internet & Utilitas Bulanan",
        tx2Sub: "Pos Kebutuhan (50%) • Otomatis",
        tx2Amount: "-$115",
        tx2IsPositive: false,
        dockTab: "budget",
        card2Label: "Pemakaian Pos Kebutuhan",
        card2Value: "62% Terpakai",
        card2Sub: "Belanja & tagihan terkendali",
        chartLine: "M0,54 Q55,44 105,34 T175,28 T220,20",
        chartArea: "M0,54 Q55,44 105,34 T175,28 T220,20 L220,72 L0,72 Z",
        chartDotX: 135,
        chartDotY: 31,
        breakdown: [
          { label: "Kebutuhan Terpakai", val: "62%", scale: 0.62 },
          { label: "Keinginan Terpakai", val: "41%", scale: 0.41 },
          { label: "Tabungan Terkunci", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_03.png"
      },
      rapid: {
        cardLabel: "Transaksi SQLite Instan",
        amount: "-$12",
        amountSub: "Hitung Langsung: 7 + 5",
        badgeText: "0ms Tersimpan",
        badgeClass: "badge-fast",
        meterScale: 0.18,
        meterGradient: "linear-gradient(90deg, var(--sunset-orange), var(--sunset-magenta))",
        stats: [
          { label: "Tulis", val: "0.12 ms", pos: true },
          { label: "Brankas", val: "Struk", pos: false },
          { label: "Mode", val: "Offline", pos: false }
        ],
        txTitle: "Kopi & Roti Pagi",
        txSub: "Makan & Minum • Foto Struk",
        txAmount: "-$12",
        txIsPositive: false,
        tx2Title: "Tiket Transportasi",
        tx2Sub: "Transportasi • Kalkulator",
        tx2Amount: "-$25",
        tx2IsPositive: false,
        dockTab: "tx",
        card2Label: "Kecepatan Tulis Lokal",
        card2Value: "0.12 ms",
        card2Sub: "Tanpa tunggu cloud • Terenkripsi",
        chartLine: "M0,48 Q45,52 95,40 T165,30 T220,18",
        chartArea: "M0,48 Q45,52 95,40 T165,30 T220,18 L220,72 L0,72 Z",
        chartDotX: 110,
        chartDotY: 38,
        breakdown: [
          { label: "Commit SQLite", val: "0.12ms", scale: 0.92 },
          { label: "AES Keystore", val: "Aktif", scale: 1.0 },
          { label: "Antrean Cloud", val: "0 Pending", scale: 0.12 }
        ],
        mascotAvatar: "images/chibi/chibi_04.png"
      },
      debt: {
        cardLabel: "Piutang & Tagihan Aktif",
        amount: "$320",
        amountSub: "3 lunas · 1 jatuh tempo 4 hari lagi",
        badgeText: "Pengingat",
        badgeClass: "badge-due",
        meterScale: 0.75,
        meterGradient: "linear-gradient(90deg, var(--neon-cyan), var(--amber))",
        stats: [
          { label: "Lunas", val: "3 / 4", pos: true },
          { label: "Tempo", val: "4 Hari", pos: false },
          { label: "Piutang", val: "$85", pos: true }
        ],
        txTitle: "Patungan Makan Malam (Sarah)",
        txSub: "Split Bill Kustom • Menunggu",
        txAmount: "+$85",
        txIsPositive: true,
        tx2Title: "Cicilan Perangkat Kerja",
        tx2Sub: "Bayar Otomatis • Lunas",
        tx2Amount: "-$120",
        tx2IsPositive: false,
        dockTab: "goals",
        card2Label: "Hitung Mundur Pelunasan",
        card2Value: "4 Hari Lagi",
        card2Sub: "Pengingat lokal aktif",
        chartLine: "M0,62 Q50,52 100,38 T170,22 T220,12",
        chartArea: "M0,62 Q50,52 100,38 T170,22 T220,12 L220,72 L0,72 Z",
        chartDotX: 195,
        chartDotY: 16,
        breakdown: [
          { label: "Patungan Sarah", val: "75%", scale: 0.75 },
          { label: "Patungan Alex", val: "100%", scale: 1.0 },
          { label: "Makan Tim", val: "100%", scale: 1.0 }
        ],
        mascotAvatar: "images/chibi/chibi_08.png"
      }
    }
  }
};

const CALIBRATOR_DATA = {
  IDR: [
    {
      tick: "3M",
      income: 3000000,
      daily: 50000,
      needs: 1500000,
      savings: 600000,
      hintEn: "Lean & intentional budget. Rp 50.000/day keeps daily expenses completely under control.",
      hintId: "Anggaran ramping & terukur. Rp 50.000/hari menjaga pengeluaran harian tetap terkendali."
    },
    {
      tick: "5M",
      income: 5000000,
      daily: 85000,
      needs: 2500000,
      savings: 1000000,
      hintEn: "Balanced entry tier. 50% shields living costs while building Rp 1.000.000 savings reserve every month.",
      hintId: "Tingkat pemula seimbang. 50% menjaga biaya hidup sambil membangun Rp 1.000.000 tabungan per bulan."
    },
    {
      tick: "8.5M",
      income: 8500000,
      daily: 145000,
      needs: 4250000,
      savings: 1700000,
      hintEn: "The signature Wall o' Pay sweet spot! Safe spending speed of Rp 145.000/day ensures zero month-end stress.",
      hintId: "Titik ideal khas Wall o' Pay! Batas aman Rp 145.000/hari memastikan akhir bulan tanpa stres."
    },
    {
      tick: "12.5M",
      income: 12500000,
      daily: 215000,
      needs: 6250000,
      savings: 2500000,
      hintEn: "Accelerated growth! Over Rp 2.500.000 flows directly into your emergency fortress each month.",
      hintId: "Pertumbuhan cepat! Lebih dari Rp 2.500.000 langsung mengalir ke dana darurat setiap bulan."
    },
    {
      tick: "18M",
      income: 18000000,
      daily: 310000,
      needs: 9000000,
      savings: 3600000,
      hintEn: "Sovereign freedom tier. Discretionary spending comfortably buffered without impacting long-term goals.",
      hintId: "Tingkat kebebasan finansial. Pengeluaran fleksibel tetap aman tanpa mengganggu target jangka panjang."
    },
    {
      tick: "25M",
      income: 25000000,
      daily: 430000,
      needs: 12500000,
      savings: 5000000,
      hintEn: "Maximum velocity! Rp 5.000.000 monthly passive wealth accumulation with full offline peace of mind.",
      hintId: "Kecepatan maksimal! Akumulasi Rp 5.000.000 per bulan dengan ketenangan penuh secara offline."
    }
  ],
  USD: [
    {
      tick: "$1K",
      income: 1000,
      daily: 16,
      needs: 500,
      savings: 200,
      hintEn: "Lean & intentional budget. $16/day keeps daily expenses completely under control.",
      hintId: "Anggaran ramping & terukur. $16/hari menjaga pengeluaran harian tetap terkendali."
    },
    {
      tick: "$1.8K",
      income: 1800,
      daily: 30,
      needs: 900,
      savings: 360,
      hintEn: "Balanced entry tier. 50% shields living costs while saving $360 every month.",
      hintId: "Tingkat pemula seimbang. 50% menjaga biaya hidup sambil menabung $360 setiap bulan."
    },
    {
      tick: "$2.5K",
      income: 2500,
      daily: 42,
      needs: 1250,
      savings: 500,
      hintEn: "Global sweet spot! A safe velocity of $42/day ensures zero month-end stress.",
      hintId: "Titik ideal global! Laju aman $42/hari memastikan akhir bulan bebas stres."
    },
    {
      tick: "$4K",
      income: 4000,
      daily: 66,
      needs: 2000,
      savings: 800,
      hintEn: "Accelerated growth! $800 flows directly into your emergency reserve every month.",
      hintId: "Pertumbuhan cepat! $800 langsung mengalir ke dana cadangan darurat setiap bulan."
    },
    {
      tick: "$6.5K",
      income: 6500,
      daily: 108,
      needs: 3250,
      savings: 1300,
      hintEn: "Sovereign freedom tier. Discretionary spending comfortably buffered without touching goals.",
      hintId: "Tingkat kebebasan finansial. Pengeluaran fleksibel aman tanpa mengganggu target."
    },
    {
      tick: "$10K",
      income: 10000,
      daily: 165,
      needs: 5000,
      savings: 2000,
      hintEn: "Maximum velocity! $2,000 monthly wealth accumulation with 100% offline privacy.",
      hintId: "Kecepatan maksimal! Akumulasi $2,000 per bulan dengan privasi offline penuh."
    }
  ]
};

function formatCurrencyAmount(val, currency) {
  if (currency === "USD") {
    return "$" + val.toLocaleString("en-US");
  }
  return "Rp " + val.toLocaleString("id-ID");
}

function setButtonLabel(button, text) {
  if (!button) return;
  const labelSpan = button.querySelector("span:not(.btn-shimmer)");
  if (labelSpan) {
    labelSpan.textContent = text;
  }
}

function parseSemVer(v) {
  if (!v) return [0, 0, 0];
  const clean = v.toString().replace(/^v/i, "").split("-")[0];
  return clean.split(".").map(n => parseInt(n, 10) || 0);
}

function isVersionGreater(v1, v2) {
  const p1 = parseSemVer(v1);
  const p2 = parseSemVer(v2);
  for (let i = 0; i < Math.max(p1.length, p2.length); i++) {
    const num1 = p1[i] || 0;
    const num2 = p2[i] || 0;
    if (num1 > num2) return true;
    if (num1 < num2) return false;
  }
  return false;
}

let resolvedRemoteTag = null;

function syncDownloadLabels() {
  const verText = resolvedRemoteTag || `v${APP_VERSION}`;
  const labelWord = activeLang === "id" ? "Unduh APK" : "Download APK";

  document.querySelectorAll(".app-version-tag").forEach(el => {
    el.textContent = verText;
  });

  const heroDownloadBtn = document.getElementById("hero-download-btn");
  if (heroDownloadBtn) {
    setButtonLabel(heroDownloadBtn, `${labelWord} (${verText})`);
  }

  const ctaDownloadBtn = document.getElementById("cta-download-btn");
  if (ctaDownloadBtn) {
    setButtonLabel(ctaDownloadBtn, `${labelWord} (${verText})`);
  }
}

function fetchLatestReleaseVersion() {
  const directApkUrl = `https://github.com/${REPO_NAME}/releases/latest/download/Wall_o_Pay.apk`;
  syncDownloadLabels();

  fetch(`https://api.github.com/repos/${REPO_NAME}/releases/latest`)
    .then(res => {
      if (!res.ok) throw new Error("GitHub API offline or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        if (isVersionGreater(tag, APP_VERSION)) {
          resolvedRemoteTag = tag.startsWith("v") ? tag : `v${tag}`;
        }
        syncDownloadLabels();

        const apkAsset =
          data.assets?.find(a => a.name === "Wall_o_Pay.apk") ||
          data.assets?.find(a => a.name.endsWith("_arm64-v8a.apk")) ||
          data.assets?.find(a => a.name.endsWith(".apk"));
        const downloadUrl = apkAsset ? apkAsset.browser_download_url : directApkUrl;
        document.querySelectorAll(".apk-download-btn").forEach(link => {
          link.href = downloadUrl;
        });
      }
    })
    .catch(() => {
      document.querySelectorAll(".apk-download-btn").forEach(link => {
        link.href = directApkUrl;
      });
    });
}

function updateMockupGreeting() {
  const now = new Date();
  const timeString = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;

  const timeEl = document.getElementById("phone-time-display");
  if (timeEl) timeEl.textContent = timeString;

  const timeBEl = document.getElementById("phone-b-time-display");
  if (timeBEl) timeBEl.textContent = timeString;

  const greetEl = document.getElementById("phone-greet-display");
  if (greetEl) {
    const hour = now.getHours();
    if (activeLang === "id") {
      if (hour >= 5 && hour < 11) greetEl.textContent = "Selamat pagi,";
      else if (hour >= 11 && hour < 15) greetEl.textContent = "Selamat siang,";
      else if (hour >= 15 && hour < 18) greetEl.textContent = "Selamat sore,";
      else greetEl.textContent = "Selamat malam,";
    } else {
      if (hour < 12) greetEl.textContent = "Good morning,";
      else if (hour < 17) greetEl.textContent = "Good afternoon,";
      else greetEl.textContent = "Good evening,";
    }
  }
}

function triggerMorph(el, className = "phone-morph-in") {
  if (!el) return;
  el.classList.remove(className);
  void el.offsetWidth;
  el.classList.add(className);
}

function renderPhoneMockups(animate = false) {
  const langSet = MODE_DATA[activeCurrency]?.[activeLang] || MODE_DATA.IDR.en;
  const data = langSet[activeMode];
  if (!data) return;

  const labelEl = document.getElementById("mockup-card-label");
  if (labelEl) labelEl.textContent = data.cardLabel;

  const amtEl = document.getElementById("mockup-amount-val");
  if (amtEl) amtEl.textContent = data.amount;

  const subEl = document.getElementById("mockup-amount-sub");
  if (subEl) subEl.textContent = data.amountSub;

  const badgeEl = document.getElementById("mockup-mode-badge");
  if (badgeEl) {
    badgeEl.textContent = data.badgeText;
    badgeEl.className = `mock-safe-badge ${data.badgeClass}`;
  }

  const meterFill = document.getElementById("mockup-meter-fill");
  if (meterFill) {
    meterFill.style.transform = `scaleX(${data.meterScale})`;
    meterFill.style.background = data.meterGradient;
  }

  data.stats.forEach((st, idx) => {
    const sLabel = document.getElementById(`mockup-stat${idx + 1}-label`);
    const sVal = document.getElementById(`mockup-stat${idx + 1}-val`);
    if (sLabel) sLabel.textContent = st.label;
    if (sVal) {
      sVal.textContent = st.val;
      sVal.className = `mini-stat-val${st.pos ? " pos" : ""}`;
    }
  });

  const txTitleEl = document.getElementById("mockup-tx-title");
  if (txTitleEl) txTitleEl.textContent = data.txTitle;

  const txSubEl = document.getElementById("mockup-tx-sub");
  if (txSubEl) txSubEl.textContent = data.txSub;

  const txValEl = document.getElementById("mockup-tx-val");
  if (txValEl) {
    txValEl.textContent = data.txAmount;
    txValEl.className = `tx-val ${data.txIsPositive ? "pos" : "neg"}`;
  }

  const tx2TitleEl = document.getElementById("mockup-tx2-title");
  if (tx2TitleEl) tx2TitleEl.textContent = data.tx2Title;

  const tx2SubEl = document.getElementById("mockup-tx2-sub");
  if (tx2SubEl) tx2SubEl.textContent = data.tx2Sub;

  const tx2ValEl = document.getElementById("mockup-tx2-val");
  if (tx2ValEl) {
    tx2ValEl.textContent = data.tx2Amount;
    tx2ValEl.className = `tx-val ${data.tx2IsPositive ? "pos" : "neg"}`;
  }

  document.querySelectorAll("#mockup-bottom-dock .dock-item").forEach(item => {
    item.classList.toggle("active", item.getAttribute("data-dock") === data.dockTab);
  });

  const avatarImg = document.getElementById("phone-avatar-img");
  if (avatarImg && data.mascotAvatar) {
    avatarImg.src = data.mascotAvatar;
    if (animate) {
      avatarImg.classList.remove("pop");
      void avatarImg.offsetWidth;
      avatarImg.classList.add("pop");
      setTimeout(() => avatarImg.classList.remove("pop"), 260);
    }
  }

  const card2Label = document.getElementById("mockup-b-label");
  if (card2Label) card2Label.textContent = data.card2Label;

  const card2Val = document.getElementById("mockup-b-value");
  if (card2Val) card2Val.textContent = data.card2Value;

  const card2Sub = document.getElementById("mockup-b-sub");
  if (card2Sub) card2Sub.textContent = data.card2Sub;

  const chartLine = document.getElementById("mockup-chart-line");
  if (chartLine) chartLine.setAttribute("d", data.chartLine);

  const chartArea = document.getElementById("mockup-chart-area");
  if (chartArea) chartArea.setAttribute("d", data.chartArea);

  const chartDot = document.getElementById("mockup-chart-dot");
  if (chartDot) {
    chartDot.setAttribute("cx", data.chartDotX);
    chartDot.setAttribute("cy", data.chartDotY);
  }

  const chartHalo = document.getElementById("mockup-chart-halo");
  if (chartHalo) {
    chartHalo.setAttribute("cx", data.chartDotX);
    chartHalo.setAttribute("cy", data.chartDotY);
  }

  data.breakdown.forEach((bd, idx) => {
    const bLabel = document.getElementById(`mockup-bd${idx + 1}-label`);
    const bVal = document.getElementById(`mockup-bd${idx + 1}-val`);
    const bBar = document.getElementById(`mockup-bd${idx + 1}-bar`);
    if (bLabel) bLabel.textContent = bd.label;
    if (bVal) bVal.textContent = bd.val;
    if (bBar) bBar.style.transform = `scaleX(${bd.scale})`;
  });

  if (animate) {
    triggerMorph(document.getElementById("mockup-phone-a-card"));
    triggerMorph(document.getElementById("mockup-tx-list"));
    triggerMorph(document.getElementById("mockup-phone-b-card"));
    triggerMorph(document.getElementById("mockup-breakdown-card"));
  }
}

function renderWidgetsCurrency() {
  const dialVal = document.getElementById("widget-dial-val");
  const dialSub = document.getElementById("widget-dial-sub");
  const log1 = document.getElementById("widget-log-val-1");
  const log2 = document.getElementById("widget-log-val-2");

  if (dialSub) {
    dialSub.textContent = activeLang === "id" ? "AMAN HARI INI" : "SAFE TODAY";
  }

  if (activeCurrency === "USD") {
    if (dialVal) dialVal.textContent = "$42";
    if (log1) log1.textContent = "-$6";
    if (log2) log2.textContent = "-$48";
  } else {
    if (dialVal) dialVal.textContent = activeLang === "id" ? "Rp 145rb" : "Rp 145K";
    if (log1) log1.textContent = "-Rp 28.000";
    if (log2) log2.textContent = "-Rp 185.000";
  }
}

function renderCalibrator(idx, animate = false) {
  activeCalibratorStep = idx;
  const tiers = CALIBRATOR_DATA[activeCurrency] || CALIBRATOR_DATA.IDR;
  const tier = tiers[idx];
  if (!tier) return;

  const slider = document.getElementById("income-scrubber-range");
  const readout = document.getElementById("calibrator-income-readout");
  const dailyQuotaEl = document.getElementById("calibrator-daily-quota");
  const needsEl = document.getElementById("calibrator-needs-amount");
  const savingsEl = document.getElementById("calibrator-savings-amount");
  const hintEl = document.getElementById("calibrator-hint-text");
  const ticks = document.querySelectorAll(".scrubber-ticks-row .tick");

  if (slider) slider.value = idx;

  const moSuffix = activeLang === "id" ? "/ bln" : "/ mo";
  const daySuffix = activeLang === "id" ? "/ hari aman" : "/ day safe";

  if (readout) {
    readout.textContent = `${formatCurrencyAmount(tier.income, activeCurrency)} ${moSuffix}`;
  }
  if (dailyQuotaEl) {
    dailyQuotaEl.innerHTML = `${formatCurrencyAmount(tier.daily, activeCurrency)} <small>${daySuffix}</small>`;
  }
  if (needsEl) {
    needsEl.textContent = formatCurrencyAmount(tier.needs, activeCurrency);
  }
  if (savingsEl) {
    savingsEl.textContent = formatCurrencyAmount(tier.savings, activeCurrency);
  }
  if (hintEl) {
    hintEl.textContent = activeLang === "id" ? tier.hintId : tier.hintEn;
  }

  ticks.forEach((t, i) => {
    if (tiers[i]) t.textContent = tiers[i].tick;
    const stepVal = parseInt(t.getAttribute("data-step"), 10);
    t.classList.toggle("active", stepVal === idx);
  });

  if (animate) {
    triggerMorph(dailyQuotaEl, "calibrator-morph-in");
    triggerMorph(needsEl, "calibrator-morph-in");
    triggerMorph(savingsEl, "calibrator-morph-in");
  }
}

function applyLanguage(lang, persist = true) {
  activeLang = lang === "id" ? "id" : "en";
  document.documentElement.lang = activeLang;

  if (persist) {
    try {
      localStorage.setItem("wop_lang", activeLang);
    } catch (_) {}
  }

  const dict = I18N[activeLang];
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    if (dict[key] !== undefined) {
      el.textContent = dict[key];
    }
  });
  document.querySelectorAll("[data-i18n-html]").forEach(el => {
    const key = el.getAttribute("data-i18n-html");
    if (dict[key] !== undefined) {
      el.innerHTML = dict[key];
    }
  });

  document.querySelectorAll(".lang-btn").forEach(btn => {
    const isMatch = btn.getAttribute("data-lang") === activeLang;
    btn.classList.toggle("active", isMatch);
    btn.setAttribute("aria-pressed", isMatch ? "true" : "false");
  });

  syncDownloadLabels();
  updateMockupGreeting();
  renderPhoneMockups(false);
  renderWidgetsCurrency();
  renderCalibrator(activeCalibratorStep, false);
}

function applyCurrency(currency, animate = true) {
  activeCurrency = currency === "USD" ? "USD" : "IDR";
  document.querySelectorAll(".currency-btn").forEach(btn => {
    const isMatch = btn.getAttribute("data-currency") === activeCurrency;
    btn.classList.toggle("active", isMatch);
    btn.setAttribute("aria-pressed", isMatch ? "true" : "false");
  });

  renderPhoneMockups(animate);
  renderWidgetsCurrency();
  renderCalibrator(activeCalibratorStep, animate);
}

function setupLanguageSwitcher() {
  let savedLang = "en";
  try {
    const stored = localStorage.getItem("wop_lang");
    if (stored === "id" || stored === "en") savedLang = stored;
  } catch (_) {}

  document.querySelectorAll(".lang-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const nextLang = btn.getAttribute("data-lang");
      if (nextLang !== activeLang) {
        applyLanguage(nextLang, true);
      }
    });
  });

  applyLanguage(savedLang, false);
}

function setupCurrencySwitcher() {
  document.querySelectorAll(".currency-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const nextCur = btn.getAttribute("data-currency");
      if (nextCur !== activeCurrency) {
        applyCurrency(nextCur, true);
      }
    });
  });
}

function setupCashflowSwitcher() {
  const pills = document.querySelectorAll(".route-pill");
  if (!pills.length) return;

  pills.forEach(pill => {
    pill.addEventListener("click", () => {
      const modeKey = pill.getAttribute("data-mode");
      if (!modeKey) return;
      activeMode = modeKey;

      pills.forEach(p => {
        p.classList.remove("active");
        p.setAttribute("aria-selected", "false");
      });
      pill.classList.add("active");
      pill.setAttribute("aria-selected", "true");

      renderPhoneMockups(true);
    });
  });
}

function setupPulseCalibrator() {
  const slider = document.getElementById("income-scrubber-range");
  if (!slider) return;

  const ticks = document.querySelectorAll(".scrubber-ticks-row .tick");

  slider.addEventListener("input", e => {
    renderCalibrator(parseInt(e.target.value, 10), true);
  });

  ticks.forEach(t => {
    t.addEventListener("click", () => {
      renderCalibrator(parseInt(t.getAttribute("data-step"), 10), true);
    });
  });

  renderCalibrator(2, false);
}

function setupActiveNav() {
  const sections = document.querySelectorAll("header[id], section[id]");
  const navLinks = document.querySelectorAll(".nav-list a");
  const header = document.getElementById("site-header");

  const onScroll = () => {
    if (header) {
      header.classList.toggle("scrolled", window.scrollY > 20);
    }

    let current = "home";
    sections.forEach(section => {
      const sectionTop = section.offsetTop - 140;
      if (window.scrollY >= sectionTop) {
        current = section.getAttribute("id");
      }
    });

    navLinks.forEach(link => {
      link.classList.toggle("on", link.getAttribute("href") === `#${current}`);
    });
  };

  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
}

function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const navList = document.querySelector(".nav-list");
  if (!toggle || !navList) return;

  const closeNav = () => {
    navList.classList.remove("active");
    toggle.setAttribute("aria-expanded", "false");
  };

  const openNav = () => {
    navList.classList.add("active");
    toggle.setAttribute("aria-expanded", "true");
  };

  toggle.addEventListener("click", () => {
    const isOpen = navList.classList.contains("active");
    if (isOpen) {
      closeNav();
    } else {
      openNav();
    }
  });

  navList.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", closeNav);
  });

  document.addEventListener("keydown", e => {
    if (e.key === "Escape" && navList.classList.contains("active")) {
      closeNav();
      toggle.focus();
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  setupLanguageSwitcher();
  setupCurrencySwitcher();
  fetchLatestReleaseVersion();
  setupCashflowSwitcher();
  setupPulseCalibrator();
  setupActiveNav();
  setupMobileNav();
});
