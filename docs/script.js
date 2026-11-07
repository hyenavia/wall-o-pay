/**
 * Wall o' Pay - Landing Page Interactive Logic
 * Botanical Forest & Pure Cyberpunk Theme Switcher, Testimonial Carousel,
 * Mobile Navigation, and GitHub Releases API Version Sync.
 */

const APP_VERSION = "2.1.1";
const THEME_STORAGE_KEY = "wall_o_pay_theme";

// Helper to compare semver strings (e.g. "2.0.10" vs "v2.0.9")
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

// Interactive Mockup Dual-Theme Preview (Option A: Showcase Teaser)
function setupMockupThemeToggle() {
  const duo = document.getElementById("duo-mockup");
  const btnBot = document.getElementById("btn-theme-botanical");
  const btnCyber = document.getElementById("btn-theme-cyberpunk");

  if (!duo || !btnBot || !btnCyber) return;

  function setMockupTheme(theme) {
    const isCyber = theme === "cyberpunk";
    duo.setAttribute("data-preview", theme);

    if (isCyber) {
      btnCyber.classList.add("active");
      btnCyber.setAttribute("aria-selected", "true");
      btnBot.classList.remove("active");
      btnBot.setAttribute("aria-selected", "false");
    } else {
      btnBot.classList.add("active");
      btnBot.setAttribute("aria-selected", "true");
      btnCyber.classList.remove("active");
      btnCyber.setAttribute("aria-selected", "false");
    }
  }

  btnBot.addEventListener("click", () => setMockupTheme("botanical"));
  btnCyber.addEventListener("click", () => setMockupTheme("cyberpunk"));
}

// Testimonials Carousel
const testimonials = [
  {
    quote: "“Wall o’ Pay made me far more aware of my daily spending leaks. Managing my monthly allowance is now completely effortless!”",
    author: "— Sarah, University Student"
  },
  {
    quote: "“The 50/30/20 budget pools and Daily Pulse tell me exactly when to stop splurging. Plus, offline SQLite means it opens instantly with zero lag.”",
    author: "— Rafi, Software Engineer"
  },
  {
    quote: "“I love the dual aesthetics! Botanical Forest feels like a serene sanctuary by day, and Cyberpunk turns my expenses into an edgy sci-fi terminal.”",
    author: "— Dina, UI/UX Designer"
  }
];

function setupTestimonials() {
  const quoteText = document.getElementById("qt");
  const quoteAuthor = document.getElementById("qn");
  const dotsContainer = document.getElementById("dots");
  const nextBtn = document.getElementById("next");

  if (!quoteText || !quoteAuthor || !dotsContainer || !nextBtn) return;

  let currentIndex = 0;
  let timer = null;

  function show(index) {
    currentIndex = (index + testimonials.length) % testimonials.length;
    quoteText.textContent = testimonials[currentIndex].quote;
    quoteAuthor.textContent = testimonials[currentIndex].author;

    Array.from(dotsContainer.children).forEach((dot, idx) => {
      dot.setAttribute("aria-current", String(idx === currentIndex));
    });
  }

  // Create dot buttons
  dotsContainer.innerHTML = "";
  testimonials.forEach((_, idx) => {
    const dot = document.createElement("button");
    dot.setAttribute("type", "button");
    dot.setAttribute("aria-label", `Testimonial ${idx + 1}`);
    dot.addEventListener("click", () => {
      show(idx);
      resetTimer();
    });
    dotsContainer.appendChild(dot);
  });

  nextBtn.addEventListener("click", () => {
    show(currentIndex + 1);
    resetTimer();
  });

  function startTimer() {
    timer = setInterval(() => {
      show(currentIndex + 1);
    }, 7000);
  }

  function resetTimer() {
    if (timer) clearInterval(timer);
    startTimer();
  }

  show(0);
  startTimer();
}

// Mobile Nav Menu Toggle
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

// GitHub API: Fetch Latest Release Version without downgrading local version
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
  setupMockupThemeToggle();
  setupTestimonials();
  setupMobileNav();
  fetchLatestReleaseVersion();
});
