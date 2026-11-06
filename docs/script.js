/**
 * Wall o' Pay - Landing Page Interactive Logic (Full English)
 */

const APP_VERSION = "2.0.0";

// Helper to compare semver strings (e.g. "1.11.32" vs "v1.11.21")
function isVersionGreater(v1, v2) {
  const clean = v => v.replace(/^v/, "").split(".").map(n => parseInt(n, 10) || 0);
  const a = clean(v1);
  const b = clean(v2);
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const numA = a[i] || 0;
    const numB = b[i] || 0;
    if (numA > numB) return true;
    if (numA < numB) return false;
  }
  return false;
}

// Showcase Tabs Data (Full English)
const showcaseData = {
  beranda: {
    title: "Instant Financial Dashboard",
    desc: "View your total balance, monthly inflows and outflows, recent activities, and daily budget pulse in one clean 3-block interface.",
    bullets: [
      "Gradient balance card with net cashflow summary",
      "Real-time Daily Budget Pulse showing safe-to-spend allowance",
      "Recent activity feed pulled directly from local SQLite with zero lag"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>🏠</span> Instant Financial Health</span>
          <span class="preview-box-badge">Live Dashboard</span>
        </div>
        <div class="screen-balance-card" style="margin-bottom: 0;">
          <div class="balance-card-title">Total Net Balance</div>
          <div class="balance-card-amount">Rp 12.850.000</div>
          <div class="balance-card-stats">
            <div class="stat-pill">Inflow<span style="color: #6EE7B7;">+Rp 8.500.000</span></div>
            <div class="stat-pill">Outflow<span style="color: #FCA5A5;">-Rp 3.150.000</span></div>
          </div>
        </div>
        <div class="preview-row-item">
          <div class="preview-item-left">
            <span class="preview-item-icon">⚡</span>
            <div>
              <div class="preview-item-name">Daily Budget Pulse</div>
              <div class="preview-item-cat">Safe to Spend</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--income);">Rp 145.000 / day</div>
        </div>
      </div>
    `
  },
  transaksi: {
    title: "Rapid 5-Second Transaction Logging",
    desc: "Record every expense with rich metadata. Attach custom categories, custom dates, memos, mini calculator arithmetic, transfer admin fees, and receipt photos with ease.",
    bullets: [
      "Dynamic categories with custom badges and icons",
      "Transfer Admin Fee tracking & built-in math calculation",
      "Real-time search query filtering and date range filters"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>📝</span> Fast Cashflow Records</span>
          <span class="preview-box-badge">5-Second Input</span>
        </div>
        <div class="preview-chip-group">
          <span class="preview-filter-chip">All</span>
          <span class="preview-filter-chip active">Expenses</span>
          <span class="preview-filter-chip">Incomes</span>
          <span class="preview-filter-chip">Transfers</span>
        </div>
        <div class="preview-row-item">
          <div class="preview-item-left">
            <span class="preview-item-icon">🛒</span>
            <div>
              <div class="preview-item-name">Supermarket Groceries</div>
              <div class="preview-item-cat">Needs • Receipt Attached 📸</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--expense);">-Rp 250.000</div>
        </div>
        <div class="preview-row-item">
          <div class="preview-item-left">
            <span class="preview-item-icon">💳</span>
            <div>
              <div class="preview-item-name">BCA ➔ ShopeePay</div>
              <div class="preview-item-cat">Transfer • Admin Fee: Rp 1.000</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--primary);">Rp 100.000</div>
        </div>
      </div>
    `
  },
  anggaran: {
    title: "Category Monthly Budgets & 50/30/20",
    desc: "Set spending caps for groceries, transport, or lifestyle expenses. Visual progress bars notify you as you approach designated limits with rollover support.",
    bullets: [
      "Adaptive color progress bars (Green ➔ Amber ➔ Red)",
      "Automatic calculation of daily remaining allowance",
      "50/30/20 Needs, Wants, and Savings budget pools"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>📊</span> Monthly Budget Allocations</span>
          <span class="preview-box-badge">50 / 30 / 20</span>
        </div>
        <div class="preview-progress-block">
          <div class="preview-progress-label">
            <span class="preview-item-name">🍲 Food & Dining</span>
            <span class="preview-item-cat">Rp 1.450.000 / Rp 2.000.000 (72%)</span>
          </div>
          <div class="preview-track-bg">
            <div class="preview-track-fill" style="width: 72%; background: var(--income);"></div>
          </div>
        </div>
        <div class="preview-progress-block">
          <div class="preview-progress-label">
            <span class="preview-item-name">🚗 Transportation</span>
            <span class="preview-item-cat" style="color: #F59E0B;">Rp 480.000 / Rp 500.000 (96%)</span>
          </div>
          <div class="preview-track-bg">
            <div class="preview-track-fill" style="width: 96%; background: #F59E0B;"></div>
          </div>
        </div>
        <div class="preview-progress-block">
          <div class="preview-progress-label">
            <span class="preview-item-name">☕ Coffee & Hangout</span>
            <span class="preview-item-cat">Rp 120.000 / Rp 400.000 (30%)</span>
          </div>
          <div class="preview-track-bg">
            <div class="preview-track-fill" style="width: 30%; background: var(--primary);"></div>
          </div>
        </div>
      </div>
    `
  },
  tabungan: {
    title: "Dedicated Savings Goals & Debts",
    desc: "Bring your financial dreams to life step-by-step. Set emergency funds or new device milestones, and manage debts or split bills with friends seamlessly.",
    bullets: [
      "Motivating percentage progress trackers linked to real accounts",
      "Debts & Split Bills tracking with automated due date alerts",
      "Estimated completion date predictions based on deposits"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>🎯</span> Savings Goals & Debts</span>
          <span class="preview-box-badge">Milestones</span>
        </div>
        <div class="preview-progress-block">
          <div class="preview-progress-label">
            <span class="preview-item-name">🛡️ Emergency Stash</span>
            <span class="preview-item-cat" style="color: var(--income);">Rp 15.000.000 / Rp 20.000.000 (75%)</span>
          </div>
          <div class="preview-track-bg">
            <div class="preview-track-fill" style="width: 75%; background: var(--income);"></div>
          </div>
        </div>
        <div class="preview-row-item">
          <div class="preview-item-left">
            <span class="preview-item-icon">🤝</span>
            <div>
              <div class="preview-item-name">Split Bill - Lunch with Sarah</div>
              <div class="preview-item-cat">Sarah owes you • Due tomorrow</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--income);">+Rp 65.000</div>
        </div>
      </div>
    `
  },
  tema: {
    title: "Dual Aesthetics: Botanical & Pure Cyberpunk",
    desc: "Transform the app's visual atmosphere instantly. Switch between serene Botanical Forest (Lush Emerald & Sage) and electric Pure Cyberpunk (Night City Obsidian, Electric Cyan & Edgerunner Yellow).",
    bullets: [
      "Signature Botanical Forest: Calming night pine, emerald curves & soothing sage",
      "Pure Cyberpunk: High-contrast Electric Cyan, Matrix Mint, Laser Pink & Edgerunner Yellow",
      "Dynamic typography with Google Fonts Rajdhani and custom glowing vector accents"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>🎨</span> Dual Visual Identity</span>
          <span class="preview-box-badge">v2.0 Exclusive</span>
        </div>
        <div class="preview-chip-group" style="margin-bottom: 0.75rem;">
          <span class="preview-filter-chip" id="demo-chip-botanical" style="cursor: pointer;">🌿 Botanical Forest</span>
          <span class="preview-filter-chip" id="demo-chip-cyberpunk" style="cursor: pointer;">⚡ Pure Cyberpunk</span>
        </div>
        <div class="screen-balance-card" style="margin-bottom: 0.75rem;">
          <div class="balance-card-title">Active Aesthetic Engine</div>
          <div class="balance-card-amount">Instant Transformation</div>
          <div class="balance-card-stats">
            <div class="stat-pill">Botanical<span style="color: #6EE7B7;">Forest Emerald</span></div>
            <div class="stat-pill">Cyberpunk<span style="color: #00F0FF;">Neon Cyan</span></div>
          </div>
        </div>
        <div class="preview-row-item">
          <div class="preview-item-left">
            <span class="preview-item-icon">💡</span>
            <div>
              <div class="preview-item-name">Click chips above to toggle page theme live!</div>
              <div class="preview-item-cat">Experience the landing page in either aesthetic</div>
            </div>
          </div>
        </div>
      </div>
    `
  },
  keamanan: {
    title: "Universal Biometrics & Hardware Keystore",
    desc: "Your financial privacy is fortified with hardware-backed encryption. Unlock instantaneously using your device's Fingerprint scanner or Face Recognition, backed by key-stretched PBKDF2 HMAC-SHA256.",
    bullets: [
      "Universal Biometric Unlock (Fingerprint & Face Recognition) via local_auth",
      "Hardware-backed secret storage via Android Keystore & iOS Keychain",
      "2,048-iteration salted HMAC-SHA256 PIN hashing with persistent brute-force lockout"
    ],
    previewHtml: `
      <div class="preview-box">
        <div class="preview-box-header">
          <span class="preview-box-title"><span>🛡️</span> Hardware Security Vault</span>
          <span class="preview-box-badge">Encrypted</span>
        </div>
        <div class="preview-row-item" style="border-left: 3px solid var(--primary); padding-left: 0.75rem; margin-bottom: 0.5rem;">
          <div class="preview-item-left">
            <span class="preview-item-icon">👆</span>
            <div>
              <div class="preview-item-name">Biometric Quick Trigger</div>
              <div class="preview-item-cat">Fingerprint & Face ID Enabled</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--income);">Active ✓</div>
        </div>
        <div class="preview-row-item" style="border-left: 3px solid var(--accent); padding-left: 0.75rem; margin-bottom: 0.5rem;">
          <div class="preview-item-left">
            <span class="preview-item-icon">🔐</span>
            <div>
              <div class="preview-item-name">Encrypted Keystore Storage</div>
              <div class="preview-item-cat">FlutterSecureStorage (Hardware-Backed)</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--primary);">Secured</div>
        </div>
        <div class="preview-row-item" style="border-left: 3px solid var(--warning); padding-left: 0.75rem;">
          <div class="preview-item-left">
            <span class="preview-item-icon">⏳</span>
            <div>
              <div class="preview-item-name">Anti Brute-Force Lockout</div>
              <div class="preview-item-cat">Exponential 30s ➔ 120s ➔ 300s Backoff</div>
            </div>
          </div>
          <div class="preview-item-amount" style="color: var(--warning);">Protected</div>
        </div>
      </div>
    `
  }
};

// Theme Switcher Logic
const THEME_STORAGE_KEY = "wall_o_pay_landing_theme";

function applyTheme(theme) {
  const isCyber = theme === "cyberpunk";
  const themeName = isCyber ? "cyberpunk" : "botanical";
  document.documentElement.setAttribute("data-theme", themeName);
  try {
    localStorage.setItem(THEME_STORAGE_KEY, themeName);
  } catch (_) {}

  // Update navbar theme toggle button
  const toggleText = document.getElementById("theme-toggle-text");
  const toggleAction = document.getElementById("theme-toggle-action");
  const brandLogo = document.getElementById("brand-logo-img");
  const footerLogo = document.getElementById("footer-logo-img");
  const compThemeIcon = document.getElementById("comp-theme-icon");

  if (toggleText) {
    toggleText.textContent = isCyber ? "Pure Cyberpunk" : "Botanical Forest";
  }
  if (toggleAction) {
    toggleAction.textContent = isCyber ? "Switch 🌿" : "Switch ⚡";
  }
  if (compThemeIcon) {
    compThemeIcon.textContent = isCyber ? "⚡" : "🌿";
  }
  if (brandLogo) {
    brandLogo.src = isCyber ? "images/logo_cyberpunk.png" : "images/logo.png";
  }
  if (footerLogo) {
    footerLogo.src = isCyber ? "images/logo_cyberpunk.png" : "images/logo.png";
  }

  // Update showcase demo chips if present
  const chipBotanical = document.getElementById("demo-chip-botanical");
  const chipCyberpunk = document.getElementById("demo-chip-cyberpunk");
  if (chipBotanical && chipCyberpunk) {
    if (isCyber) {
      chipBotanical.classList.remove("active");
      chipCyberpunk.classList.add("active");
    } else {
      chipCyberpunk.classList.remove("active");
      chipBotanical.classList.add("active");
    }
  }
}

function setupThemeToggle() {
  let savedTheme = "botanical";
  try {
    savedTheme = localStorage.getItem(THEME_STORAGE_KEY) || "botanical";
  } catch (_) {}
  applyTheme(savedTheme);

  const toggleBtn = document.getElementById("theme-toggle-btn");
  if (toggleBtn) {
    toggleBtn.addEventListener("click", () => {
      const current = document.documentElement.getAttribute("data-theme");
      const next = current === "cyberpunk" ? "botanical" : "cyberpunk";
      applyTheme(next);
    });
  }
}

function setupShowcaseTabs() {
  const tabs = document.querySelectorAll(".showcase-tab-btn");
  const visual = document.getElementById("showcase-visual");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      const key = tab.getAttribute("data-tab");
      const data = showcaseData[key];
      if (data) {
        document.getElementById("showcase-title").textContent = data.title;
        document.getElementById("showcase-desc").textContent = data.desc;
        
        const list = document.getElementById("showcase-bullets");
        list.innerHTML = "";
        data.bullets.forEach(b => {
          const li = document.createElement("li");
          li.innerHTML = '<span class="check-icon">✓</span> ' + b;
          list.appendChild(li);
        });

        if (visual && data.previewHtml) {
          visual.innerHTML = data.previewHtml;
        }

        // Attach interactive chip handlers for 'tema' tab
        if (key === "tema") {
          const chipBot = document.getElementById("demo-chip-botanical");
          const chipCyber = document.getElementById("demo-chip-cyberpunk");
          const current = document.documentElement.getAttribute("data-theme");
          if (chipBot && chipCyber) {
            if (current === "cyberpunk") {
              chipCyber.classList.add("active");
            } else {
              chipBot.classList.add("active");
            }
            chipBot.addEventListener("click", () => applyTheme("botanical"));
            chipCyber.addEventListener("click", () => applyTheme("cyberpunk"));
          }
        }
      }
    });
  });
}

// Mobile Nav Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const nav = document.getElementById("nav-links");
  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      nav.classList.toggle("active");
    });
    nav.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", () => {
        nav.classList.remove("active");
      });
    });
  }
}

// Fetch latest release tag from GitHub API without downgrading local build version
function fetchLatestReleaseVersion() {
  // Apply local version as baseline
  document.querySelectorAll(".app-version-tag").forEach(el => {
    el.textContent = `v${APP_VERSION}`;
  });
  const heroDownloadText = document.getElementById("hero-download-text");
  if (heroDownloadText) {
    heroDownloadText.textContent = `Download APK (v${APP_VERSION})`;
  }
  const specsVersion = document.getElementById("specs-version-val");
  if (specsVersion) {
    specsVersion.textContent = `v${APP_VERSION} (Release)`;
  }

  fetch("https://api.github.com/repos/hyenavia/wall-o-pay/releases/latest")
    .then(res => {
      if (!res.ok) throw new Error("GitHub API unavailable or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        // Only update if GitHub tag is strictly newer than current local version
        if (isVersionGreater(tag, APP_VERSION)) {
          document.querySelectorAll(".app-version-tag").forEach(el => {
            el.textContent = tag;
          });
          if (heroDownloadText) {
            heroDownloadText.textContent = `Download APK (${tag})`;
          }
          if (specsVersion) {
            specsVersion.textContent = `${tag} (Release)`;
          }
        }
      }
    })
    .catch(() => {
      // Graceful fallback to local APP_VERSION
    });
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  setupThemeToggle();
  setupShowcaseTabs();
  setupMobileNav();
  fetchLatestReleaseVersion();
});
