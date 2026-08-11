


(function () {
  "use strict";

  const DATA = Array.isArray(window.GAL_IRONS) ? window.GAL_IRONS : [];
  const selected = new Set();
  let visible = 9;

  const state = {
    audience: null,
    strike: null,
    goal: null,
    flight: null,
    look: null,
    budget: null,
    brand: "all",
    sort: "fit"
  };

  const QUESTIONS = [
    {id:"audience", title:"Who are you shopping for?", why:"Women see women-specific and appropriate unisex models.", options:[
      ["men","Men / unisex","Show standard and unisex models"],
      ["women","Women","Include women-specific and unisex models"]
    ]},
    {id:"strike", title:"How consistently do you strike your irons?", why:"Strike consistency is a more practical forgiveness clue than handicap alone.", options:[
      ["often-miss","I miss the center often","Give me more help across the face"],
      ["mixed","Mixed","Some centered strikes, some misses"],
      ["consistent","Usually centered","Contact is a strength"],
      ["not-sure","Not sure","Keep the recommendation broad"]
    ]},
    {id:"goal", title:"What do you want most from your next irons?", why:"Choose the improvement you would notice most on the course.", options:[
      ["help","Easier golf","Forgiveness and confidence"],
      ["distance","More distance","Create more useful carry"],
      ["balanced","A little of everything","Help, distance and control"],
      ["control","Control & feel","Predictable flight and player shaping"]
    ]},
    {id:"flight", title:"What does your normal iron flight look like?", why:"This prevents a stronger loft from being mistaken automatically for a better fit.", options:[
      ["low","Low / hard to hold greens","I need more usable height"],
      ["medium","Medium","No major height problem"],
      ["high","High","Height comes easily"],
      ["not-sure","Not sure","Do not make a flight assumption"]
    ]},
    {id:"look", title:"What gives you confidence at address?", why:"Visual confidence matters when narrowing the field.", options:[
      ["larger","A larger, reassuring head","More visual help is okay"],
      ["neutral","Something in the middle","Neither very large nor very compact"],
      ["compact","A compact player look","Cleaner shape / less offset"],
      ["not-sure","No strong preference","Let testing decide"]
    ]},
    {id:"budget", title:"How important is price?", why:"Where published, GAL compares price per iron rather than only set price.", options:[
      ["value","Value matters","Prefer roughly under $150 per iron"],
      ["middle","Mid-market is fine","Roughly $150–$225 per iron"],
      ["premium","Premium is okay","Pay more for the right fit"],
      ["open","Keep price out of it","Rank fit before price"]
    ]}
  ];

  function byId(id) { return document.getElementById(id); }
  function all(sel) {
    const root = document.querySelector(".irons-guide");
    return root ? Array.prototype.slice.call(root.querySelectorAll(sel)) : [];
  }
  function num(v) {
    if (v === null || v === undefined || v === "") return null;
    const x = Number(v);
    return Number.isFinite(x) ? x : null;
  }
  function esc(v) {
    return String(v == null ? "" : v).replace(/[&<>"']/g, function(c) {
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }
  function money(v) {
    const x = num(v);
    return x === null ? "—" : "$" + Math.round(x).toLocaleString();
  }
  function segmentAdd(segment, map) { return Object.prototype.hasOwnProperty.call(map, segment) ? map[segment] : 0; }

  function buildQuestions() {
    const root = byId("questions");
    if (!root) return;
    root.innerHTML = QUESTIONS.map(function(q, idx) {
      return '<article class="question">' +
        '<div class="qnum">QUESTION ' + (idx + 1) + '</div>' +
        '<h3>' + esc(q.title) + '</h3>' +
        '<p class="why">' + esc(q.why) + '</p>' +
        '<div class="options">' +
        q.options.map(function(o) {
          return '<button type="button" class="option" data-q="' + esc(q.id) + '" data-v="' + esc(o[0]) + '">' +
            esc(o[1]) + '<small>' + esc(o[2]) + '</small></button>';
        }).join("") +
        '</div></article>';
    }).join("");
  }

  function answeredCount() {
    return QUESTIONS.reduce(function(total, q) { return total + (state[q.id] ? 1 : 0); }, 0);
  }

  function audienceOkay(i) {
    if (!state.audience) return true;
    if (state.audience === "women") return i.eligibleWomen !== false;
    return i.eligibleMen !== false;
  }

  function scoreIron(i) {
    const reasons = [];
    const cautions = [];
    const seg = i.segment || "";

    // v2.2 uses a weighted-average model rather than additive bonus points.
    // This prevents score saturation while making Strike and Price the dominant inputs.
    const W = { strike:0.35, price:0.30, goal:0.15, look:0.10, flight:0.08, evidence:0.02 };

    function bounded(x) { return Math.max(0, Math.min(100, x)); }

    // 1) STRIKE CONSISTENCY — 35%
    let strikeScore = 72; // neutral default if unanswered / unsure
    if (state.strike === "often-miss") {
      strikeScore = segmentAdd(seg, {"Super Game Improvement":100,"Game Improvement":92,"Players Distance":52,"Players":15});
      if (strikeScore >= 90) reasons.push("Its head category strongly matches your need for help on off-center strikes.");
      if (strikeScore <= 25) cautions.push("This player-oriented category may demand more consistent center contact than you described.");
    } else if (state.strike === "mixed") {
      strikeScore = segmentAdd(seg, {"Super Game Improvement":76,"Game Improvement":100,"Players Distance":86,"Players":48});
      if (strikeScore >= 86) reasons.push("Its category is a strong match for mixed strike consistency.");
    } else if (state.strike === "consistent") {
      strikeScore = segmentAdd(seg, {"Super Game Improvement":22,"Game Improvement":52,"Players Distance":92,"Players":100});
      if (strikeScore >= 92) reasons.push("Its player-oriented architecture matches your more consistent strike pattern.");
    } else if (state.strike === "not-sure") {
      strikeScore = segmentAdd(seg, {"Super Game Improvement":72,"Game Improvement":78,"Players Distance":78,"Players":70});
    }

    // Optional, small v1.6 architecture adjustment inside the strike component only.
    if (state.strike === "often-miss" &&
        num(i.fasH) !== null &&
        num(i.fasAvailableWeight) !== null && num(i.fasAvailableWeight) >= 50 &&
        num(i.engConfidence) !== null && num(i.engConfidence) >= 50) {
      strikeScore += Math.max(-4, Math.min(4, (num(i.fasH) - 50) / 10));
      if (num(i.fasH) >= 70) reasons.push("Published architecture shows several forgiveness-oriented design signals.");
    }
    strikeScore = bounded(strikeScore);

    // 2) PRICE — 30%
    // Unknown price receives a neutral/penalized value instead of being accidentally treated as $0.
    const price = num(i.pricePerIron);
    let priceScore = 76; // price-neutral default when buyer says keep price out of it
    if (state.budget === "value") {
      if (price === null) priceScore = 48;
      else if (price <= 100) { priceScore = 100; reasons.push("Published price strongly matches your value target."); }
      else if (price < 150) { priceScore = 100 - ((price - 100) / 50) * 18; reasons.push("Published price strongly matches your value target."); }
      else if (price < 175) priceScore = 82 - ((price - 150) / 25) * 18;
      else if (price < 225) priceScore = 64 - ((price - 175) / 50) * 34;
      else { priceScore = Math.max(5, 30 - ((price - 225) / 100) * 20); cautions.push("Published price is well above your stated value target."); }
    } else if (state.budget === "middle") {
      if (price === null) priceScore = 50;
      else if (price < 150) priceScore = 84 + Math.max(0, (price - 100) / 50) * 8;
      else if (price <= 190) { priceScore = 92 + ((price - 150) / 40) * 8; reasons.push("Published price is directly in your mid-market target."); }
      else if (price < 225) { priceScore = 100 - ((price - 190) / 35) * 8; reasons.push("Published price is directly in your mid-market target."); }
      else if (price < 275) priceScore = 70 - ((price - 225) / 50) * 30;
      else priceScore = 25;
    } else if (state.budget === "premium") {
      if (price === null) priceScore = 68;
      else if (price >= 225) { priceScore = 100; reasons.push("Price does not conflict with your premium-buying preference."); }
      else if (price >= 180) priceScore = 88;
      else priceScore = 72;
    } else if (state.budget === "open") {
      priceScore = price === null ? 72 : 82;
    }

    // 3) PRIMARY GOAL — 15%
    let goalScore = 75;
    if (state.goal === "help") {
      goalScore = segmentAdd(seg, {"Super Game Improvement":100,"Game Improvement":94,"Players Distance":65,"Players":30});
      if (goalScore >= 94) reasons.push("Its category strongly supports your easier-golf / forgiveness goal.");
    } else if (state.goal === "distance") {
      goalScore = segmentAdd(seg, {"Super Game Improvement":78,"Game Improvement":90,"Players Distance":100,"Players":55});
      if (goalScore >= 90) reasons.push("Its category is a strong starting point for a distance-oriented goal.");
    } else if (state.goal === "balanced") {
      goalScore = segmentAdd(seg, {"Super Game Improvement":72,"Game Improvement":90,"Players Distance":100,"Players":76});
      if (goalScore >= 90) reasons.push("Its category fits a balanced help/distance/control objective.");
    } else if (state.goal === "control") {
      goalScore = segmentAdd(seg, {"Super Game Improvement":28,"Game Improvement":52,"Players Distance":86,"Players":100});
      if (goalScore >= 86) reasons.push("Its category strongly aligns with a control/player-oriented goal.");
    }

    // 4) LOOK / CONFIDENCE — 10%
    const offset = num(i.sevenOffset);
    let lookScore = 78;
    if (state.look === "larger") {
      lookScore = segmentAdd(seg, {"Super Game Improvement":100,"Game Improvement":92,"Players Distance":62,"Players":32});
      if (offset !== null && offset >= 3.5) lookScore += 5;
      if (lookScore >= 92) reasons.push("The category is consistent with the confidence-oriented look you prefer.");
    } else if (state.look === "neutral") {
      lookScore = segmentAdd(seg, {"Super Game Improvement":68,"Game Improvement":86,"Players Distance":94,"Players":82});
    } else if (state.look === "compact") {
      lookScore = segmentAdd(seg, {"Super Game Improvement":30,"Game Improvement":55,"Players Distance":90,"Players":100});
      if (offset !== null && offset <= 2.5) lookScore += 4;
      if (lookScore >= 94) reasons.push("Its architecture is close to the compact/player look you prefer.");
    } else if (state.look === "not-sure") {
      lookScore = 78;
    }
    lookScore = bounded(lookScore);

    // 5) FLIGHT — 8%
    const loft = num(i.sevenLoft);
    let flightScore = 80;
    if (state.flight === "low") {
      flightScore = segmentAdd(seg, {"Super Game Improvement":94,"Game Improvement":96,"Players Distance":76,"Players":66});
      if (loft !== null && loft < 29) {
        flightScore -= 15;
        cautions.push("Strong published 7-iron loft: verify peak height and descent angle.");
      }
      if (flightScore >= 90) reasons.push("A more help-oriented architecture is a sensible starting point for your lower flight.");
    } else if (state.flight === "medium") {
      flightScore = segmentAdd(seg, {"Super Game Improvement":78,"Game Improvement":90,"Players Distance":92,"Players":84});
    } else if (state.flight === "high") {
      flightScore = segmentAdd(seg, {"Super Game Improvement":68,"Game Improvement":80,"Players Distance":94,"Players":94});
      if (loft !== null && loft <= 30) flightScore += 4;
    } else if (state.flight === "not-sure") {
      flightScore = 80;
    }
    flightScore = bounded(flightScore);

    // 6) DATA CONFIDENCE — 2%, deliberately small.
    const evidenceScore = num(i.engConfidence) !== null
      ? bounded(num(i.engConfidence))
      : (num(i.completeness) !== null ? bounded(num(i.completeness) * 100) : 40);

    let fit =
      strikeScore * W.strike +
      priceScore * W.price +
      goalScore * W.goal +
      lookScore * W.look +
      flightScore * W.flight +
      evidenceScore * W.evidence;

    // Women-specific is used as a small tie-breaker, not a substitute for fit.
    if (state.audience === "women" && i.womenSpecific) {
      fit += 1.5;
      reasons.push("A women-specific build is available.");
    }

    return Object.assign({}, i, {
      fit: Math.max(0, Math.min(100, Math.round(fit))),
      reasons: Array.from(new Set(reasons)).slice(0,4),
      cautions: Array.from(new Set(cautions)).slice(0,2),
      scoreDetail: {
        strike: Math.round(strikeScore),
        price: Math.round(priceScore),
        goal: Math.round(goalScore),
        look: Math.round(lookScore),
        flight: Math.round(flightScore),
        evidence: Math.round(evidenceScore)
      }
    });
  }

  function getResults() {
    let arr = DATA.filter(audienceOkay).map(scoreIron);
    if (state.brand !== "all") arr = arr.filter(function(i) { return i.brand === state.brand; });

    if (state.sort === "priceLow") {
      arr.sort(function(a,b) { return (num(a.pricePerIron) === null ? 999999 : num(a.pricePerIron)) - (num(b.pricePerIron) === null ? 999999 : num(b.pricePerIron)); });
    } else if (state.sort === "priceHigh") {
      arr.sort(function(a,b) { return (num(b.pricePerIron) === null ? -1 : num(b.pricePerIron)) - (num(a.pricePerIron) === null ? -1 : num(a.pricePerIron)); });
    } else if (state.sort === "brand") {
      arr.sort(function(a,b) { return String(a.brand||"").localeCompare(String(b.brand||"")) || String(a.model||"").localeCompare(String(b.model||"")); });
    } else {
      arr.sort(function(a,b) { return b.fit - a.fit || String(a.brand||"").localeCompare(String(b.brand||"")) || String(a.model||"").localeCompare(String(b.model||"")); });
    }
    return arr;
  }

  function fitTier(v) {
    if (v >= 85) return ["Best fit","tier-best"];
    if (v >= 70) return ["Worth a look","tier-good"];
    return ["Stretch fit","tier-stretch"];
  }

  function architectureContext(i) {
    const bits = [];
    if (num(i.egi) !== null) bits.push("EGI " + Math.round(num(i.egi)));
    if (num(i.fasH) !== null) bits.push("FAS-H " + Math.round(num(i.fasH)) + " hypothesis");
    if (num(i.engConfidence) !== null) bits.push(Math.round(num(i.engConfidence)) + "% evidence");
    return bits.length ? bits.join(" · ") : "Insufficient public data for composite architecture context";
  }

  function defaultWatch(i) {
    if (i.cautions && i.cautions.length) return i.cautions[0];
    if (i.segment === "Players") return "Verify mishit carry loss and dispersion; this category may offer less help.";
    if (i.segment === "Players Distance") return "Check launch, spin and wedge-end gapping as well as distance.";
    if (i.segment === "Game Improvement") return "Confirm offset, sole interaction and head size suit your delivery.";
    if (i.segment === "Super Game Improvement") return "Confirm predictable distance, gapping and turf interaction.";
    return "Test the complete build before purchase.";
  }

  function renderProfile() {
    const el = byId("profile");
    if (!el) return;
    const labels = {
      strike: {"often-miss":"More help on off-center contact","mixed":"Balanced forgiveness","consistent":"Player/control bias","not-sure":"Broad strike-fit range"},
      goal: {help:"Forgiveness first",distance:"Distance first",balanced:"Balanced",control:"Control & feel"},
      flight: {low:"Needs usable height",medium:"Neutral flight need",high:"Height is not a problem","not-sure":"No flight assumption"},
      look: {larger:"Confidence-oriented head",neutral:"Middle-ground shape",compact:"Compact/player shape","not-sure":"No visual filter"},
      budget: {value:"Value-conscious",middle:"Mid-market",premium:"Premium okay",open:"Price-neutral"}
    };
    const values = [
      ["Strike need", labels.strike[state.strike] || "Not answered"],
      ["Primary goal", labels.goal[state.goal] || "Not answered"],
      ["Flight need", labels.flight[state.flight] || "Not answered"],
      ["Preferred look", labels.look[state.look] || "Not answered"],
      ["Budget", labels.budget[state.budget] || "Not answered"],
      ["Shopping pool", state.audience === "women" ? "Women-specific + unisex options" : state.audience === "men" ? "Men/unisex options" : "Not answered"]
    ];
    el.innerHTML = values.map(function(x) {
      return '<div class="profile-item"><b>' + esc(x[0]) + '</b><span>' + esc(x[1]) + '</span></div>';
    }).join("");
  }

  function renderResults() {
    const resultsEl = byId("results");
    if (!resultsEl) return;

    const arr = getResults();
    const summary = byId("resultSummary");
    if (summary) {
      summary.textContent = answeredCount() < 6
        ? "Results are live. Complete all six questions for the strongest shortlist."
        : "GAL ranked " + arr.length + " eligible models. v2.2 weighting: Strike 35% · Price 30% · Goal 15% · Look 10% · Flight 8% · Evidence 2%.";
    }

    const shown = arr.slice(0, visible);
    if (!shown.length) {
      resultsEl.innerHTML = '<div class="empty">No eligible models were returned. Reset the guide or broaden the brand filter.</div>';
    } else {
      resultsEl.innerHTML = shown.map(function(i) {
        const tier = fitTier(i.fit);
        const why = i.reasons.length ? i.reasons : ["This model remains in the broader candidate pool; your answers do not strongly favor or disfavor it."];
        return '<article class="iron">' +
          '<div class="iron-top"><div><div class="brand-name">' + esc(i.brand) + '</div><h3>' + esc(i.model) + '</h3></div><div class="fit-score">' + i.fit + '<span>%</span></div></div>' +
          '<div><span class="fit-tier ' + tier[1] + '">' + tier[0] + '</span></div>' +
          '<div class="tags"><span class="tag">' + esc(i.segment || "Unclassified") + '</span>' +
            (i.womenSpecific ? '<span class="tag">Women-specific</span>' : '') +
            '<span class="tag">' + esc(i.loftClass || "Loft class n/a") + '</span></div>' +
          '<div class="specs"><div class="spec"><b>7i loft</b>' + (num(i.sevenLoft) === null ? "—" : num(i.sevenLoft) + "°") + '</div>' +
            '<div class="spec"><b>7i offset</b>' + (num(i.sevenOffset) === null ? "—" : num(i.sevenOffset).toFixed(1) + " mm") + '</div>' +
            '<div class="spec"><b>Price / iron</b>' + money(i.pricePerIron) + '</div></div>' +
          '<ul class="why-list">' + why.map(function(r) { return '<li>' + esc(r) + '</li>'; }).join("") + '</ul>' +
          '<div class="arch"><b>Why the score separates:</b> Strike ' + i.scoreDetail.strike + ' · Price ' + i.scoreDetail.price + ' · Goal ' + i.scoreDetail.goal + ' · Look ' + i.scoreDetail.look + ' · Flight ' + i.scoreDetail.flight + '</div>' +
          '<div class="arch"><b>GAL architecture context:</b> ' + esc(architectureContext(i)) + '. Not measured performance.</div>' +
          '<div class="watch"><b>Check before buying:</b> ' + esc(defaultWatch(i)) + '</div>' +
          '<div class="iron-actions">' +
            (i.source ? '<a class="source" target="_blank" rel="noopener" href="' + esc(i.source) + '">Source ↗</a>' : '<span></span>') +
            '<button type="button" class="compare ' + (selected.has(i.id) ? "on" : "") + '" data-compare="' + esc(i.id) + '">' + (selected.has(i.id) ? "Selected" : "Compare") + '</button>' +
          '</div></article>';
      }).join("");
    }

    const more = byId("showMore");
    if (more) more.style.display = arr.length > visible ? "block" : "none";
    renderCompare();
  }

  function renderCompare() {
    const body = byId("compareBody");
    const table = byId("compareTable");
    const empty = byId("compareEmpty");
    if (!body || !table || !empty) return;

    const chosen = DATA.filter(function(i) { return selected.has(i.id); }).map(scoreIron).sort(function(a,b){ return b.fit-a.fit; });
    if (!chosen.length) {
      table.hidden = true;
      empty.hidden = false;
      body.innerHTML = "";
      return;
    }
    empty.hidden = true;
    table.hidden = false;
    body.innerHTML = chosen.map(function(i) {
      return '<tr><td><b>' + esc(i.brand) + ' ' + esc(i.model) + '</b></td>' +
        '<td>' + i.fit + '%</td><td>' + esc(i.segment || "—") + '</td>' +
        '<td>' + (num(i.sevenLoft) === null ? "—" : num(i.sevenLoft) + "°") + '</td>' +
        '<td>' + (num(i.sevenOffset) === null ? "—" : num(i.sevenOffset).toFixed(1) + " mm") + '</td>' +
        '<td>' + money(i.pricePerIron) + '</td><td>' + esc(i.construction || i.headType || "—") + '</td>' +
        '<td>' + esc(architectureContext(i)) + '</td></tr>';
    }).join("");
  }

  function populateBrands() {
    const el = byId("brandFilter");
    if (!el) return;
    const brands = Array.from(new Set(DATA.filter(audienceOkay).map(function(i){ return i.brand; }).filter(Boolean))).sort();
    if (state.brand !== "all" && brands.indexOf(state.brand) < 0) state.brand = "all";
    el.innerHTML = '<option value="all">All brands</option>' +
      brands.map(function(b){ return '<option value="' + esc(b) + '"' + (state.brand === b ? ' selected' : '') + '>' + esc(b) + '</option>'; }).join("");
  }

  function render() {
    const ac = byId("answered");
    if (ac) ac.textContent = answeredCount();
    renderProfile();
    renderResults();
  }

  function resetGuide() {
    ["audience","strike","goal","flight","look","budget"].forEach(function(k){ state[k] = null; });
    state.brand = "all";
    state.sort = "fit";
    selected.clear();
    visible = 9;
    all(".option").forEach(function(b){ b.classList.remove("active"); });
    if (byId("sort")) byId("sort").value = "fit";
    populateBrands();
    render();
  }

  function runSelfTest() {
    const saved = Object.assign({}, state);
    const profiles = [
      {audience:"men",strike:"often-miss",goal:"help",flight:"low",look:"larger",budget:"value"},
      {audience:"men",strike:"mixed",goal:"distance",flight:"medium",look:"neutral",budget:"middle"},
      {audience:"men",strike:"consistent",goal:"control",flight:"high",look:"compact",budget:"premium"},
      {audience:"women",strike:"often-miss",goal:"balanced",flight:"low",look:"larger",budget:"open"},
      {audience:"women",strike:"mixed",goal:"distance",flight:"medium",look:"neutral",budget:"value"},
      {audience:"men",strike:"not-sure",goal:"balanced",flight:"not-sure",look:"not-sure",budget:"open"}
    ];
    const report = profiles.map(function(p, idx) {
      Object.assign(state, p, {brand:"all",sort:"fit"});
      const r = getResults();
      return {
        test: idx + 1,
        profile: p,
        count: r.length,
        top: r.length ? (r[0].brand + " " + r[0].model) : null,
        topScore: r.length ? r[0].fit : null,
        passed: r.length > 0
      };
    });
    Object.assign(state, saved);
    window.GAL_GUIDE_SELF_TEST = report;
    window.GAL_GUIDE_SELF_TEST_PASSED = report.every(function(x){ return x.passed; });
    return report;
  }

  function init() {
    if (!DATA.length) {
      const root = byId("results");
      if (root) root.innerHTML = '<div class="empty"><b>Database failed to load.</b> Please use the standalone file or upload all website package files together.</div>';
      return;
    }

    buildQuestions();
    populateBrands();

    const guideRoot = document.querySelector(".irons-guide");
    if (guideRoot) guideRoot.addEventListener("click", function(e) {
      const option = e.target.closest ? e.target.closest(".option") : null;
      if (option) {
        const q = option.getAttribute("data-q");
        const v = option.getAttribute("data-v");
        state[q] = v;
        all('.option[data-q="' + q + '"]').forEach(function(b){ b.classList.toggle("active", b === option); });
        if (q === "audience") { state.brand = "all"; populateBrands(); }
        render();
        return;
      }
      const compare = e.target.closest ? e.target.closest("[data-compare]") : null;
      if (compare) {
        const id = compare.getAttribute("data-compare");
        if (selected.has(id)) selected.delete(id);
        else if (selected.size < 3) selected.add(id);
        else { window.alert("Choose up to three finalists."); return; }
        render();
      }
    });

    const show = byId("showResults");
    if (show) show.addEventListener("click", function(){
      render();
      const section = byId("resultsSection");
      if (section && section.scrollIntoView) section.scrollIntoView({behavior:"smooth",block:"start"});
    });

    const more = byId("showMore");
    if (more) more.addEventListener("click", function(){ visible += 9; render(); });

    const reset = byId("reset");
    if (reset) reset.addEventListener("click", resetGuide);

    const brand = byId("brandFilter");
    if (brand) brand.addEventListener("change", function(e){ state.brand=e.target.value; visible=9; render(); });

    const sort = byId("sort");
    if (sort) sort.addEventListener("change", function(e){ state.sort=e.target.value; render(); });

    runSelfTest();
    render();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();

})();


