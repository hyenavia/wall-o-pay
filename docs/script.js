/**
 * Wall o' Pay - Landing Page Interactive Logic
 * Signature Vice City Sunset Theme
 * Includes: Showcase Screen Switcher, Mobile Nav Drawer,
 * and GitHub Releases API Version Sync.
 */

const APP_VERSION = "3.0.0";

// Helper to compare semver strings (e.g. "2.5.4" vs "v2.5.3")
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

// 1. Interactive App Showcase Screen Switcher
function setupShowcaseTabs() {
  const tabButtons = document.querySelectorAll(".showcase-tab-btn");
  const screenPanels = document.querySelectorAll(".showcase-screen-panel");
  const detailPanels = document.querySelectorAll(".showcase-detail-panel");

  if (!tabButtons.length || !screenPanels.length) return;

  tabButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      const targetScreen = btn.getAttribute("data-screen");

      // Update active tab button
      tabButtons.forEach(b => {
        const isActive = b === btn;
        b.classList.toggle("active", isActive);
        b.setAttribute("aria-selected", String(isActive));
      });

      // Update visible phone screen panel
      screenPanels.forEach(panel => {
        const matches = panel.getAttribute("data-screen") === targetScreen;
        panel.classList.toggle("active", matches);
        if (matches) {
          panel.removeAttribute("hidden");
        } else {
          panel.setAttribute("hidden", "true");
        }
      });

      // Update visible detail explanation panel if present
      detailPanels.forEach(panel => {
        const matches = panel.getAttribute("data-screen") === targetScreen;
        panel.classList.toggle("active", matches);
        if (matches) {
          panel.removeAttribute("hidden");
        } else {
          panel.setAttribute("hidden", "true");
        }
      });
    });
  });
}

// 2. Mobile Navigation Drawer Toggle & Close on Anchor Click
function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const nav = document.getElementById("nav-links");
  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      const isOpen = nav.classList.toggle("active");
      toggle.setAttribute("aria-expanded", String(isOpen));
      toggle.innerHTML = isOpen ? "✕" : "☰";
    });

    nav.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", () => {
        nav.classList.remove("active");
        toggle.setAttribute("aria-expanded", "false");
        toggle.innerHTML = "☰";
      });
    });
  }
}

// 3. Header Scroll Elevation & Active Spy
function setupNavScroll() {
  const header = document.querySelector("header.glass-nav");
  if (!header) return;

  window.addEventListener("scroll", () => {
    if (window.scrollY > 40) {
      header.classList.add("scrolled");
    } else {
      header.classList.remove("scrolled");
    }
  }, { passive: true });
}

// 4. GitHub API: Fetch Latest Release Version without downgrading local version
function fetchLatestReleaseVersion() {
  // Apply baseline local version
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
        // Only update if GitHub tag is strictly newer than local version
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

// Initialize on DOM Ready
document.addEventListener("DOMContentLoaded", () => {
  setupShowcaseTabs();
  setupMobileNav();
  setupNavScroll();
  fetchLatestReleaseVersion();
});
