/*
 * Golf Analytics Lab — Build a Better Bag Golf Ball Buyers Guide
 * Men/Women audience update.
 *
 * This file works with the existing index.html. It inserts the audience
 * selector automatically, so no HTML edit is required.
 */
(function () {
  "use strict";

  const balls = Array.isArray(window.GOLF_BALLS)
    ? window.GOLF_BALLS
    : Array.isArray(window.GOLF_BALL_DATA)
      ? window.GOLF_BALL_DATA
      : [];

  const meta = window.GOLF_BALL_META || {};
  const state = {
    audience: "men",
    swing: "not-sure",
    feel: "no-preference",
    cover: "balanced",
    budget: "no-preference",
    construction: "no-preference",
    brand: "all",
    search: "",
    sort: "score",
  };

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function finiteNumber(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number : null;
  }

  function normalize(value) {
    return String(value ?? "").trim().toLowerCase();
  }

  function includesAny(text, terms) {
    const haystack = normalize(text);
    return terms.some((term) => haystack.includes(term));
  }

  function addAudienceSelector() {
    const controls = $(".controls");
    const firstExistingGroup = controls?.querySelector(".control-group");
    if (!controls || !firstExistingGroup || $('[data-generated="audience-control"]')) return;

    const wrapper = document.createElement("div");
    wrapper.className = "control-group";
    wrapper.dataset.generated = "audience-control";
    wrapper.innerHTML = `
      <label>Who are you shopping for?</label>
      <div class="help">Women includes women-specific and unisex golf balls. Men includes unisex golf balls.</div>
      <div class="segmented">
        <button class="active" data-field="audience" data-value="men">Men<br><small>unisex models</small></button>
        <button data-field="audience" data-value="women">Women<br><small>women-specific + unisex</small></button>
      </div>
    `;
    controls.insertBefore(wrapper, firstExistingGroup);
  }

  function addSupportingStyles() {
    if ($("#gal-gender-js-styles")) return;
    const style = document.createElement("style");
    style.id = "gal-gender-js-styles";
    style.textContent = `
      .ball-card {
        border: 1px solid rgba(12, 31, 51, .14);
        border-radius: 16px;
        padding: 18px;
        background: #fff;
        box-shadow: 0 8px 24px rgba(12, 31, 51, .07);
        display: flex;
        flex-direction: column;
        gap: 12px;
      }
      .ball-card__top, .ball-card__footer {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 12px;
      }
      .ball-card h3 { margin: 0; font-size: 1.08rem; line-height: 1.25; }
      .ball-card__brand {
        color: #f28c28;
        font-weight: 800;
        font-size: .78rem;
        letter-spacing: .06em;
        text-transform: uppercase;
      }
      .match-score {
        min-width: 54px;
        border-radius: 999px;
        padding: 7px 9px;
        text-align: center;
        background: #0b1f33;
        color: #fff;
        font-weight: 800;
        font-size: .82rem;
      }
      .audience-badge {
        display: inline-flex;
        align-items: center;
        width: fit-content;
        border-radius: 999px;
        padding: 5px 9px;
        background: #e8f1f8;
        color: #0b1f33;
        font-size: .72rem;
        font-weight: 800;
      }
      .audience-badge--women { background: #f6c28b; }
      .ball-specs {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 8px;
      }
      .ball-spec {
        border-radius: 10px;
        background: #f5f7f9;
        padding: 9px 10px;
        font-size: .78rem;
        line-height: 1.3;
      }
      .ball-spec b { display: block; color: #0b1f33; margin-bottom: 2px; }
      .match-reasons { margin: 0; padding-left: 18px; font-size: .82rem; line-height: 1.45; }
      .ball-card__notes { margin: 0; font-size: .82rem; line-height: 1.45; color: #46515c; }
      .ball-card__link {
        color: #0b1f33;
        font-weight: 800;
        text-decoration: none;
      }
      .ball-card__link:hover { text-decoration: underline; }
      .availability-warning { color: #9a3412; font-weight: 800; font-size: .75rem; }
      .no-results {
        grid-column: 1 / -1;
        padding: 36px 20px;
        text-align: center;
        border: 1px dashed rgba(12,31,51,.25);
        border-radius: 14px;
      }
      @media (max-width: 520px) {
        .ball-specs { grid-template-columns: 1fr; }
      }
    `;
    document.head.appendChild(style);
  }

  function populateBrands() {
    const select = $("#brand");
    if (!select) return;

    const brands = [...new Set(balls.map((ball) => ball.brand).filter(Boolean))]
      .sort((a, b) => a.localeCompare(b));

    select.innerHTML = '<option value="all">All brands</option>' +
      brands.map((brand) => `<option value="${escapeHtml(brand)}">${escapeHtml(brand)}</option>`).join("");
  }

  function isAudienceEligible(ball) {
    return state.audience === "women" ? Boolean(ball.eligibleWomen) : Boolean(ball.eligibleMen);
  }

  function compressionScore(ball, reasons) {
    const compression = finiteNumber(ball.compression);
    if (compression === null || state.swing === "not-sure") return 0;

    const targets = {
      slow: { ideal: 50, tolerance: 28 },
      moderate: { ideal: 72, tolerance: 25 },
      fast: { ideal: 92, tolerance: 24 },
    };
    const target = targets[state.swing];
    const distance = Math.abs(compression - target.ideal);
    const score = Math.max(-20, 28 - (distance / target.tolerance) * 30);

    if (score >= 16) reasons.push(`Compression ${compression} is a strong ${state.swing} swing-speed match.`);
    else if (score >= 7) reasons.push(`Compression ${compression} is within a practical ${state.swing} range.`);
    return score;
  }

  function feelScore(ball, reasons) {
    if (state.feel === "no-preference") return 0;
    const compression = finiteNumber(ball.compression);
    const text = `${ball.compressionRaw} ${ball.notes} ${ball.construction}`;

    let perceived = "balanced";
    if ((compression !== null && compression <= 62) || includesAny(text, ["very soft", "soft feel", "low compression"])) {
      perceived = "soft";
    } else if ((compression !== null && compression >= 86) || includesAny(text, ["firm", "high compression"])) {
      perceived = "firm";
    }

    if (perceived === state.feel) {
      reasons.push(`${state.feel[0].toUpperCase() + state.feel.slice(1)} feel matches your preference.`);
      return 14;
    }
    if (perceived === "balanced" || state.feel === "balanced") return 5;
    return -7;
  }

  function coverScore(ball, reasons) {
    const cover = normalize(ball.cover);
    const urethane = cover.includes("urethane");
    const durable = includesAny(cover, ["ionomer", "surlyn", "truflex", "hybrid"]);

    if (state.cover === "spin") {
      if (urethane) {
        reasons.push("Urethane cover supports more greenside spin and control.");
        return 18;
      }
      return -7;
    }

    if (state.cover === "durable") {
      if (durable && !urethane) {
        reasons.push("Durable cover aligns with value and long-wearing performance.");
        return 16;
      }
      return urethane ? -5 : 5;
    }

    // Balanced
    if (urethane) return 9;
    if (durable) return 8;
    return 3;
  }

  function budgetScore(ball, reasons) {
    const price = finiteNumber(ball.parsedPrice);
    if (state.budget === "no-preference" || price === null) return 0;

    let match = false;
    if (state.budget === "value") match = price < 30;
    if (state.budget === "mid") match = price >= 30 && price < 45;
    if (state.budget === "premium") match = price >= 45;

    if (match) {
      reasons.push(`Price fits the ${state.budget} budget tier.`);
      return 16;
    }

    if (state.budget === "value" && price >= 45) return -15;
    if (state.budget === "premium" && price < 30) return -4;
    return -8;
  }

  function constructionScore(ball, reasons) {
    if (state.construction === "no-preference") return 0;
    const construction = normalize(ball.construction);
    let match = false;

    if (state.construction === "2-piece") match = construction.includes("2-piece");
    if (state.construction === "3-piece") match = construction.includes("3-piece");
    if (state.construction === "4-plus") {
      match = includesAny(construction, ["4-piece", "5-piece", "multi-piece", "dual-core", "tour construction"]);
    }

    if (match) {
      reasons.push(`${ball.construction} construction matches your selection.`);
      return 12;
    }
    return -12;
  }

  function audienceScore(ball, reasons) {
    if (state.audience === "women" && ball.productAudience === "Women-specific") {
      const fitText = normalize(ball.suggestedSwingSpeedFit);
      const swingAligned =
        state.swing === "not-sure" ||
        fitText.includes(state.swing) ||
        (state.swing === "slow" && fitText.includes("moderate"));

      if (swingAligned) {
        reasons.push("Women-specific design is included without excluding unisex performance matches.");
        return 5;
      }
    }
    return 0;
  }

  function qualityScore(ball) {
    const confidence = normalize(ball.dataConfidence);
    if (confidence === "high") return 3;
    if (confidence === "medium") return 1;
    return 0;
  }

  function availabilityScore(ball, reasons) {
    const status = normalize(ball.linkStatus);
    if (includesAny(status, ["sold out", "unavailable"])) {
      reasons.push("Availability may be limited.");
      return -12;
    }
    return 0;
  }

  function scoreBall(ball) {
    const reasons = [];
    let score = 50;

    score += compressionScore(ball, reasons);
    score += feelScore(ball, reasons);
    score += coverScore(ball, reasons);
    score += budgetScore(ball, reasons);
    score += constructionScore(ball, reasons);
    score += audienceScore(ball, reasons);
    score += qualityScore(ball);
    score += availabilityScore(ball, reasons);

    score = Math.max(0, Math.min(100, Math.round(score)));
    return { ...ball, score, reasons: reasons.slice(0, 4) };
  }

  function matchesFilters(ball) {
    if (!isAudienceEligible(ball)) return false;
    if (state.brand !== "all" && ball.brand !== state.brand) return false;

    if (state.search) {
      const haystack = normalize([
        ball.brand,
        ball.model,
        ball.compressionRaw,
        ball.construction,
        ball.cover,
        ball.cost,
        ball.retailers,
        ball.notes,
        ball.womensFitCategory,
        ball.suggestedSwingSpeedFit,
        ball.launchProfile,
        ball.womensFitRationale,
        ball.productAudience,
      ].join(" "));

      if (!haystack.includes(normalize(state.search))) return false;
    }

    return true;
  }

  function sortResults(results) {
    const copy = [...results];

    const numberOr = (value, fallback) => {
      const number = finiteNumber(value);
      return number === null ? fallback : number;
    };

    const sorters = {
      score: (a, b) => b.score - a.score || a.brand.localeCompare(b.brand) || a.model.localeCompare(b.model),
      "cost-low": (a, b) => numberOr(a.parsedPrice, Infinity) - numberOr(b.parsedPrice, Infinity),
      "cost-high": (a, b) => numberOr(b.parsedPrice, -Infinity) - numberOr(a.parsedPrice, -Infinity),
      "compression-low": (a, b) => numberOr(a.compression, Infinity) - numberOr(b.compression, Infinity),
      "compression-high": (a, b) => numberOr(b.compression, -Infinity) - numberOr(a.compression, -Infinity),
      brand: (a, b) => a.brand.localeCompare(b.brand) || a.model.localeCompare(b.model),
    };

    return copy.sort(sorters[state.sort] || sorters.score);
  }

  function displayCompression(ball) {
    return finiteNumber(ball.compression) !== null
      ? String(ball.compression)
      : (ball.compressionRaw || "Not published");
  }

  function audienceLabel(ball) {
    return ball.productAudience === "Women-specific" ? "Women-specific" : "Unisex";
  }

  function notesFor(ball) {
    if (state.audience === "women" && ball.womensFitRationale) return ball.womensFitRationale;
    return ball.notes || ball.verificationNotes || "See product source for additional specifications.";
  }

  function renderCards(results) {
    const cards = $("#cards");
    if (!cards) return;

    if (!results.length) {
      cards.innerHTML = `
        <div class="no-results">
          <h3>No exact matches found</h3>
          <p>Try resetting one or more preferences. Audience eligibility remains enforced.</p>
        </div>
      `;
      return;
    }

    cards.innerHTML = results.slice(0, 12).map((ball) => {
      const womenClass = ball.productAudience === "Women-specific" ? " audience-badge--women" : "";
      const source = ball.sourceUrl
        ? `<a class="ball-card__link" href="${escapeHtml(ball.sourceUrl)}" target="_blank" rel="noopener noreferrer">Product source ↗</a>`
        : "";
      const warning = includesAny(ball.linkStatus, ["sold out", "unavailable"])
        ? `<span class="availability-warning">${escapeHtml(ball.linkStatus)}</span>`
        : "";
      const reasons = ball.reasons.length
        ? `<ul class="match-reasons">${ball.reasons.map((reason) => `<li>${escapeHtml(reason)}</li>`).join("")}</ul>`
        : "";

      return `
        <article class="ball-card">
          <div class="ball-card__top">
            <div>
              <div class="ball-card__brand">${escapeHtml(ball.brand)}</div>
              <h3>${escapeHtml(ball.model)}</h3>
            </div>
            <div class="match-score">${ball.score}%</div>
          </div>

          <span class="audience-badge${womenClass}">${escapeHtml(audienceLabel(ball))}</span>

          <div class="ball-specs">
            <div class="ball-spec"><b>Compression</b>${escapeHtml(displayCompression(ball))}</div>
            <div class="ball-spec"><b>Construction</b>${escapeHtml(ball.construction || "Not listed")}</div>
            <div class="ball-spec"><b>Cover</b>${escapeHtml(ball.cover || "Not listed")}</div>
            <div class="ball-spec"><b>Cost</b>${escapeHtml(ball.cost || "Retailer-dependent")}</div>
          </div>

          ${reasons}
          <p class="ball-card__notes">${escapeHtml(notesFor(ball))}</p>

          <div class="ball-card__footer">
            ${source}
            ${warning}
          </div>
        </article>
      `;
    }).join("");
  }

  function renderComparison(results) {
    const body = $("#compareBody");
    if (!body) return;

    body.innerHTML = results.slice(0, 20).map((ball) => `
      <tr>
        <td><b>${escapeHtml(ball.brand)} ${escapeHtml(ball.model)}</b><br><small>${escapeHtml(audienceLabel(ball))}</small></td>
        <td>${ball.score}%</td>
        <td>${escapeHtml(displayCompression(ball))}</td>
        <td>${escapeHtml(ball.construction || "—")}</td>
        <td>${escapeHtml(ball.cover || "—")}</td>
        <td>${escapeHtml(ball.cost || "—")}</td>
        <td>${escapeHtml(notesFor(ball))}</td>
      </tr>
    `).join("");
  }

  function updateStats(results) {
    const eligiblePool = balls.filter(isAudienceEligible);
    const recordCount = $("#recordCount");
    const brandCount = $("#brandCount");
    const resultCount = $("#resultCount");
    const topPick = $("#topPick");
    const sourceFile = $("#sourceFile");

    if (recordCount) recordCount.textContent = String(eligiblePool.length);
    if (brandCount) brandCount.textContent = String(new Set(eligiblePool.map((ball) => ball.brand)).size);
    if (resultCount) resultCount.textContent = String(results.length);
    if (topPick) topPick.textContent = results[0] ? `${results[0].brand} ${results[0].model}` : "—";
    if (sourceFile) sourceFile.textContent = meta.sourceFile || "updated golf-ball database";
  }

  function render() {
    const results = sortResults(balls.filter(matchesFilters).map(scoreBall));
    renderCards(results);
    renderComparison(results);
    updateStats(results);
  }

  function setSegmentedValue(field, value, button) {
    state[field] = value;
    $$(`[data-field="${field}"]`).forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    render();
  }

  function resetControls() {
    Object.assign(state, {
      audience: "men",
      swing: "not-sure",
      feel: "no-preference",
      cover: "balanced",
      budget: "no-preference",
      construction: "no-preference",
      brand: "all",
      search: "",
      sort: "score",
    });

    $$("[data-field]").forEach((button) => {
      const shouldBeActive =
        (button.dataset.field === "audience" && button.dataset.value === "men") ||
        (button.dataset.field === "swing" && button.dataset.value === "not-sure") ||
        (button.dataset.field === "feel" && button.dataset.value === "no-preference") ||
        (button.dataset.field === "cover" && button.dataset.value === "balanced") ||
        (button.dataset.field === "budget" && button.dataset.value === "no-preference");
      button.classList.toggle("active", shouldBeActive);
    });

    if ($("#construction")) $("#construction").value = "no-preference";
    if ($("#brand")) $("#brand").value = "all";
    if ($("#search")) $("#search").value = "";
    if ($("#sort")) $("#sort").value = "score";
    render();
  }

  function bindEvents() {
    document.addEventListener("click", (event) => {
      const segmentedButton = event.target.closest("button[data-field][data-value]");
      if (segmentedButton) {
        setSegmentedValue(
          segmentedButton.dataset.field,
          segmentedButton.dataset.value,
          segmentedButton
        );
      }
    });

    $("#construction")?.addEventListener("change", (event) => {
      state.construction = event.target.value;
      render();
    });

    $("#brand")?.addEventListener("change", (event) => {
      state.brand = event.target.value;
      render();
    });

    $("#search")?.addEventListener("input", (event) => {
      state.search = event.target.value;
      render();
    });

    $("#sort")?.addEventListener("change", (event) => {
      state.sort = event.target.value;
      render();
    });

    $("#find")?.addEventListener("click", render);
    $("#reset")?.addEventListener("click", resetControls);
  }

  function initialize() {
    if (!balls.length) {
      console.error("Golf Ball Buyers Guide: data.js did not provide any records.");
      const cards = $("#cards");
      if (cards) cards.innerHTML = '<div class="no-results"><h3>Database unavailable</h3><p>Confirm data.js loads before app.js.</p></div>';
      return;
    }

    addSupportingStyles();
    addAudienceSelector();
    populateBrands();
    bindEvents();
    render();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialize, { once: true });
  } else {
    initialize();
  }
})();
