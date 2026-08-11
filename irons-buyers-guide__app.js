
(function(){
"use strict";
const DATA=Array.isArray(window.GAL_IRONS)?window.GAL_IRONS:[];
const selected=new Set();
let visible=9;

const state={audience:null,strike:null,goal:null,flight:null,look:null,budget:null,shopping:"amazon",brand:"all",sort:"fit"};

const QUESTIONS=[
 {id:"audience",title:"Who are you shopping for?",why:"Women see women-specific and appropriate unisex models.",options:[
  ["men","Men / unisex","Show standard and unisex models"],["women","Women","Include women-specific and unisex models"]]},
 {id:"strike",title:"How consistently do you strike your irons?",why:"Strike consistency is a practical clue to how much help the head should provide.",options:[
  ["often-miss","I miss the center often","Give me more help across the face"],["mixed","Mixed","Some centered strikes, some misses"],["consistent","Usually centered","Contact is a strength"],["not-sure","Not sure","Keep the recommendation broad"]]},
 {id:"goal",title:"What do you want most from your next irons?",why:"Choose the improvement you would notice most on the course.",options:[
  ["help","Easier golf","Forgiveness and confidence"],["distance","More distance","Create more useful carry"],["balanced","A little of everything","Help, distance and control"],["control","Control & feel","Predictable flight and player shaping"]]},
 {id:"flight",title:"What does your normal iron flight look like?",why:"GAL uses this to create an ideal loft target instead of treating stronger loft as automatically better.",options:[
  ["low","Low / hard to hold greens","I need more usable height"],["medium","Medium","No major height problem"],["high","High","Height comes easily"],["not-sure","Not sure","Do not make a flight assumption"]]},
 {id:"look",title:"What kind of iron gives you confidence?",why:"GAL uses your visual preference to create an ideal head-shape and offset target where specifications are published.",options:[
  ["larger","A larger, reassuring head","More visual help is okay"],["neutral","Something in the middle","Neither very large nor very compact"],["compact","A compact player look","Cleaner shape / less offset"],["not-sure","No strong preference","Let testing decide"]]},
 {id:"budget",title:"How important is price?",why:"When two irons fit similarly, GAL gives the lower-priced option a stronger Value score.",options:[
  ["value","Value matters","Prefer roughly under $150 per iron"],["middle","Mid-market is fine","Roughly $150–$225 per iron"],["premium","Premium is okay","Pay more for the right fit"],["open","Keep price out of it","Rank fit before price"]]}
];

const RETAILERS=[
 {id:"amazon",label:"Amazon"},{id:"walmart",label:"Walmart"},{id:"dicks",label:"Dick's Sporting Goods"},
 {id:"golfgalaxy",label:"Golf Galaxy"},{id:"pgatss",label:"PGA TOUR Superstore"},
 {id:"direct",label:"Manufacturer / Direct"},{id:"none",label:"No Preference"}
];

const AMAZON_VERIFIED={
 "TaylorMade|P·790":"https://www.amazon.com/TaylorMade-Golf-2025-P790-Irons/dp/B0DRMMWYNN",
 "TaylorMade|Qi Max":"https://www.amazon.com/Taylormade-Golf-Irons-Steel-Stiff/dp/B0GC76ZRRB",
 "TaylorMade|Qi Max HL":"https://www.amazon.com/TaylorMade-Qi-Max-HL-Custom/dp/B0GS6TJ133",
 "Callaway|Elyte":"https://www.amazon.com/s?k=callaway+elyte+irons",
 "Callaway|Elyte X":"https://www.amazon.com/Callaway-Golf-Elyte-Individual-Iron/dp/B0DTW4SR74",
 "Callaway|Elyte HL":"https://www.amazon.com/Callaway-Golf-Elyte-Launch-Individual/dp/B0DTW6THZW",
 "Cobra|King Tec-X":"https://www.amazon.com/Cobra-Golf-King-Mens-Iron/dp/B0DC8RRDFF"
};

// v3.1: verified retailer registry. Empty registries are intentional until GAL verifies
// model-specific purchase paths. Never infer availability.
const RETAILER_VERIFIED = {
 amazon: AMAZON_VERIFIED,
 walmart: {},
 dicks: {},
 golfgalaxy: {},
 pgatss: {}
};

const RETAILER_PRIORITY = ["amazon","golfgalaxy","dicks","pgatss","walmart","direct"];


const ROOT=document.querySelector(".irons-guide");
const $=id=>ROOT?ROOT.querySelector("#"+id):null;
const $$=sel=>ROOT?Array.prototype.slice.call(ROOT.querySelectorAll(sel)):[];
function num(v){if(v===null||v===undefined||v==="")return null;const x=Number(v);return Number.isFinite(x)?x:null}
function esc(v){return String(v==null?"":v).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]))}
function money(v){const x=num(v);return x===null?"—":"$"+Math.round(x).toLocaleString()}
function clamp(x,a=0,b=100){return Math.max(a,Math.min(b,x))}
function closeness(value,target,fullCreditWidth,zeroWidth){
 if(value===null)return null;
 const d=Math.abs(value-target);
 if(d<=fullCreditWidth)return 100;
 if(d>=zeroWidth)return 0;
 return 100-(d-fullCreditWidth)/(zeroWidth-fullCreditWidth)*100;
}
function segBaseline(seg,map,neutral=70){return Object.prototype.hasOwnProperty.call(map,seg)?map[seg]:neutral}

function buildQuestions(){
 $("questions").innerHTML=QUESTIONS.map((q,idx)=>{
  const opts='<div class="options">'+q.options.map(o=>'<button type="button" class="option" data-q="'+esc(q.id)+'" data-v="'+esc(o[0])+'">'+esc(o[1])+'<small>'+esc(o[2])+'</small></button>').join("")+'</div>';
  const shop=q.id==="audience"
   ? '<div class="shopping-setup"><div class="shopping-label">Where are you shopping?</div><div class="shopping-help">Amazon is the default shopping preference. If you choose another retailer, your choice takes priority when GAL has a verified purchase path.</div><div class="retailer-options">'+RETAILERS.map(r=>'<button type="button" class="retailer-option '+(state.shopping===r.id?"active":"")+'" data-shop="'+r.id+'">'+esc(r.label)+'</button>').join("")+'</div></div>'
   : "";
  return '<article class="question '+(q.id==="audience"?"question-audience":"")+'"><div class="qnum">QUESTION '+(idx+1)+'</div><h3>'+esc(q.title)+'</h3><p class="why">'+esc(q.why)+'</p><div class="'+(q.id==="audience"?"audience-shopping-grid":"")+'"><div>'+opts+'</div>'+shop+'</div></article>';
 }).join("");
}
function answered(){return QUESTIONS.reduce((n,q)=>n+(state[q.id]?1:0),0)}
function eligible(i){if(!state.audience)return true;return state.audience==="women"?i.eligibleWomen!==false:i.eligibleMen!==false}

function retailerAvailability(i,retailer){
 if(!retailer||retailer==="none")return{available:null,url:null,label:"No Preference"};
 const key=String(i.brand||"")+"|"+String(i.model||"");
 if(retailer==="direct"){
   return{available:!!i.source,url:i.source||null,label:"Manufacturer / Direct"};
 }
 const registry=RETAILER_VERIFIED[retailer]||{};
 const url=registry[key]||null;
 const r=RETAILERS.find(x=>x.id===retailer);
 return{available:!!url,url:url,label:r?r.label:"Retailer"};
}

function retailerRank(i){
 if(state.shopping==="none")return 0;
 const explicit=retailerAvailability(i,state.shopping);
 if(explicit.available===true)return 3;
 if(state.shopping!=="amazon"&&state.shopping!=="none") {
   const amazon=retailerAvailability(i,"amazon");
   if(amazon.available===true)return 2;
 }
 const direct=retailerAvailability(i,"direct");
 return direct.available===true?1:0;
}

function purchasePath(i){
 // 1) Explicit shopper selection always wins when verified.
 if(state.shopping&&state.shopping!=="none"){
   const explicit=retailerAvailability(i,state.shopping);
   if(explicit.available&&explicit.url){
     return{label:"BUY NOW",retailer:explicit.label,url:explicit.url};
   }
 }

 // 2) If user selected another retailer but we cannot verify that model there,
 // fall back to the next verified option. Amazon is preferred among fallbacks.
 for(const retailer of RETAILER_PRIORITY){
   if(retailer===state.shopping)continue;
   const r=retailerAvailability(i,retailer);
   if(r.available&&r.url){
     return{label:"BUY NOW",retailer:r.label,url:r.url};
   }
 }

 // 3) If no verified path exists, show no Buy Now button.
 return null;
}

/* -----------------------------
   V3.0 CONTINUOUS FIT COMPONENTS
   ----------------------------- */

function strikeFit(i){
 const seg=i.segment||"";
 let base=75;
 if(state.strike==="often-miss")base=segBaseline(seg,{"Super Game Improvement":96,"Game Improvement":90,"Players Distance":58,"Players":24});
 else if(state.strike==="mixed")base=segBaseline(seg,{"Super Game Improvement":76,"Game Improvement":94,"Players Distance":86,"Players":55});
 else if(state.strike==="consistent")base=segBaseline(seg,{"Super Game Improvement":34,"Game Improvement":58,"Players Distance":91,"Players":98});
 else if(state.strike==="not-sure")base=segBaseline(seg,{"Super Game Improvement":74,"Game Improvement":80,"Players Distance":80,"Players":72});

 const offset=num(i.sevenOffset);
 let offsetAdj=0;
 if(offset!==null){
  if(state.strike==="often-miss")offsetAdj=(closeness(offset,4.3,0.6,4.0)-50)*0.12;
  if(state.strike==="mixed")offsetAdj=(closeness(offset,3.2,0.7,3.6)-50)*0.08;
  if(state.strike==="consistent")offsetAdj=(closeness(offset,2.0,0.7,3.2)-50)*0.08;
 }

 let archAdj=0;
 if(num(i.fasH)!==null&&num(i.fasAvailableWeight)!==null&&i.fasAvailableWeight>=50&&num(i.engConfidence)!==null&&i.engConfidence>=50){
   if(state.strike==="often-miss")archAdj=(i.fasH-50)*0.10;
   else if(state.strike==="mixed")archAdj=(i.fasH-50)*0.04;
 }
 return clamp(base+offsetAdj+archAdj);
}

function priceTarget(){
 if(state.budget==="value")return{target:120,full:12,zero:170};
 if(state.budget==="middle")return{target:185,full:22,zero:120};
 if(state.budget==="premium")return{target:250,full:45,zero:220};
 return null;
}
function priceFit(i){
 const p=num(i.pricePerIron);
 if(state.budget==="open")return p===null?72:82;
 if(p===null)return 45;
 const t=priceTarget();
 return clamp(closeness(p,t.target,t.full,t.zero));
}

function goalFit(i){
 const seg=i.segment||"";
 const loft=num(i.sevenLoft);
 let base=76;
 if(state.goal==="help")base=segBaseline(seg,{"Super Game Improvement":98,"Game Improvement":94,"Players Distance":68,"Players":35});
 else if(state.goal==="distance")base=segBaseline(seg,{"Super Game Improvement":78,"Game Improvement":88,"Players Distance":98,"Players":58});
 else if(state.goal==="balanced")base=segBaseline(seg,{"Super Game Improvement":70,"Game Improvement":90,"Players Distance":96,"Players":78});
 else if(state.goal==="control")base=segBaseline(seg,{"Super Game Improvement":30,"Game Improvement":52,"Players Distance":88,"Players":98});
 if(loft!==null&&state.goal==="distance")base+=(closeness(loft,29,1.2,5.5)-50)*0.10;
 if(loft!==null&&state.goal==="control")base+=(closeness(loft,33,1.0,5.5)-50)*0.08;
 return clamp(base);
}

function idealLoft(){
 if(state.flight==="low")return state.goal==="distance"?30.5:31.5;
 if(state.flight==="medium")return state.goal==="distance"?29.5:31;
 if(state.flight==="high")return state.goal==="control"?32:29;
 return state.goal==="distance"?29.5:31;
}
function flightFit(i){
 const l=num(i.sevenLoft);
 const seg=i.segment||"";
 let score=l===null?62:closeness(l,idealLoft(),1.0,5.5);
 if(state.flight==="low"){
   score=(score*0.75)+segBaseline(seg,{"Super Game Improvement":92,"Game Improvement":94,"Players Distance":74,"Players":64})*0.25;
 }
 if(state.flight==="high"){
   score=(score*0.82)+segBaseline(seg,{"Super Game Improvement":68,"Game Improvement":80,"Players Distance":92,"Players":92})*0.18;
 }
 return clamp(score);
}

function idealOffset(){
 if(state.look==="larger")return 4.3;
 if(state.look==="neutral")return 3.0;
 if(state.look==="compact")return 1.8;
 return null;
}
function shapeFit(i){
 const o=num(i.sevenOffset);
 const seg=i.segment||"";
 if(state.look==="not-sure"||!state.look)return segBaseline(seg,{"Super Game Improvement":72,"Game Improvement":80,"Players Distance":82,"Players":78});
 const target=idealOffset();
 let score=o===null?58:closeness(o,target,state.look==="neutral"?0.7:0.6,state.look==="compact"?3.2:4.0);
 const cat=state.look==="larger"
  ? segBaseline(seg,{"Super Game Improvement":98,"Game Improvement":91,"Players Distance":62,"Players":35})
  : state.look==="compact"
   ? segBaseline(seg,{"Super Game Improvement":32,"Game Improvement":54,"Players Distance":88,"Players":98})
   : segBaseline(seg,{"Super Game Improvement":68,"Game Improvement":84,"Players Distance":92,"Players":82});
 return clamp(score*0.72+cat*0.28);
}

function setArchitectureFit(i){
 const lp=num(i.loftProgression), op=num(i.offsetProgression), hm=num(i.headMassProgression);
 let vals=[];
 if(lp!==null)vals.push(lp);
 if(op!==null)vals.push(op);
 if(hm!==null)vals.push(hm);
 if(!vals.length)return 60;
 return clamp(vals.reduce((a,b)=>a+b,0)/vals.length);
}
function evidenceFit(i){
 if(num(i.engConfidence)!==null)return clamp(i.engConfidence);
 if(num(i.completeness)!==null)return clamp(i.completeness*100);
 return 38;
}

function scoreIron(i){
 const c={
  strike:strikeFit(i),
  price:priceFit(i),
  goal:goalFit(i),
  flight:flightFit(i),
  shape:shapeFit(i),
  set:setArchitectureFit(i),
  evidence:evidenceFit(i)
 };
 // Price is intentionally separated from pure Fit in v3.0.
 const fit =
   c.strike*0.34 +
   c.goal*0.19 +
   c.flight*0.16 +
   c.shape*0.14 +
   c.set*0.10 +
   c.evidence*0.07;

 const p=num(i.pricePerIron);
 const value = p===null ? null : clamp(
   fit*0.68 +
   c.price*0.27 +
   c.evidence*0.05
 );

 const reasons=[];
 const cautions=[];
 if(c.strike>=90)reasons.push("Excellent match for your stated strike consistency.");
 if(c.goal>=90)reasons.push("Strong match for the outcome you want from the set.");
 if(c.flight>=88&&num(i.sevenLoft)!==null)reasons.push("Published 7-iron loft is close to your ideal flight target.");
 if(c.shape>=88)reasons.push("Published geometry/category is close to your preferred address look.");
 if(value!==null&&c.price>=90)reasons.push("Published price is very close to your ideal budget target.");
 if(c.set>=85)reasons.push("Published set progression is a relative strength in the current GAL data.");
 if(c.strike<45)cautions.push("Head architecture is a stretch relative to your stated strike consistency.");
 if(c.flight<45)cautions.push("Published loft architecture is a weak match for your stated flight need.");
 if(c.shape<45)cautions.push("Head/offset architecture may not match the look you prefer.");
 if(state.budget!=="open"&&c.price<35)cautions.push("Published price is a weak match for your selected budget.");
 if(p===null)cautions.push("GAL does not have a verified per-iron price, so Value cannot be calculated.");

 return Object.assign({},i,{
   fitExact:fit,valueExact:value,
   fit:Math.round(fit*10)/10,
   value:value===null?null:Math.round(value*10)/10,
   components:c,
   reasons:Array.from(new Set(reasons)).slice(0,4),
   cautions:Array.from(new Set(cautions)).slice(0,2),
   role:""
 });
}

function assignRoles(arr){
 const used=new Set();
 function best(predicate,metric){
   let candidates=arr.filter(x=>!used.has(x.id)&&predicate(x));
   candidates.sort((a,b)=>(metric(b)-metric(a))||b.fitExact-a.fitExact);
   if(!candidates.length)return null;
   const x=candidates[0];used.add(x.id);return x;
 }
 if(arr[0]){arr[0].role="Best Overall";used.add(arr[0].id)}
 const value=best(x=>x.valueExact!==null&&x.fitExact>=68,x=>x.valueExact||0); if(value)value.role="Best Value";
 const forgiving=best(x=>x.fitExact>=65,x=>x.components.strike); if(forgiving)forgiving.role="More Forgiving";
 const compact=best(x=>x.fitExact>=65&&(num(x.sevenOffset)!==null||x.segment==="Players"||x.segment==="Players Distance"),x=>x.components.shape); if(compact)compact.role="More Compact";
 if(state.goal==="distance"){
   const dist=best(x=>x.fitExact>=62,x=>x.components.goal+x.components.flight*0.35); if(dist)dist.role="Distance Alternative";
 } else {
   const dist=best(x=>x.fitExact>=62&&(x.segment==="Players Distance"||num(x.sevenLoft)!==null),x=>x.components.goal+x.components.flight*0.25); if(dist)dist.role="Different Flight Option";
 }
 const premium=best(x=>x.fitExact>=65&&num(x.pricePerIron)!==null&&x.pricePerIron>=225,x=>x.fitExact); if(premium)premium.role="Premium Alternative";
 return arr;
}

function getResults(){
 let arr=DATA.filter(eligible).map(scoreIron);
 if(state.brand!=="all")arr=arr.filter(i=>i.brand===state.brand);
 if(state.sort==="value")arr.sort((a,b)=>(b.valueExact??-1)-(a.valueExact??-1)||b.fitExact-a.fitExact);
 else if(state.sort==="priceLow")arr.sort((a,b)=>(num(a.pricePerIron)??999999)-(num(b.pricePerIron)??999999));
 else if(state.sort==="priceHigh")arr.sort((a,b)=>(num(b.pricePerIron)??-1)-(num(a.pricePerIron)??-1));
 else if(state.sort==="brand")arr.sort((a,b)=>String(a.brand||"").localeCompare(String(b.brand||""))||String(a.model||"").localeCompare(String(b.model||"")));
 else arr.sort((a,b)=>{
   const d=b.fitExact-a.fitExact;
   if(Math.abs(d)>.0001)return d;
   const rd=retailerRank(b)-retailerRank(a);if(rd)return rd;
   return (b.valueExact??-1)-(a.valueExact??-1)||String(a.brand||"").localeCompare(String(b.brand||""));
 });
 return assignRoles(arr);
}

function tier(v){return v>=86?["Strong Match","tier-best"]:v>=73?["Good Match","tier-good"]:["Possible Match","tier-stretch"]}
function arch(i){let bits=[];if(num(i.egi)!==null)bits.push("EGI "+Math.round(i.egi));if(num(i.fasH)!==null)bits.push("FAS-H "+Math.round(i.fasH)+" hypothesis");if(num(i.engConfidence)!==null)bits.push(Math.round(i.engConfidence)+"% evidence");return bits.length?bits.join(" · "):"Insufficient data for composite architecture context"}
function watch(i){if(i.cautions.length)return i.cautions[0];if(i.segment==="Players")return"Verify mishit carry loss and dispersion.";if(i.segment==="Players Distance")return"Check launch, spin and wedge-end gapping.";if(i.segment==="Game Improvement")return"Confirm offset, sole interaction and head size suit your delivery.";if(i.segment==="Super Game Improvement")return"Confirm predictable distance, gapping and turf interaction.";return"Test the complete build before purchase."}

function renderProfile(){
 const labels={
  strike:{"often-miss":"More help on off-center contact","mixed":"Balanced forgiveness","consistent":"Player/control bias","not-sure":"Broad strike-fit range"},
  goal:{help:"Forgiveness first",distance:"Distance first",balanced:"Balanced",control:"Control & feel"},
  flight:{low:"Needs usable height",medium:"Neutral flight need",high:"Height is not a problem","not-sure":"No flight assumption"},
  look:{larger:"Confidence-oriented head",neutral:"Middle-ground shape",compact:"Compact/player shape","not-sure":"No visual filter"},
  budget:{value:"Value-conscious",middle:"Mid-market",premium:"Premium okay",open:"Price-neutral"}
 };
 const vals=[["Strike need",labels.strike[state.strike]||"Not answered"],["Primary goal",labels.goal[state.goal]||"Not answered"],["Flight need",labels.flight[state.flight]||"Not answered"],["Preferred look",labels.look[state.look]||"Not answered"],["Budget",labels.budget[state.budget]||"Not answered"],["Shopping pool",state.audience==="women"?"Women-specific + unisex":state.audience==="men"?"Men/unisex":"Not answered"]];
 $("profile").innerHTML=vals.map(x=>'<div class="profile-item"><b>'+esc(x[0])+'</b><span>'+esc(x[1])+'</span></div>').join("");
}

function render(){
 $("answered").textContent=answered();
 renderProfile();
 const arr=getResults();
 $("resultSummary").textContent=answered()<6
  ?"Results update as you answer. Complete all six questions for the strongest shortlist."
  :"GAL is comparing each iron with your ideal profile. Exact internal scores are preserved to reduce ties; displayed scores are rounded to one decimal.";

 const shown=arr.slice(0,visible);
 $("results").innerHTML=shown.map(i=>{
  const t=tier(i.fitExact),buy=purchasePath(i),ret=retailerAvailability(i,state.shopping);
  let retailNote="";
  if(buy){
    retailNote='<div class="retailer-note preferred">Available from: '+esc(buy.retailer)+'</div>';
  } else if(state.shopping!=="none"){
    retailNote='<div class="retailer-note">No verified purchase path is currently available for this model.</div>';
  }
  return '<article class="iron">'+
   (i.role?'<div class="role-badge">'+esc(i.role)+'</div>':'')+
   '<div class="iron-top"><div><div class="brand-name">'+esc(i.brand)+'</div><h3>'+esc(i.model)+'</h3></div>'+
   '<div class="scores"><div class="score-pill"><b>'+i.fit.toFixed(1)+'</b><span>GAL FIT</span></div><div class="score-pill value"><b>'+(i.value===null?"—":i.value.toFixed(1))+'</b><span>GAL VALUE</span></div></div></div>'+
   '<div><span class="fit-tier '+t[1]+'">'+t[0]+'</span></div>'+
   '<div class="tags"><span class="tag">'+esc(i.segment||"Unclassified")+'</span>'+(i.womenSpecific?'<span class="tag">Women-specific</span>':'')+'<span class="tag">'+esc(i.loftClass||"Loft n/a")+'</span></div>'+
   '<div class="specs"><div class="spec"><b>7i loft</b>'+(num(i.sevenLoft)===null?"—":i.sevenLoft+"°")+'</div><div class="spec"><b>7i offset</b>'+(num(i.sevenOffset)===null?"—":i.sevenOffset.toFixed(1)+" mm")+'</div><div class="spec"><b>Price / iron</b>'+money(i.pricePerIron)+'</div></div>'+
   '<ul class="why-list">'+(i.reasons.length?i.reasons:["This remains a credible candidate, but no single component strongly separates it."]).map(r=>'<li>'+esc(r)+'</li>').join("")+'</ul>'+
   '<div class="component-line"><b>Fit components:</b> Strike '+Math.round(i.components.strike)+' · Goal '+Math.round(i.components.goal)+' · Flight '+Math.round(i.components.flight)+' · Shape '+Math.round(i.components.shape)+' · Set '+Math.round(i.components.set)+'</div>'+
   '<div class="arch"><b>GAL architecture context:</b> '+esc(arch(i))+'. Not measured performance.</div>'+
   '<div class="watch"><b>Check before buying:</b> '+esc(watch(i))+'</div>'+
   retailNote+
   '<div class="iron-actions">'+(i.source?'<a class="source" target="_blank" rel="noopener" href="'+esc(i.source)+'">Source ↗</a>':'<span></span>')+
   '<div class="purchase-actions">'+(buy?'<a class="buy-link buy-now" target="_blank" rel="noopener" href="'+esc(buy.url)+'"><span>'+esc(buy.label)+'</span><small>'+esc(buy.retailer)+'</small></a>':'')+
   '<button type="button" class="compare '+(selected.has(i.id)?"on":"")+'" data-compare="'+esc(i.id)+'">'+(selected.has(i.id)?"Selected":"Compare")+'</button></div></div></article>';
 }).join("");
 $("showMore").style.display=arr.length>visible?"block":"none";
 renderCompare();
}

function renderCompare(){
 const chosen=getResults().filter(i=>selected.has(i.id)).sort((a,b)=>b.fitExact-a.fitExact);
 if(!chosen.length){$("compareTable").hidden=true;$("compareEmpty").hidden=false;$("compareBody").innerHTML="";return}
 $("compareEmpty").hidden=true;$("compareTable").hidden=false;
 $("compareBody").innerHTML=chosen.map(i=>'<tr><td><b>'+esc(i.brand)+' '+esc(i.model)+'</b></td><td>'+esc(i.role||"—")+'</td><td>'+i.fit.toFixed(1)+'</td><td>'+(i.value===null?"—":i.value.toFixed(1))+'</td><td>'+esc(i.segment||"—")+'</td><td>'+(num(i.sevenLoft)===null?"—":i.sevenLoft+"°")+'</td><td>'+(num(i.sevenOffset)===null?"—":i.sevenOffset.toFixed(1)+" mm")+'</td><td>'+money(i.pricePerIron)+'</td><td>'+esc(arch(i))+'</td></tr>').join("");
}

function populateBrands(){
 const brands=Array.from(new Set(DATA.filter(eligible).map(i=>i.brand).filter(Boolean))).sort();
 if(state.brand!=="all"&&!brands.includes(state.brand))state.brand="all";
 $("brandFilter").innerHTML='<option value="all">All brands</option>'+brands.map(b=>'<option value="'+esc(b)+'" '+(state.brand===b?"selected":"")+'>'+esc(b)+'</option>').join("");
}
function resetGuide(){
 ["audience","strike","goal","flight","look","budget"].forEach(k=>state[k]=null);state.shopping="amazon";state.brand="all";state.sort="fit";visible=9;selected.clear();
 $$(".option").forEach(b=>b.classList.remove("active"));$$(".retailer-option").forEach(b=>b.classList.toggle("active",b.dataset.shop==="amazon"));
 $("sort").value="fit";populateBrands();render();
}

function runSelfTest(){
 const saved=Object.assign({},state);
 const profiles=[
  {audience:"men",strike:"often-miss",goal:"help",flight:"low",look:"larger",budget:"value"},
  {audience:"men",strike:"mixed",goal:"balanced",flight:"medium",look:"neutral",budget:"middle"},
  {audience:"men",strike:"consistent",goal:"control",flight:"high",look:"compact",budget:"premium"},
  {audience:"women",strike:"often-miss",goal:"balanced",flight:"low",look:"larger",budget:"value"}
 ];
 const report=profiles.map((p,idx)=>{Object.assign(state,p,{brand:"all",sort:"fit"});const r=getResults();const top=r.slice(0,10);const unique=new Set(top.map(x=>x.fitExact.toFixed(4))).size;return{test:idx+1,count:r.length,top:r[0]?r[0].brand+" "+r[0].model:null,uniqueTop10FitScores:unique,roles:top.filter(x=>x.role).map(x=>x.role),passed:r.length>0&&unique>=3};});
 Object.assign(state,saved);window.GAL_GUIDE_SELF_TEST=report;window.GAL_GUIDE_SELF_TEST_PASSED=report.every(x=>x.passed);return report;
}

if(ROOT) ROOT.addEventListener("click",e=>{
 const o=e.target.closest&&e.target.closest(".option");if(o){state[o.dataset.q]=o.dataset.v;$$('.option[data-q="'+o.dataset.q+'"]').forEach(b=>b.classList.toggle("active",b===o));if(o.dataset.q==="audience"){state.brand="all";populateBrands()}render();return}
 const shop=e.target.closest&&e.target.closest("[data-shop]");if(shop){state.shopping=shop.dataset.shop||"amazon";$$(".retailer-option").forEach(b=>b.classList.toggle("active",b===shop));render();return}
 const c=e.target.closest&&e.target.closest("[data-compare]");if(c){const id=c.dataset.compare;if(selected.has(id))selected.delete(id);else if(selected.size<3)selected.add(id);else return alert("Choose up to three finalists.");render()}
});
if($("showResults")) $("showResults").addEventListener("click",()=>{render();$("resultsSection").scrollIntoView({behavior:"smooth",block:"start"})});
if($("showMore")) $("showMore").addEventListener("click",()=>{visible+=9;render()});
if($("reset")) $("reset").addEventListener("click",resetGuide);
if($("brandFilter")) $("brandFilter").addEventListener("change",e=>{state.brand=e.target.value;visible=9;render()});
if($("sort")) $("sort").addEventListener("change",e=>{state.sort=e.target.value;render()});

function init(){
 if(!ROOT)return;
 if(!DATA.length){if($("results")) $("results").innerHTML='<div class="empty"><b>Database failed to load.</b></div>';return}
 buildQuestions();populateBrands();runSelfTest();render();
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
})();
