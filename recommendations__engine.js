(function(root){
'use strict';
const ENGINE_VERSION='GAL-REC-1.0';
function s(v){return String(v==null?'':v).toLowerCase();}
function num(v,d){const n=Number(v);return Number.isFinite(n)?n:d;}
function idOf(r){return r.canonicalProductId||r.product_id||r.id;}
function normalizeBias(v){v=s(v);if(v.includes('draw'))return 'draw';if(v.includes('fade'))return 'fade';return 'neutral';}
function launchMatch(actual,wanted){
  actual=s(actual);wanted=s(wanted);if(!wanted)return false;if(actual===wanted)return true;
  const rank={'low':1,'mid-low':2,'mid':3,'mid-high':4,'high':5};
  return rank[actual]&&rank[wanted]&&Math.abs(rank[actual]-rank[wanted])<=1;
}
function driverScore(r,p){
  let score=62,reasons=[],tradeoffs=[];const mph=num(p.driver_swing_speed_mph,95),miss=s(p.driver_primary_miss),want=s(p.driver_launch_preference);
  if(mph<88&&r.profile==='easy-speed'){score+=18;reasons.push('Easy-speed chassis suits the current driver speed profile.');}
  if(mph>=88&&mph<=102&&['balanced','forgiveness','control-forgiving'].includes(r.profile)){score+=12;reasons.push('Head profile fits a mid-speed player without demanding tour-level speed.');}
  if(mph>102&&['control','control-forgiving','distance'].includes(r.profile)){score+=12;reasons.push('Lower-spin/control profile suits higher speed.');}
  const b=normalizeBias(r.bias);if(miss.includes('right')&&b==='draw'){score+=14;reasons.push('Draw-biased geometry helps reduce the cost of the common right miss.');}
  else if(miss.includes('right')&&b==='fade'){score-=10;tradeoffs.push('Fade tendency may amplify the current right-miss pattern.');}
  if(launchMatch(r.launch,want)){score+=6;reasons.push('Launch window is compatible with the stated preference.');}
  return {score:Math.max(0,Math.min(99,Math.round(score))),reasons,tradeoffs};
}
function fhTraits(r){const m=' '+s(r.model)+' ',loft=num(r.loft_deg,20);let profile='balanced',launch=loft>=21?'high':loft>=17?'mid-high':'mid',bias='neutral';
  if(m.includes(' lst ')||m.includes(' ls '))profile='control';
  if(m.includes(' sft ')){profile='forgiveness';bias='draw';}
  if(m.includes(' max hl ')){profile='easy-launch';launch='high';}
  else if(m.includes(' max '))profile='forgiveness';
  if(r.category==='HYBRID')profile=profile==='balanced'?'versatile':profile;
  return {profile,launch,bias};
}
function targetFor(r,p){const explicit=num(p.top_bag_target_yards,NaN);if(Number.isFinite(explicit))return explicit;return r.category==='FAIRWAY'?220:205;}
function estimatedCarry(r,p){const mph=num(p.driver_swing_speed_mph,95),base=mph*2.35;const loft=num(r.loft_deg,20);return Math.round(base-(loft-15)*3.25-(r.category==='HYBRID'?5:0));}
function fhScore(r,p){const t=fhTraits(r),target=targetFor(r,p),carry=estimatedCarry(r,p);let score=70-Math.min(28,Math.abs(carry-target)*1.8),reasons=[],tradeoffs=[];const miss=s(p.driver_primary_miss),mph=num(p.driver_swing_speed_mph,95);
  if(Math.abs(carry-target)<=8){score+=14;reasons.push('Estimated carry fits the top-of-bag distance need.');}
  if(miss.includes('right')&&t.bias==='draw'){score+=8;reasons.push('Draw-biased design can reduce the penalty of the prevailing right miss.');}
  if(mph<90&&t.launch==='high'){score+=7;reasons.push('Higher-launch profile supports playable carry at this speed.');}
  if(r.category==='FAIRWAY'&&num(r.loft_deg,0)>=20)reasons.push('Higher-loft fairway option favors launch and turf playability.');
  if(r.category==='HYBRID')reasons.push('Hybrid option offers a compact alternative for the same distance role.');
  return {score:Math.max(0,Math.min(99,Math.round(score))),estimatedCarryYards:carry,reasons,tradeoffs};
}
function recommendation(r,role,category,fit){return Object.freeze({canonicalProductId:idOf(r),role,category,score:fit.score,confidence:fit.score>=86?'HIGH':fit.score>=75?'MEDIUM':'LOW',reasons:Object.freeze(fit.reasons.slice()),tradeoffs:Object.freeze(fit.tradeoffs.slice()),estimatedCarryYards:fit.estimatedCarryYards??null,engineVersion:ENGINE_VERSION});}
function recommendations(snapshot){const p=root.GALRecommendationProfile.flatten(snapshot),drivers=root.GAL_DRIVERS||[],fh=root.GALFairwayHybridData||[];
  const rankedDrivers=drivers.filter(r=>r.active!==false&&!r.womenSpecific).map(r=>recommendation(r,'Driver','DRIVER',driverScore(r,p))).sort((a,b)=>b.score-a.score);
  const rankedTop=fh.map(r=>recommendation(r,'Top-of-bag distance',r.category,fhScore(r,p))).sort((a,b)=>b.score-a.score);
  return Object.freeze({engineVersion:ENGINE_VERSION,profileId:snapshot&&snapshot.profileId||null,profileRevision:num(snapshot&&snapshot.revision,0),profile:p,needs:Object.freeze([{id:'driver',label:'Driver',summary:'Optimize launch, stability and miss pattern.',items:rankedDrivers.slice(0,3)},{id:'top-bag',label:'Top-of-bag distance',summary:'Compare fairway woods and hybrids by the distance job they need to do.',items:rankedTop.slice(0,5)}]),categories:Object.freeze({DRIVER:rankedDrivers,FAIRWAY:rankedTop.filter(x=>x.category==='FAIRWAY'),HYBRID:rankedTop.filter(x=>x.category==='HYBRID')})});
}
root.GALRecommendationEngine=Object.freeze({ENGINE_VERSION,recommendations,driverScore,fhScore,fhTraits,estimatedCarry});
})(typeof window!=='undefined'?window:globalThis);