
(() => {
  "use strict";

  const BUYERS_GUIDE_URL = "https://vincentaffatati-19.github.io/GAL-Buyers-Guide-v720a/";
  const SHARED_DATA_PATHS = [
    "./golf-ball-guide__data.js"
  ];

  const $ = (id) => document.getElementById(id);
  const currency = new Intl.NumberFormat("en-US", {style:"currency", currency:"USD"});
  const number = new Intl.NumberFormat("en-US", {maximumFractionDigits:2});

  let dataSource = "review";
  let balls = [];
  let selectedBall = null;
  const defaults = {
    rounds:30, startingInventory:0, lostPerRound:2, retiredPerRound:.25,
    taxRate:0, shipping:0, improvedLossRate:1, packageQuantity:12
  };

  function normalizeBall(ball) {
    const price = Number(ball.parsedPrice ?? ball.price);
    return {
      ...ball,
      id: ball.id ?? `${ball.brand}-${ball.model}`.toLowerCase().replace(/[^a-z0-9]+/g,"-"),
      brand: ball.brand || "Unknown",
      model: ball.model || "Unknown model",
      parsedPrice: Number.isFinite(price) ? price : null,
      compression: ball.compression ?? null,
      construction: ball.construction || "Not published",
      cover: ball.cover || "Not published",
      dataConfidence: ball.dataConfidence || "Not stated",
      lastVerified: ball.lastVerified || "",
      sourceUrl: ball.sourceUrl || ""
    };
  }

  function getSharedBalls() {
    const source = window.GOLF_BALLS || window.GOLF_BALL_DATA || window.golfBallData;
    return Array.isArray(source) ? source : null;
  }

  function loadScript(src) {
    return new Promise(resolve => {
      const script = document.createElement("script");
      script.src = src;
      script.onload = () => resolve(true);
      script.onerror = () => { script.remove(); resolve(false); };
      document.head.appendChild(script);
    });
  }

  async function loadData() {
    let shared = getSharedBalls();
    if (!shared) {
      for (const path of SHARED_DATA_PATHS) {
        await loadScript(path);
        shared = getSharedBalls();
        if (shared) break;
      }
    }

    if (shared && shared.length) {
      balls = shared.map(normalizeBall).filter(b => b.parsedPrice != null);
      dataSource = "shared";
    } else {
      balls = (window.GAL_COST_REVIEW_FALLBACK || []).map(normalizeBall).filter(b => b.parsedPrice != null);
      dataSource = "review";
    }

    balls.sort((a,b) => a.brand.localeCompare(b.brand) || a.model.localeCompare(b.model));
    renderDataNotice();
  }

  function renderDataNotice() {
    $("dataNotice").innerHTML = dataSource === "shared"
      ? `<strong>Shared database connected.</strong> Loaded ${balls.length} priced records from the same GAL Buyers Guide data globals.`
      : `<strong>Review mode.</strong> Loaded ${balls.length} representative records using the Buyers Guide v3 schema. When deployed beside the guide, the tool automatically loads the full shared <code>data.js</code>.`;
  }

  function option(ball) {
    return `<option value="${String(ball.id)}">${escapeHtml(ball.brand)} — ${escapeHtml(ball.model)}</option>`;
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  }

  function byId(id) {
    return balls.find(b => String(b.id) === String(id));
  }

  function initSelectors() {
    const brands = [...new Set(balls.map(b => b.brand))].sort();
    $("brandSelect").innerHTML = `<option value="all">All brands</option>` + brands.map(b => `<option>${escapeHtml(b)}</option>`).join("");

    const allOptions = balls.map(option).join("");
    ["compareA","compareB","compareC"].forEach(id => $(id).innerHTML = allOptions);

    const defaultBall = balls.find(b => b.brand === "Titleist" && b.model === "Pro V1") || balls[0];
    $("brandSelect").value = defaultBall.brand;
    populateBallSelect(defaultBall.id);

    const candidates = [
      defaultBall,
      balls.find(b => b.brand === "Callaway" && b.model === "Supersoft"),
      balls.find(b => b.brand === "TaylorMade" && b.model === "Tour Response")
    ].filter(Boolean);

    $("compareA").value = String(candidates[0]?.id ?? balls[0].id);
    $("compareB").value = String(candidates[1]?.id ?? balls[Math.min(1,balls.length-1)].id);
    $("compareC").value = String(candidates[2]?.id ?? balls[Math.min(2,balls.length-1)].id);

    const params = new URLSearchParams(location.search);
    const requested = params.get("ball");
    const match = requested ? byId(requested) : null;
    selectBall(match || defaultBall);
  }

  function populateBallSelect(preferredId) {
    const brand = $("brandSelect").value;
    const filtered = brand === "all" ? balls : balls.filter(b => b.brand === brand);
    $("ballSelect").innerHTML = filtered.map(option).join("");
    if (preferredId && filtered.some(b => String(b.id) === String(preferredId))) {
      $("ballSelect").value = String(preferredId);
    }
  }

  function selectBall(ball) {
    if (!ball) return;
    selectedBall = ball;
    $("brandSelect").value = ball.brand;
    populateBallSelect(ball.id);
    $("ballSelect").value = String(ball.id);
    $("packagePrice").value = ball.parsedPrice.toFixed(2);
    $("packageQuantity").value = defaults.packageQuantity;
    renderBallSummary();
    calculate();
  }

  function renderBallSummary() {
    const compression = selectedBall.compression == null ? "Not published" : selectedBall.compression;
    $("ballSummary").innerHTML = `
      <div>
        <h3>${escapeHtml(selectedBall.brand)} ${escapeHtml(selectedBall.model)}</h3>
        <p>${escapeHtml(selectedBall.construction)} · ${escapeHtml(selectedBall.cover)} · Compression ${escapeHtml(compression)}</p>
        <p>Database confidence: ${escapeHtml(selectedBall.dataConfidence)}${selectedBall.lastVerified ? ` · Verified ${escapeHtml(selectedBall.lastVerified)}` : ""}</p>
      </div>
      <div class="price">${currency.format(selectedBall.parsedPrice)}<small style="display:block;font-size:11px;color:#718096">reference package price</small></div>`;
  }

  function inputNumber(id, fallback=0) {
    const value = Number($(id).value);
    return Number.isFinite(value) ? value : fallback;
  }

  function assumptions(customBall=null) {
    const ball = customBall || selectedBall;
    return {
      packagePrice: customBall ? Number(ball.parsedPrice) : inputNumber("packagePrice"),
      packageQuantity: inputNumber("packageQuantity",12),
      rounds: inputNumber("rounds"),
      lostPerRound: inputNumber("lostPerRound"),
      retiredPerRound: inputNumber("retiredPerRound"),
      startingInventory: inputNumber("startingInventory"),
      taxRate: inputNumber("taxRate"),
      shipping: inputNumber("shipping"),
      improvedLossRate: inputNumber("improvedLossRate")
    };
  }

  function calculateCost(a) {
    const pricePerBall = a.packageQuantity > 0 ? a.packagePrice / a.packageQuantity : 0;
    const lostBalls = Math.max(0, a.rounds * a.lostPerRound);
    const retiredBalls = Math.max(0, a.rounds * a.retiredPerRound);
    const ballsConsumed = lostBalls + retiredBalls;
    const ballsToPurchase = Math.max(0, ballsConsumed - a.startingInventory);
    const packagesRequired = a.packageQuantity > 0 ? Math.ceil(ballsToPurchase / a.packageQuantity) : 0;
    const purchaseSubtotal = packagesRequired * a.packagePrice;
    const tax = purchaseSubtotal * Math.max(0,a.taxRate) / 100;
    const cashOutlay = purchaseSubtotal + tax + Math.max(0,a.shipping);
    const endingInventory = a.startingInventory + packagesRequired * a.packageQuantity - ballsConsumed;
    const lostBallCost = lostBalls * pricePerBall;
    const wearCost = retiredBalls * pricePerBall;
    const economicCost = lostBallCost + wearCost;
    const improvement = Math.max(0, a.lostPerRound - a.improvedLossRate) * a.rounds * pricePerBall;
    return {
      pricePerBall,lostBalls,retiredBalls,ballsConsumed,packagesRequired,
      purchaseSubtotal,tax,cashOutlay,endingInventory,lostBallCost,wearCost,
      economicCost,fees:tax+Math.max(0,a.shipping),improvement,
      economicPerRound:a.rounds>0?economicCost/a.rounds:0,
      cashPerRound:a.rounds>0?cashOutlay/a.rounds:0
    };
  }

  function calculate() {
    if (!selectedBall) return;
    const a = assumptions();
    const r = calculateCost(a);

    $("pricePerBall").textContent = currency.format(r.pricePerBall);
    $("resultBallName").textContent = `${selectedBall.brand} ${selectedBall.model}`;
    $("confidenceBadge").textContent = `${selectedBall.dataConfidence} confidence`;
    $("economicCost").textContent = currency.format(r.economicCost);
    $("economicPerRound").textContent = `${currency.format(r.economicPerRound)} per round`;
    $("cashOutlay").textContent = currency.format(r.cashOutlay);
    $("packagesRequired").textContent = number.format(r.packagesRequired);
    $("ballsConsumed").textContent = number.format(r.ballsConsumed);
    $("endingInventory").textContent = number.format(r.endingInventory);
    $("lostBallCost").textContent = currency.format(r.lostBallCost);
    $("wearCost").textContent = currency.format(r.wearCost);
    $("feesCost").textContent = currency.format(r.fees);
    const totalBreakdown = Math.max(r.economicCost,1);
    $("lostBar").style.width = `${Math.min(100,r.lostBallCost/totalBreakdown*100)}%`;
    $("wearBar").style.width = `${Math.min(100,r.wearCost/totalBreakdown*100)}%`;
    $("improvementSavings").textContent = `${currency.format(r.improvement)} potential savings`;
    $("improvementText").textContent = `Reducing losses from ${a.lostPerRound.toFixed(2)} to ${Math.max(0,a.improvedLossRate).toFixed(2)} ball per round.`;
    $("lostValue").textContent = a.lostPerRound.toFixed(2);
    $("retiredValue").textContent = a.retiredPerRound.toFixed(2);

    const guide = new URL(BUYERS_GUIDE_URL);
    guide.searchParams.set("ball", selectedBall.id);
    $("buyersGuideButton").href = guide.toString();

    updateComparison();
  }

  function updateComparison() {
    const rows = ["compareA","compareB","compareC"].map(id => byId($(id).value)).filter(Boolean);
    const results = rows.map(ball => ({ball, result:calculateCost(assumptions(ball))}));
    $("comparisonBody").innerHTML = results.map(({ball,result}) => `
      <tr>
        <td><strong>${escapeHtml(ball.brand)} ${escapeHtml(ball.model)}</strong><small>${escapeHtml(ball.cover)}</small></td>
        <td>${currency.format(result.pricePerBall)}</td>
        <td>${currency.format(result.economicCost)}</td>
        <td>${currency.format(result.cashOutlay)}</td>
        <td>${currency.format(result.economicPerRound)}</td>
        <td>${number.format(result.packagesRequired)}</td>
      </tr>`).join("");

    const max = Math.max(...results.map(x=>x.result.economicCost),1);
    $("comparisonBars").innerHTML = results.map(({ball,result}) => `
      <div class="compare-bar">
        <span>${escapeHtml(ball.brand)} ${escapeHtml(ball.model)}</span>
        <div class="track"><i style="width:${result.economicCost/max*100}%"></i></div>
        <strong>${currency.format(result.economicCost)}</strong>
      </div>`).join("");
  }

  function reset() {
    $("rounds").value = defaults.rounds;
    $("startingInventory").value = defaults.startingInventory;
    $("lostPerRound").value = defaults.lostPerRound;
    $("retiredPerRound").value = defaults.retiredPerRound;
    $("taxRate").value = defaults.taxRate;
    $("shipping").value = defaults.shipping;
    $("improvedLossRate").value = defaults.improvedLossRate;
    $("packageQuantity").value = defaults.packageQuantity;
    $("packagePrice").value = selectedBall.parsedPrice.toFixed(2);
    calculate();
  }

  async function copySummary() {
    const a = assumptions();
    const r = calculateCost(a);
    const text = [
      `GAL Golf Ball Cost-of-Play Calculator`,
      `${selectedBall.brand} ${selectedBall.model}`,
      `Reference package price: ${currency.format(a.packagePrice)} for ${a.packageQuantity} balls`,
      `Rounds: ${a.rounds}`,
      `Balls lost per round: ${a.lostPerRound}`,
      `Balls retired per round: ${a.retiredPerRound}`,
      `Economic consumption cost: ${currency.format(r.economicCost)}`,
      `Cash outlay: ${currency.format(r.cashOutlay)}`,
      `Economic cost per round: ${currency.format(r.economicPerRound)}`,
      `Packages required: ${r.packagesRequired}`,
      `Ending inventory: ${number.format(r.endingInventory)}`
    ].join("\n");
    try {
      await navigator.clipboard.writeText(text);
      $("copyButton").textContent = "Copied";
      setTimeout(()=>$("copyButton").textContent="Copy summary",1200);
    } catch {
      window.prompt("Copy this summary:",text);
    }
  }

  function bind() {
    $("brandSelect").addEventListener("change", () => {
      populateBallSelect();
      selectBall(byId($("ballSelect").value));
    });
    $("ballSelect").addEventListener("change", () => selectBall(byId($("ballSelect").value)));
    ["packagePrice","packageQuantity","rounds","startingInventory","lostPerRound","retiredPerRound","taxRate","shipping","improvedLossRate"]
      .forEach(id => $(id).addEventListener("input",calculate));
    ["compareA","compareB","compareC"].forEach(id => $(id).addEventListener("change",updateComparison));
    $("resetButton").addEventListener("click",reset);
    $("copyButton").addEventListener("click",copySummary);
  }

  async function start() {
    await loadData();
    initSelectors();
    bind();
    calculate();
  }

  start();
})();
