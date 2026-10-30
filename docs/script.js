/**
 * Wall o' Pay - Landing Page Interactive Logic (Full English)
 */

const APP_VERSION = "1.8.4";

// Theme Switcher
function toggleTheme() {
  const current = document.documentElement.getAttribute("data-theme");
  const next = current === "dark" ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", next);
  
  const themeBtn = document.getElementById("theme-btn");
  if (themeBtn) {
    themeBtn.textContent = next === "dark" ? "☀️" : "🌙";
  }
  localStorage.setItem("wall_o_pay_theme", next);
}

// Showcase Tabs Data (Full English)
const showcaseData = {
  beranda: {
    title: "Instant Financial Dashboard",
    desc: "View your total balance, monthly inflows and outflows, recent activities, and quick-action shortcuts in one clean interface.",
    bullets: [
      "Gradient forest balance card with quick financial summary",
      "Instant deposit, expense, and transaction filters",
      "Recent activity feed pulled directly from local SQLite"
    ]
  },
  transaksi: {
    title: "Detailed & Fast Transaction Logging",
    desc: "Record every expense with rich metadata. Attach custom categories, custom dates, memos, and receipt photos with ease.",
    bullets: [
      "Dynamic categories with custom badges and icons",
      "Attach receipt photos directly from camera or device storage",
      "Real-time search query filtering and date range filters"
    ]
  },
  anggaran: {
    title: "Category Monthly Budgets",
    desc: "Set spending caps for groceries, transport, or utilities. Visual progress bars notify you as you approach designated limits.",
    bullets: [
      "Adaptive color progress bars (Green -> Amber -> Red)",
      "Automatic calculation of daily remaining allowance",
      "Adjust and tune budget limits anytime without friction"
    ]
  },
  tabungan: {
    title: "Dedicated Savings Goals",
    desc: "Bring your financial dreams to life step-by-step. Set emergency funds, new devices, or vacations, and deposit funds whenever ready.",
    bullets: [
      "Motivating percentage progress trackers",
      "Estimated completion date predictions based on contributions",
      "Transparent deposit history for each individual goal"
    ]
  }
};

function setupShowcaseTabs() {
  const tabs = document.querySelectorAll(".showcase-tab-btn");
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

// Fetch latest release tag from GitHub API to keep web badges dynamically up-to-date
function fetchLatestReleaseVersion() {
  fetch("https://api.github.com/repos/hyenavia/wall-o-pay/releases/latest")
    .then(res => {
      if (!res.ok) throw new Error("GitHub API unavailable or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        document.querySelectorAll(".app-version-tag").forEach(el => {
          el.textContent = tag;
        });
        const heroDownloadText = document.getElementById("hero-download-text");
        if (heroDownloadText) {
          heroDownloadText.textContent = `Download APK (${tag})`;
        }
        const specsVersion = document.getElementById("specs-version-val");
        if (specsVersion) {
          specsVersion.textContent = `${tag} (Release)`;
        }
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION
    });
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  // Theme init
  const savedTheme = localStorage.getItem("wall_o_pay_theme") || "light";
  document.documentElement.setAttribute("data-theme", savedTheme);
  const themeBtn = document.getElementById("theme-btn");
  if (themeBtn) {
    themeBtn.textContent = savedTheme === "dark" ? "☀️" : "🌙";
    themeBtn.addEventListener("click", toggleTheme);
  }

  setupShowcaseTabs();
  setupMobileNav();
  fetchLatestReleaseVersion();
});
