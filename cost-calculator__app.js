
(() => {
  "use strict";

  const BUYERS_GUIDE_URL = "https://vincentaffatati-19.github.io/GAL-Buyers-Guide-v720a/";
  const balls = Array.isArray(window.GOLF_BALLS) ? window.GOLF_BALLS :
                Array.isArray(window.GOLF_BALL_DATA) ? window.GOLF_BALL_DATA : [];
  const meta = window.GOLF_BALL_META || {};

  const $ = id => document.getElementById(id);
  const currency = new Intl.NumberFormat("en-US", {style:"currency",currency:"USD"});
  const number = new Intl.NumberFormat("en-US", {maximumFractionDigits:2});
  const defaults = {
    rounds:30, startingInventory:0, lostPerRound:2, retiredPerRound:.25,
    taxRate:0, shipping:0, improvedLossRate:1
  };
  let selectedBall = null;
  let selectedPackage = null;

  function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, c => ({
      "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
    })[c]);
  }

  function validPrice(value) {
    return value !== null && value !== undefined &&
      Number.isFinite(Number(value)) && Number(value) > 0;
  }

  function byId(id) {
    return balls.find(ball => String(ball.id) === String(id));
  }

  function explicitPackageFromCost(cost) {
    const text = String(cost || "");
    const match = text.match(/(?:^|[\s;(])~?\$([0-9]+(?:\.[0-9]{1,2})?)\s*\/\s*(\d+)\s*[- ]?(?:pack|ball(?:s)?)/i);
    if (!match) return null;
    const price = Number(match[1]);
    const quantity = Number(match[2]);
    if (!Number.isFinite(price) || !Number.isFinite(quantity) || price <= 0 || quantity <= 0) return null;
    return {price, quantity, basis:`Exact package parsed from database cost: ${currency.format(price)} / ${quantity} balls`, exact:true};
  }

  function inferPackage(ball) {
    const explicit = explicitPackageFromCost(ball.cost);
    if (explicit) return explicit;
    if (validPrice(ball.parsedPrice)) {
      return {
        price:Number(ball.parsedPrice),
        quantity:12,
        basis:"Database dozen-equivalent reference; edit when the retail pack differs from 12 balls.",
        exact:false
      };
    }
    return {
      price:0,
      quantity:12,
      basis:"No usable database price. Enter the actual package price and quantity.",
      exact:false
    };
  }

  function option(ball, includePriceState=true) {
    const suffix = includePriceState && !validPrice(ball.parsedPrice) && !explicitPackageFromCost(ball.cost)
      ? " — price needed" : "";
    return `<option value="${esc(ball.id)}">${esc(ball.brand)} — ${esc(ball.model)}${suffix}</option>`;
  }

  function init() {
    if (!balls.length) {
      $("dataNotice").innerHTML = "<strong>Database unavailable.</strong> Confirm that data.js loads before cost-calculator.js.";
      return;
    }

    const brands = [...new Set(balls.map(b => b.brand).filter(Boolean))].sort((a,b)=>a.localeCompare(b));
    $("brandSelect").innerHTML = `<option value="all">All brands</option>` +
      brands.map(brand => `<option value="${esc(brand)}">${esc(brand)}</option>`).join("");

    const comparisonBalls = balls.filter(b => validPrice(b.parsedPrice) || explicitPackageFromCost(b.cost));
    const comparisonOptions = comparisonBalls.map(option).join("");
    $("compareA").innerHTML = comparisonOptions;
    $("compareB").innerHTML = comparisonOptions;
    $("compareC").innerHTML = comparisonOptions;

    const source = meta.sourceFile || "attached golf-ball database";
    $("dataNotice").innerHTML =
      `<strong>Correct shared database connected.</strong> ${esc(source)} · ` +
      `${esc(meta.recordCount ?? balls.length)} records · ${esc(meta.brandCount ?? brands.length)} brands · ` +
      `generated ${esc(meta.generatedOn || "date not listed")}.`;

    const params = new URLSearchParams(location.search);
    const requested = params.get("ball");
    const defaultBall = byId(requested) ||
      balls.find(b => b.brand === "Titleist" && b.model === "Pro V1") ||
      balls[0];

    $("brandSelect").value = defaultBall.brand;
    populateBallSelect(defaultBall.id);
    setBall(defaultBall);

    const picks = [
      defaultBall,
      balls.find(b => b.brand === "Callaway" && b.model === "Supersoft"),
      balls.find(b => b.brand === "Kirkland Signature" && b.model === "Performance+ V3.0")
    ].filter(b => b && (validPrice(b.parsedPrice) || explicitPackageFromCost(b.cost)));

    $("compareA").value = String((picks[0] || comparisonBalls[0]).id);
    $("compareB").value = String((picks[1] || comparisonBalls[1] || comparisonBalls[0]).id);
    $("compareC").value = String((picks[2] || comparisonBalls[2] || comparisonBalls[0]).id);

    bind();
    calculate();
  }

  function populateBallSelect(preferredId) {
    const brand = $("brandSelect").value;
    const filtered = brand === "all" ? balls : balls.filter(b => b.brand === brand);
    $("ballSelect").innerHTML = filtered.map(option).join("");
    if (preferredId !== undefined && filtered.some(b => String(b.id) === String(preferredId))) {
      $("ballSelect").value = String(preferredId);
    }
  }

  function setBall(ball) {
    if (!ball) return;
    selectedBall = ball;
    selectedPackage = inferPackage(ball);
    $("brandSelect").value = ball.brand;
    populateBallSelect(ball.id);
    $("ballSelect").value = String(ball.id);
    $("packagePrice").value = selectedPackage.price ? selectedPackage.price.toFixed(2) : "";
    $("packageQuantity").value = selectedPackage.quantity;
    renderBallSummary();
    calculate();
  }

  function renderBallSummary() {
    const compression = selectedBall.compression !== null && selectedBall.compression !== undefined
      ? selectedBall.compression
      : (selectedBall.compressionRaw || "Not published");
    const priceLabel = selectedPackage.price ? currency.format(selectedPackage.price) : "Enter price";
    const audience = selectedBall.productAudience || "Unisex";
    const status = selectedBall.linkStatus || "Status not listed";

    $("ballSummary").innerHTML = `
      <div class="ball-summary-head">
        <div>
          <h3>${esc(selectedBall.brand)} ${esc(selectedBall.model)}</h3>
          <p>${esc(selectedBall.cost || "Retail price not listed")}</p>
          <p>${esc(selectedBall.retailers || "Retailers not listed")}</p>
        </div>
        <div class="db-price">${priceLabel}<small style="display:block;font-size:11px;color:#718096">${selectedPackage.quantity}-ball basis</small></div>
      </div>
      <div class="detail-grid">
        <div class="detail"><b>Compression</b>${esc(compression)}</div>
        <div class="detail"><b>Construction</b>${esc(selectedBall.construction || "Not published")}</div>
        <div class="detail"><b>Cover</b>${esc(selectedBall.cover || "Not published")}</div>
        <div class="detail"><b>Audience / status</b>${esc(audience)} · ${esc(status)}</div>
      </div>`;
    $("priceBasis").textContent = selectedPackage.basis;

    const unavailable = selectedBall.recommendationEligible === false ||
      /sold out|unavailable|prototype|future/i.test(String(selectedBall.linkStatus || ""));
    $("availabilityNotice").hidden = !unavailable;
    $("availabilityNotice").textContent = unavailable
      ? `Database caution: ${selectedBall.linkStatus || "This record is not recommended for ordinary retail selection."}`
      : "";

    $("productSourceButton").hidden = !selectedBall.sourceUrl;
    if (selectedBall.sourceUrl) $("productSourceButton").href = selectedBall.sourceUrl;
  }

  function value(id, fallback=0) {
    const result = Number($(id).value);
    return Number.isFinite(result) ? result : fallback;
  }

  function currentAssumptions(customBall=null) {
    let packageInfo;
    if (customBall && selectedBall && String(customBall.id) === String(selectedBall.id)) {
      packageInfo = {price:value("packagePrice"), quantity:value("packageQuantity",12)};
    } else if (customBall) {
      packageInfo = inferPackage(customBall);
    } else {
      packageInfo = {price:value("packagePrice"), quantity:value("packageQuantity",12)};
    }
    return {
      packagePrice:Math.max(0,packageInfo.price || 0),
      packageQuantity:Math.max(1,packageInfo.quantity || 12),
      rounds:Math.max(0,value("rounds")),
      lostPerRound:Math.max(0,value("lostPerRound")),
      retiredPerRound:Math.max(0,value("retiredPerRound")),
      startingInventory:Math.max(0,value("startingInventory")),
      taxRate:Math.max(0,value("taxRate")),
      shipping:Math.max(0,value("shipping")),
      improvedLossRate:Math.max(0,value("improvedLossRate"))
    };
  }

  function compute(a) {
    const pricePerBall = a.packagePrice / a.packageQuantity;
    const lostBalls = a.rounds * a.lostPerRound;
    const retiredBalls = a.rounds * a.retiredPerRound;
    const ballsConsumed = lostBalls + retiredBalls;
    const ballsToPurchase = Math.max(0, ballsConsumed - a.startingInventory);
    const packagesRequired = Math.ceil(ballsToPurchase / a.packageQuantity);
    const subtotal = packagesRequired * a.packagePrice;
    const tax = subtotal * a.taxRate / 100;
    const fees = tax + a.shipping;
    const cashOutlay = subtotal + fees;
    const endingInventory = a.startingInventory + packagesRequired * a.packageQuantity - ballsConsumed;
    const lostBallCost = lostBalls * pricePerBall;
    const wearCost = retiredBalls * pricePerBall;
    const economicCost = lostBallCost + wearCost;
    const improvement = Math.max(0,a.lostPerRound-a.improvedLossRate) * a.rounds * pricePerBall;
    return {
      pricePerBall,lostBalls,retiredBalls,ballsConsumed,packagesRequired,subtotal,tax,fees,
      cashOutlay,endingInventory,lostBallCost,wearCost,economicCost,improvement,
      economicPerRound:a.rounds ? economicCost/a.rounds : 0
    };
  }

  function calculate() {
    if (!selectedBall) return;
    const a = currentAssumptions();
    const r = compute(a);

    $("pricePerBall").textContent = currency.format(r.pricePerBall);
    $("resultBallName").textContent = `${selectedBall.brand} ${selectedBall.model}`;
    $("confidenceBadge").textContent = `${selectedBall.dataConfidence || "Unrated"} confidence`;
    $("economicCost").textContent = currency.format(r.economicCost);
    $("economicPerRound").textContent = `${currency.format(r.economicPerRound)} per round`;
    $("cashOutlay").textContent = currency.format(r.cashOutlay);
    $("packagesRequired").textContent = number.format(r.packagesRequired);
    $("ballsConsumed").textContent = number.format(r.ballsConsumed);
    $("endingInventory").textContent = number.format(r.endingInventory);
    $("lostBallCost").textContent = currency.format(r.lostBallCost);
    $("wearCost").textContent = currency.format(r.wearCost);
    $("feesCost").textContent = currency.format(r.fees);
    const total = Math.max(r.economicCost,1);
    $("lostBar").style.width = `${Math.min(100,r.lostBallCost/total*100)}%`;
    $("wearBar").style.width = `${Math.min(100,r.wearCost/total*100)}%`;
    $("improvementSavings").textContent = `${currency.format(r.improvement)} potential savings`;
    $("improvementText").textContent =
      `Reducing losses from ${a.lostPerRound.toFixed(2)} to ${a.improvedLossRate.toFixed(2)} ball per round.`;
    $("lostValue").textContent = a.lostPerRound.toFixed(2);
    $("retiredValue").textContent = a.retiredPerRound.toFixed(2);

    const guide = new URL(BUYERS_GUIDE_URL);
    guide.searchParams.set("ball", selectedBall.id);
    $("buyersGuideButton").href = guide.toString();

    updateComparison();
  }

  function updateComparison() {
    const chosen = ["compareA","compareB","compareC"].map(id => byId($(id).value)).filter(Boolean);
    const rows = chosen.map(ball => {
      const packageInfo = String(ball.id) === String(selectedBall.id)
        ? {price:value("packagePrice"), quantity:value("packageQuantity",12), basis:"Custom selected price"}
        : inferPackage(ball);
      const a = currentAssumptions(ball);
      const result = compute(a);
      return {ball,packageInfo,result};
    });

    $("comparisonBody").innerHTML = rows.map(({ball,packageInfo,result}) => `
      <tr>
        <td><strong>${esc(ball.brand)} ${esc(ball.model)}</strong><small>${esc(ball.cover || "")}</small></td>
        <td>${currency.format(packageInfo.price)} / ${packageInfo.quantity}</td>
        <td>${currency.format(result.pricePerBall)}</td>
        <td>${currency.format(result.economicCost)}</td>
        <td>${currency.format(result.cashOutlay)}</td>
        <td>${currency.format(result.economicPerRound)}</td>
      </tr>`).join("");

    const max = Math.max(...rows.map(row=>row.result.economicCost),1);
    $("comparisonBars").innerHTML = rows.map(({ball,result}) => `
      <div class="compare-bar">
        <span>${esc(ball.brand)} ${esc(ball.model)}</span>
        <div class="track"><i style="width:${result.economicCost/max*100}%"></i></div>
        <strong>${currency.format(result.economicCost)}</strong>
      </div>`).join("");
  }

  function reset() {
    const info = inferPackage(selectedBall);
    $("packagePrice").value = info.price ? info.price.toFixed(2) : "";
    $("packageQuantity").value = info.quantity;
    $("rounds").value = defaults.rounds;
    $("startingInventory").value = defaults.startingInventory;
    $("lostPerRound").value = defaults.lostPerRound;
    $("retiredPerRound").value = defaults.retiredPerRound;
    $("taxRate").value = defaults.taxRate;
    $("shipping").value = defaults.shipping;
    $("improvedLossRate").value = defaults.improvedLossRate;
    $("priceBasis").textContent = info.basis;
    calculate();
  }

  async function copySummary() {
    const a = currentAssumptions();
    const r = compute(a);
    const summary = [
      "GAL Golf Ball Cost-of-Play Calculator",
      `${selectedBall.brand} ${selectedBall.model}`,
      `Package: ${currency.format(a.packagePrice)} for ${a.packageQuantity} balls`,
      `Rounds: ${a.rounds}`,
      `Balls lost per round: ${a.lostPerRound}`,
      `Balls retired per round: ${a.retiredPerRound}`,
      `Economic cost: ${currency.format(r.economicCost)}`,
      `Cash outlay: ${currency.format(r.cashOutlay)}`,
      `Economic cost per round: ${currency.format(r.economicPerRound)}`,
      `Packages required: ${r.packagesRequired}`,
      `Ending inventory: ${number.format(r.endingInventory)}`
    ].join("\n");
    try {
      await navigator.clipboard.writeText(summary);
      $("copyButton").textContent = "Copied";
      setTimeout(()=>$("copyButton").textContent="Copy summary",1200);
    } catch {
      window.prompt("Copy this summary:", summary);
    }
  }

  function bind() {
    $("brandSelect").addEventListener("change", () => {
      populateBallSelect();
      setBall(byId($("ballSelect").value));
    });
    $("ballSelect").addEventListener("change", () => setBall(byId($("ballSelect").value)));
    ["packagePrice","packageQuantity","rounds","startingInventory","lostPerRound",
     "retiredPerRound","taxRate","shipping","improvedLossRate"]
      .forEach(id => $(id).addEventListener("input", calculate));
    ["compareA","compareB","compareC"].forEach(id => $(id).addEventListener("change", updateComparison));
    $("resetButton").addEventListener("click", reset);
    $("copyButton").addEventListener("click", copySummary);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, {once:true});
  } else {
    init();
  }
})();
