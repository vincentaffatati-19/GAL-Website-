/*
  Golf Analytics Lab
  Build a Better Bag — Golf Ball Buyers Guide
  GitHub-ready version using uploaded spreadsheet database and value-weighted scoring.
*/

(function () {
  "use strict";

  const WEIGHTS = { compression: 0.30, feel: 0.15, cover: 0.15, construction: 0.10, cost: 0.30 };

  const state = {
    swing: "not-sure",
    feel: "no-preference",
    cover: "balanced",
    budget: "no-preference",
    construction: "no-preference",
    brand: "all",
    search: "",
    sort: "score"
  };

  const els = {};

  function init() {
    cacheElements();
    bindControls();
    populateBrandFilter();
    updateStats();
    render();
  }

  function cacheElements() {
    ["cards","compareBody","resultCount","topPick","recordCount","brandCount","sourceFile","construction","brand","search","sort","find","reset","mobileFilterToggle"].forEach(id => {
      els[id] = document.getElementById(id);
    });
  }

  function getBalls() { return window.GOLF_BALLS || []; }

  function bindControls() {
    document.querySelectorAll("[data-field][data-value]").forEach((button) => {
      button.addEventListener("click", () => {
        const field = button.dataset.field;
        state[field] = button.dataset.value;
        document.querySelectorAll(`[data-field="${field}"]`).forEach((b) => b.classList.toggle("active", b === button));
        render();
      });
    });

    els.construction.addEventListener("change", () => { state.construction = els.construction.value; render(); });
    els.brand.addEventListener("change", () => { state.brand = els.brand.value; render(); });
    els.search.addEventListener("input", () => { state.search = els.search.value.trim().toLowerCase(); render(); });
    els.sort.addEventListener("change", () => { state.sort = els.sort.value; render(); });
    els.find.addEventListener("click", () => {
      render();
      if (window.innerWidth <= 760) {
        document.body.classList.remove("controls-open");
        if (els.mobileFilterToggle) els.mobileFilterToggle.textContent = "Find Your Fit";
        document.querySelector(".results")?.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
    els.reset.addEventListener("click", resetFilters);

    if (els.mobileFilterToggle) {
      els.mobileFilterToggle.addEventListener("click", () => {
        const isOpen = document.body.classList.toggle("controls-open");
        els.mobileFilterToggle.textContent = isOpen ? "Hide Fit" : "Find Your Fit";
      });
    }
  }

  function resetFilters() {
    Object.assign(state, {
      swing: "not-sure", feel: "no-preference", cover: "balanced", budget: "no-preference",
      construction: "no-preference", brand: "all", search: "", sort: "score"
    });

    document.querySelectorAll("[data-field]").forEach((button) => {
      const isDefault =
        (button.dataset.field === "swing" && button.dataset.value === "not-sure") ||
        (button.dataset.field === "feel" && button.dataset.value === "no-preference") ||
        (button.dataset.field === "cover" && button.dataset.value === "balanced") ||
        (button.dataset.field === "budget" && button.dataset.value === "no-preference");
      button.classList.toggle("active", isDefault);
    });

    els.construction.value = "no-preference";
    els.brand.value = "all";
    els.search.value = "";
    els.sort.value = "score";
    render();
  }

  function populateBrandFilter() {
    const brands = [...new Set(getBalls().map((ball) => ball.brand).filter(Boolean))].sort((a, b) => a.localeCompare(b));
    els.brand.innerHTML = `<option value="all">All brands</option>` +
      brands.map((brand) => `<option value="${escapeHtml(brand)}">${escapeHtml(brand)}</option>`).join("");
  }

  function updateStats() {
    const balls = getBalls();
    const brands = new Set(balls.map((ball) => ball.brand).filter(Boolean));
    els.recordCount.textContent = balls.length || "—";
    els.brandCount.textContent = brands.size || "—";
    els.sourceFile.textContent = window.SOURCE_FILE || "golf-ball-guide__data.js";
  }

  function render() {
    const scored = getBalls()
      .filter(matchesFilters)
      .map((ball) => ({ ...ball, _score: scoreBall(ball), _price: getPrice(ball), _compression: getCompression(ball) }));

    sortBalls(scored);
    els.resultCount.textContent = scored.length;
    els.topPick.textContent = scored[0] ? ballName(scored[0]) : "—";
    renderCards(scored);
    renderCompare(scored.slice(0, 30));
  }

  function matchesFilters(ball) {
    if (state.brand !== "all" && ball.brand !== state.brand) return false;

    if (state.construction !== "no-preference") {
      const construction = normalize(ball.construction);
      const pieceCount = getPieceCount(ball);
      if (state.construction === "2-piece" && !(construction.includes("2") || pieceCount === 2)) return false;
      if (state.construction === "3-piece" && !(construction.includes("3") || pieceCount === 3)) return false;
      if (state.construction === "4-plus" && !(pieceCount >= 4 || construction.includes("4") || construction.includes("5") || construction.includes("tour"))) return false;
    }

    if (state.search) {
      const haystack = [ball.brand, ball.model, ball.cover, ball.construction, ball.notes, ball.retailers, ball.cost, ball.sourceUrl, ball.manufacturingCountry, ball.designOrigin, ball.companyOrigin, ball.productionLocation]
        .filter(Boolean).join(" ").toLowerCase();
      if (!haystack.includes(state.search)) return false;
    }

    return true;
  }

  function scoreBall(ball) {
    const compression = compressionFit(ball);
    const feel = feelFit(ball);
    const cover = coverFit(ball);
    const construction = constructionFit(ball);
    const cost = budgetFit(ball, state.budget);

    let raw = compression * WEIGHTS.compression + feel * WEIGHTS.feel + cover * WEIGHTS.cover + construction * WEIGHTS.construction + cost * WEIGHTS.cost;

    if (raw >= 98 && cost < 95) raw = 96;
    if (raw >= 92 && cost < 70) raw -= 3;

    return Math.max(0, Math.min(100, Math.round(raw * 10) / 10));
  }

  function compressionFit(ball) {
    const c = getCompression(ball);
    const raw = normalize(ball.compressionRaw || "");

    if (!c) {
      if (raw.includes("low") || raw.includes("soft")) return state.swing === "slow" ? 92 : 76;
      if (raw.includes("mid") || raw.includes("moderate")) return state.swing === "moderate" || state.swing === "not-sure" ? 88 : 78;
      if (raw.includes("high") || raw.includes("firm")) return state.swing === "fast" ? 92 : 72;
      return state.swing === "not-sure" ? 82 : 70;
    }

    if (state.swing === "slow") {
      if (c <= 55) return 100;
      if (c <= 70) return 92;
      if (c <= 85) return 76;
      return 58;
    }

    if (state.swing === "moderate") {
      if (c >= 60 && c <= 90) return 100;
      if (c >= 45 && c < 60) return 88;
      if (c > 90 && c <= 100) return 84;
      return 68;
    }

    if (state.swing === "fast") {
      if (c >= 85) return 100;
      if (c >= 70) return 90;
      if (c >= 55) return 72;
      return 58;
    }

    if (c >= 60 && c <= 95) return 90;
    if (c < 60) return 84;
    return 86;
  }

  function feelFit(ball) {
    if (state.feel === "no-preference") return 88;
    const c = getCompression(ball);
    const text = normalize(`${ball.compressionRaw || ""} ${ball.notes || ""} ${ball.model || ""}`);

    if (state.feel === "soft") {
      if (text.includes("soft")) return 100;
      if (c && c <= 65) return 96;
      if (c && c <= 80) return 82;
      return 66;
    }

    if (state.feel === "balanced") {
      if (text.includes("balanced") || text.includes("mid") || text.includes("moderate")) return 100;
      if (c && c >= 60 && c <= 90) return 94;
      return 82;
    }

    if (state.feel === "firm") {
      if (text.includes("firm")) return 100;
      if (c && c >= 85) return 96;
      if (c && c >= 70) return 84;
      return 68;
    }

    return 80;
  }

  function coverFit(ball) {
    const combined = normalize(`${ball.cover || ""} ${ball.notes || ""}`);
    const isUrethane = combined.includes("urethane");
    const isIonomer = combined.includes("ionomer") || combined.includes("surlyn") || combined.includes("durable");
    const isHybrid = combined.includes("hybrid");

    if (state.cover === "spin") {
      if (isUrethane) return 100;
      if (isHybrid) return 84;
      if (isIonomer) return 66;
      return 78;
    }

    if (state.cover === "durable") {
      if (isIonomer) return 100;
      if (isHybrid) return 92;
      if (isUrethane) return 76;
      return 82;
    }

    if (isHybrid) return 96;
    if (isUrethane || isIonomer) return 90;
    return 84;
  }

  function constructionFit(ball) {
    if (state.construction === "no-preference") return 88;
    const pieceCount = getPieceCount(ball);
    const construction = normalize(ball.construction);

    if (state.construction === "2-piece") return pieceCount === 2 || construction.includes("2") ? 100 : 72;
    if (state.construction === "3-piece") return pieceCount === 3 || construction.includes("3") ? 100 : 78;
    if (state.construction === "4-plus") return pieceCount >= 4 || construction.includes("4") || construction.includes("5") || construction.includes("tour") ? 100 : 76;
    return 80;
  }

  function baseCostScore(ball) {
    const price = getPrice(ball);
    if (price) {
      if (price < 25) return 100;
      if (price < 30) return 95;
      if (price < 35) return 88;
      if (price < 40) return 78;
      if (price < 45) return 68;
      if (price < 50) return 55;
      return 42;
    }

    const costText = normalize(ball.cost || "");
    if (costText.includes("value")) return 90;
    if (costText.includes("closeout")) return 82;
    if (costText.includes("premium")) return 48;
    if (costText.includes("varies")) return 68;
    return 70;
  }

  function budgetFit(ball, selectedBudget) {
    const price = getPrice(ball);
    let score = baseCostScore(ball);

    if (selectedBudget === "value") {
      if (price && price <= 30) score += 5;
      if (price && price > 40) score -= 20;
      if (price && price > 50) score -= 30;
    }

    if (selectedBudget === "mid") {
      if (price && price >= 30 && price <= 45) score += 5;
      if (price && price > 50) score -= 15;
      if (price && price < 25) score -= 4;
    }

    if (selectedBudget === "premium") {
      if (price && price >= 45) score += 5;
      if (price && price < 30) score -= 5;
    }

    return Math.max(0, Math.min(100, score));
  }

  function sortBalls(balls) {
    balls.sort((a, b) => {
      if (state.sort === "cost-low") return safeNumber(a._price, 999) - safeNumber(b._price, 999);
      if (state.sort === "cost-high") return safeNumber(b._price, -1) - safeNumber(a._price, -1);
      if (state.sort === "compression-low") return safeNumber(a._compression, 999) - safeNumber(b._compression, 999);
      if (state.sort === "compression-high") return safeNumber(b._compression, -1) - safeNumber(a._compression, -1);
      if (state.sort === "brand") return ballName(a).localeCompare(ballName(b));
      return b._score - a._score || safeNumber(a._price, 999) - safeNumber(b._price, 999) || ballName(a).localeCompare(ballName(b));
    });
  }

  function renderCards(balls) {
    if (!balls.length) {
      els.cards.innerHTML = `<div class="empty">No matches found. Try broadening your filters.</div>`;
      return;
    }

    els.cards.innerHTML = balls.slice(0, 24).map((ball) => `
      <article class="ball-card">
        <div class="card-top">
          <div>
            <h3>${escapeHtml(ball.brand || "Unknown brand")}</h3>
            <p>${escapeHtml(ball.model || "Unknown model")}</p>
          </div>
          <div class="score">${Math.round(ball._score)}</div>
        </div>
        <div class="pill-row">
          <span>Compression: ${escapeHtml(ball.compressionRaw || String(getCompression(ball) || "—"))}</span>
          <span>${escapeHtml(ball.construction || "—")}</span>
          <span>${escapeHtml(ball.cover || "—")}</span>
          <span>${escapeHtml(ball.cost || formatPrice(getPrice(ball)))}</span>
          <span>Made: ${escapeHtml(ball.manufacturingCountry || "—")}</span>
        </div>
        ${ball.productionLocation ? `<p class="production"><b>Production:</b> ${escapeHtml(ball.productionLocation)}</p>` : ""}
        ${ball.designOrigin ? `<p class="production"><b>Design origin:</b> ${escapeHtml(ball.designOrigin)}</p>` : ""}
        ${ball.productionConfidence ? `<p class="production"><b>Production confidence:</b> ${escapeHtml(ball.productionConfidence)}</p>` : ""}
        ${ball.retailers ? `<p class="retailers"><b>Retailers:</b> ${escapeHtml(ball.retailers)}</p>` : ""}
        ${ball.notes ? `<p class="notes">${escapeHtml(ball.notes)}</p>` : ""}
        ${ball.sourceUrl ? `<p class="source"><a href="${escapeHtml(ball.sourceUrl)}" target="_blank" rel="noopener">Source</a></p>` : ""}
      </article>
    `).join("");
  }

  function renderCompare(balls) {
    els.compareBody.innerHTML = balls.map((ball) => `
      <tr>
        <td>${escapeHtml(ballName(ball))}</td>
        <td>${Math.round(ball._score)}</td>
        <td>${escapeHtml(ball.compressionRaw || String(getCompression(ball) || "—"))}</td>
        <td>${escapeHtml(ball.construction || "—")}</td>
        <td>${escapeHtml(ball.cover || "—")}</td>
        <td>${escapeHtml(ball.cost || formatPrice(getPrice(ball)))}</td>
        <td>${escapeHtml(ball.manufacturingCountry || "—")}</td>
        <td>${escapeHtml(ball.designOrigin || "—")}</td>
        <td>${escapeHtml(ball.productionConfidence || "—")}</td>
        <td>${escapeHtml(ball.retailers || "")}</td>
        <td>${escapeHtml(ball.notes || "")}</td>
      </tr>
    `).join("");
  }

  function ballName(ball) { return [ball.brand, ball.model].filter(Boolean).join(" ") || "Unknown ball"; }

  function getPrice(ball) {
    const value = ball.price ?? ball.cost;
    if (value === null || value === undefined || value === "") return null;
    if (typeof value === "number") return Number.isFinite(value) ? value : null;
    const match = String(value).match(/\$?\s*(\d+(?:\.\d+)?)/);
    return match ? parseFloat(match[1]) : null;
  }

  function getCompression(ball) {
    const value = ball.compression ?? ball.compressionRaw;
    if (value === null || value === undefined || value === "") return null;
    if (typeof value === "number") return Number.isFinite(value) ? value : null;
    const nums = String(value).match(/\d+(?:\.\d+)?/g);
    if (!nums) return null;
    const vals = nums.map(Number);
    return vals.reduce((a, b) => a + b, 0) / vals.length;
  }

  function getPieceCount(ball) {
    const raw = ball.pieces ?? ball.pieceCount ?? ball.construction;
    const match = String(raw || "").match(/\d+/);
    return match ? parseInt(match[0], 10) : null;
  }

  function formatPrice(price) { return price ? `$${price.toFixed(2)}` : "—"; }
  function safeNumber(value, fallback) { return Number.isFinite(value) ? value : fallback; }
  function normalize(value) { return String(value || "").toLowerCase().trim(); }

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  document.addEventListener("DOMContentLoaded", init);
})();
