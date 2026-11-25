/**
 * Wall o' Pay — Landing Page Interactive Logic
 * Concept adapted from Lunera | Signature Vice City Sunset Theme
 * 
 * Features:
 * - Dynamic Greeting & Live Time in Phone Mockup
 * - Interactive Cashflow Command Engine Switcher (Pulse, Pools, Rapid, Debt)
 * - Interactive Daily Budget Pulse Calibrator (Real-Time Income Slider)
 * - GitHub Releases API Version Sync with Direct APK Asset Resolution
 * - Active ScrollSpy & Header Elevation
 * - Accessible Mobile Navigation Drawer
 */

const REPO_NAME = "hyenavia/wall-o-pay";
const APP_VERSION = "3.1.2";

// Helper to update button label text without stripping SVG icon or shimmer span
function setButtonLabel(button, text) {
  if (!button) return;
  const labelSpan = button.querySelector("span:not(.btn-shimmer)");
  if (labelSpan) {
    labelSpan.textContent = text;
  }
}

// SemVer comparison helper
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

// 1. Fetch latest release tag and direct APK link from GitHub API
function fetchLatestReleaseVersion() {
  const directApkUrl = `https://github.com/${REPO_NAME}/releases/latest/download/Wall_o_Pay.apk`;

  // Apply baseline local version
  document.querySelectorAll(".app-version-tag").forEach(el => {
    el.textContent = `v${APP_VERSION}`;
  });

  const heroDownloadBtn = document.getElementById("hero-download-btn");
  if (heroDownloadBtn) {
    setButtonLabel(heroDownloadBtn, `Download APK (v${APP_VERSION})`);
  }

  const ctaDownloadBtn = document.getElementById("cta-download-btn");
  if (ctaDownloadBtn) {
    setButtonLabel(ctaDownloadBtn, `Download APK (v${APP_VERSION})`);
  }

  fetch(`https://api.github.com/repos/${REPO_NAME}/releases/latest`)
    .then(res => {
      if (!res.ok) throw new Error("GitHub API offline or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        // Only update version badge if remote version is greater than local
        if (isVersionGreater(tag, APP_VERSION)) {
          document.querySelectorAll(".app-version-tag").forEach(el => {
            el.textContent = tag.startsWith("v") ? tag : `v${tag}`;
          });
        }

        if (heroDownloadBtn) {
          setButtonLabel(heroDownloadBtn, `Download APK (${tag})`);
        }
        if (ctaDownloadBtn) {
          setButtonLabel(ctaDownloadBtn, `Download APK (${tag})`);
        }

        const apkAsset = data.assets?.find(a => a.name.endsWith('.apk'));
        const downloadUrl = apkAsset ? apkAsset.browser_download_url : directApkUrl;
        document.querySelectorAll(".apk-download-btn").forEach(link => {
          link.href = downloadUrl;
        });
      }
    })
    .catch(() => {
      // Graceful fallback to embedded APP_VERSION
      document.querySelectorAll(".apk-download-btn").forEach(link => {
        link.href = directApkUrl;
      });
    });
}

// 2. Set time-of-day greeting and live date in phone mockup
function updateMockupGreeting() {
  const now = new Date();

  const dateEl = document.getElementById("phone-date-display");
  if (dateEl) {
    const options = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' };
    dateEl.textContent = now.toLocaleDateString('en-US', options);
  }

  const timeString = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  const timeEl = document.getElementById("phone-time-display");
  if (timeEl) timeEl.textContent = timeString;

  const timeBEl = document.getElementById("phone-b-time-display");
  if (timeBEl) timeBEl.textContent = timeString;

  const greetEl = document.getElementById("phone-greet-display");
  if (greetEl) {
    const hour = now.getHours();
    let greeting = "Good evening,";
    if (hour < 12) {
      greeting = "Good morning,";
    } else if (hour < 17) {
      greeting = "Good afternoon,";
    }
    greetEl.textContent = greeting;
  }
}

// 3. Interactive Cashflow Command Engine Switcher (Adapting Lunera's Route Switcher)
function setupCashflowSwitcher() {
  const pills = document.querySelectorAll(".route-pill");
  if (!pills.length) return;

  const modeData = {
    pulse: {
      heroTitle: "Daily Financial Pulse",
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
        { label: "Needs Pool", val: "50%", scale: 0.50 },
        { label: "Wants Pool", val: "30%", scale: 0.30 },
        { label: "Savings Reserve", val: "20%", scale: 0.20 }
      ],
      mascotAvatar: "images/chibi/chibi_01.png"
    },
    pools: {
      heroTitle: "50/30/20 Smart Pools",
      cardLabel: "Monthly Pool Allocation",
      amount: "Rp 8.500.000",
      amountSub: "Needs (50%) · Wants (30%) · Savings (20%)",
      badgeText: "Autonomous",
      badgeClass: "badge-pools",
      meterScale: 0.50,
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
      heroTitle: "5-Second Rapid Logging",
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
      heroTitle: "Debt & Custom Split Bills",
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
  };

  const triggerMorph = (el) => {
    if (!el) return;
    el.classList.remove("phone-morph-in");
    void el.offsetWidth;
    el.classList.add("phone-morph-in");
  };

  pills.forEach(pill => {
    pill.addEventListener("click", () => {
      const modeKey = pill.getAttribute("data-mode");
      const data = modeData[modeKey];
      if (!data) return;

      pills.forEach(p => {
        p.classList.remove("active");
        p.setAttribute("aria-selected", "false");
      });
      pill.classList.add("active");
      pill.setAttribute("aria-selected", "true");

      // Update Phone A (Primary Command)
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
        txValEl.className = `tx-val ${data.txIsPositive ? 'pos' : 'neg'}`;
      }

      const tx2TitleEl = document.getElementById("mockup-tx2-title");
      if (tx2TitleEl) tx2TitleEl.textContent = data.tx2Title;

      const tx2SubEl = document.getElementById("mockup-tx2-sub");
      if (tx2SubEl) tx2SubEl.textContent = data.tx2Sub;

      const tx2ValEl = document.getElementById("mockup-tx2-val");
      if (tx2ValEl) {
        tx2ValEl.textContent = data.tx2Amount;
        tx2ValEl.className = `tx-val ${data.tx2IsPositive ? 'pos' : 'neg'}`;
      }

      // Sync Bottom Dock Active Tab
      document.querySelectorAll("#mockup-bottom-dock .dock-item").forEach(item => {
        item.classList.toggle("active", item.getAttribute("data-dock") === data.dockTab);
      });

      // Update Wendy companion avatar reaction
      const avatarImg = document.getElementById("phone-avatar-img");
      if (avatarImg && data.mascotAvatar) {
        avatarImg.src = data.mascotAvatar;
        avatarImg.classList.remove("pop");
        void avatarImg.offsetWidth;
        avatarImg.classList.add("pop");
        setTimeout(() => avatarImg.classList.remove("pop"), 260);
      }

      // Update Phone B (Trajectory & Breakdown)
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

      // Subtle Jakub materialization on updated cards
      triggerMorph(document.getElementById("mockup-phone-a-card"));
      triggerMorph(document.getElementById("mockup-tx-list"));
      triggerMorph(document.getElementById("mockup-phone-b-card"));
      triggerMorph(document.getElementById("mockup-breakdown-card"));
    });
  });
}

// 4. Interactive Daily Budget Pulse Calibrator (Adapting Lunera's Scrubber)
function setupPulseCalibrator() {
  const slider = document.getElementById("income-scrubber-range");
  if (!slider) return;

  const readout = document.getElementById("calibrator-income-readout");
  const dailyQuotaEl = document.getElementById("calibrator-daily-quota");
  const needsEl = document.getElementById("calibrator-needs-amount");
  const wantsEl = document.getElementById("calibrator-wants-amount");
  const savingsEl = document.getElementById("calibrator-savings-amount");
  const hintEl = document.getElementById("calibrator-hint-text");
  const chartDot = document.getElementById("calibrator-chart-dot");
  const ticks = document.querySelectorAll(".scrubber-ticks-row .tick");

  const formatRupiah = (val) => {
    return "Rp " + val.toLocaleString('id-ID');
  };

  const incomeTiers = [
    {
      income: 3000000,
      label: "Rp 3.000.000 / mo",
      daily: 50000,
      needs: 1500000,
      wants: 900000,
      savings: 600000,
      dotX: 25,
      dotY: 46,
      hint: "Lean & intentional budget. Rp 50.000/day keeps daily expenses completely under control."
    },
    {
      income: 5000000,
      label: "Rp 5.000.000 / mo",
      daily: 85000,
      needs: 2500000,
      wants: 1500000,
      savings: 1000000,
      dotX: 65,
      dotY: 38,
      hint: "Balanced entry tier. 50% shields living costs while building Rp 1.000.000 savings reserve every month."
    },
    {
      income: 8500000,
      label: "Rp 8.500.000 / mo",
      daily: 145000,
      needs: 4250000,
      wants: 2550000,
      savings: 1700000,
      dotX: 120,
      dotY: 28,
      hint: "The signature Wall o' Pay sweet spot! Safe spending speed of Rp 145.000/day ensures zero month-end stress."
    },
    {
      income: 12500000,
      label: "Rp 12.500.000 / mo",
      daily: 215000,
      needs: 6250000,
      wants: 3750000,
      savings: 2500000,
      dotX: 175,
      dotY: 22,
      hint: "Accelerated growth! Over Rp 2.500.000 flows directly into your emergency fortress each month."
    },
    {
      income: 18000000,
      label: "Rp 18.000.000 / mo",
      daily: 310000,
      needs: 9000000,
      wants: 5400000,
      savings: 3600000,
      dotX: 230,
      dotY: 18,
      hint: "Sovereign freedom tier. Discretionary spending comfortably buffered without impacting long-term goals."
    },
    {
      income: 25000000,
      label: "Rp 25.000.000 / mo",
      daily: 430000,
      needs: 12500000,
      wants: 7500000,
      savings: 5000000,
      dotX: 280,
      dotY: 14,
      hint: "Maximum velocity! Rp 5.000.000 monthly passive wealth accumulation with full offline peace of mind."
    }
  ];

  const updateState = (idx) => {
    const tier = incomeTiers[idx];
    if (!tier) return;

    slider.value = idx;

    if (readout) readout.textContent = tier.label;
    if (dailyQuotaEl) dailyQuotaEl.innerHTML = `${formatRupiah(tier.daily)} <small>/ day safe</small>`;
    if (needsEl) needsEl.textContent = formatRupiah(tier.needs);
    if (wantsEl) wantsEl.textContent = formatRupiah(tier.wants);
    if (savingsEl) savingsEl.textContent = formatRupiah(tier.savings);
    if (hintEl) hintEl.textContent = tier.hint;

    if (chartDot) {
      chartDot.setAttribute("cx", tier.dotX);
      chartDot.setAttribute("cy", tier.dotY);
    }

    ticks.forEach(t => {
      const stepVal = parseInt(t.getAttribute("data-step"), 10);
      t.classList.toggle("active", stepVal === idx);
    });
  };

  slider.addEventListener("input", (e) => {
    updateState(parseInt(e.target.value, 10));
  });

  ticks.forEach(t => {
    t.addEventListener("click", () => {
      updateState(parseInt(t.getAttribute("data-step"), 10));
    });
  });

  // Default to tier 2 (Rp 8.500.000 signature sweet spot)
  updateState(2);
}

// 5. Active ScrollSpy & Smooth Header Elevation
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

// 6. Mobile Navigation Drawer Toggle & Escape Handler
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

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && navList.classList.contains("active")) {
      closeNav();
      toggle.focus();
    }
  });
}

// Initialize on DOM Ready
document.addEventListener("DOMContentLoaded", () => {
  fetchLatestReleaseVersion();
  updateMockupGreeting();
  setupCashflowSwitcher();
  setupPulseCalibrator();
  setupActiveNav();
  setupMobileNav();
});
