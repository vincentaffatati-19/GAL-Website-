(function(root){
'use strict';

const STORAGE='gal_equipment_bag_v1';
const PRESENTATION_STORAGE='gal.ux11.presentation';
const RECOVERED_ASSET_COMMIT='c2568a5a7dffaed422f03306509343078d5d8782';
const RAW_BASE=`https://raw.githubusercontent.com/vincentaffatati-19/GAL-Website-/${RECOVERED_ASSET_COMMIT}/portal/public/ux10`;
const PRESENTATION_ASSETS=Object.freeze({
  tee:Object.freeze({
    coastal:Object.freeze({label:'Coastal',detail:'Spyglass-inspired Coastal',src:`${RAW_BASE}/tee-boxes/coastal-01.webp`,blob:'aa8812e72ca4a5b4a622e19cbe118a4b46f8f606'}),
    cliffs:Object.freeze({label:'Cliffs',detail:'Torrey-inspired Cliffs',src:`${RAW_BASE}/tee-boxes/cliffs-01.webp`,blob:'0adcaeab08c904c1216821ee50b1165831bb65a9'})
  }),
  bag:Object.freeze({
    tour:Object.freeze({label:'GAL Tour Bag',src:`${RAW_BASE}/bags/gal-tour-bag.png`,blob:'ea2b1eeec016c85ddb4ce8cca5d90a9e57d448d4'}),
    stand:Object.freeze({label:'GAL Stand Bag',src:`${RAW_BASE}/bags/gal-stand-bag.png`,blob:'4995baf756a16e9aca03fcd2201c6cfc7d75d92d'})
  })
});
const DEFAULT_PRESENTATION=Object.freeze({tee:'coastal',bag:'tour'});
const categories=Object.freeze([
  ['DRIVER','Driver','drivers.html'],
  ['FAIRWAY','Fairway Woods','fairway-hybrids.html'],
  ['HYBRID','Hybrids','fairway-hybrids.html'],
  ['IRON','Irons','irons-buyers-guide.html'],
  ['WEDGE','Wedges','wedges.html'],
  ['PUTTER','Putter','putters.html'],
  ['GOLF_BALL','Ball','golf-ball-buyers-guide.html']
]);

function loadRaw(){
  const adapter=root.GALBagAdapter;
  if(adapter&&typeof adapter.load==='function'){
    try{return {data:adapter.load()||[],source:'GAL Bag'};}catch(e){}
  }
  try{return {data:JSON.parse(localStorage.getItem(STORAGE)||'[]'),source:'This browser'};}catch(e){return {data:[],source:'This browser'};}
}
function itemsOf(raw){return Array.isArray(raw)?raw:Array.isArray(raw&&raw.items)?raw.items:[];}
function catOf(x){
  const c=String(x.category||x.itemType||'').toUpperCase().replaceAll(' ','_');
  if(c==='FAIRWAY_WOOD')return 'FAIRWAY';
  if(c==='CLUB'){
    const s=String(x.slotCode||x.club||'').toUpperCase();
    if(s==='D'||s.includes('DRIVER'))return 'DRIVER';
    if(s.includes('W'))return 'FAIRWAY';
    if(s.includes('H'))return 'HYBRID';
    if(s==='P'||s.includes('PUTTER'))return 'PUTTER';
  }
  return c;
}
function idOf(x){return x.product_id||x.canonicalProductId||x.id||'';}
function active(x){return !x.status||['IN_BAG','ACTIVE','CURRENT'].includes(String(x.status).toUpperCase());}
function duplicateKey(x){
  const canonical=idOf(x);
  if(canonical)return `id:${canonical}`;
  const parts=[catOf(x),x.brand||x.display?.brand,x.model||x.display?.model,x.slotCode||x.club].map(v=>String(v||'').trim().toLowerCase()).filter(Boolean);
  return parts.length>=3?`fallback:${parts.join('|')}`:'';
}
function duplicateGroups(items){
  const groups=new Map();
  for(const item of items){
    const key=duplicateKey(item);
    if(!key)continue;
    if(!groups.has(key))groups.set(key,[]);
    groups.get(key).push(item);
  }
  return [...groups.values()].filter(group=>group.length>1);
}
function projection(raw){
  const items=itemsOf(raw).filter(active);
  const clubs=items.filter(x=>catOf(x)!=='GOLF_BALL');
  const by={};
  for(const [key] of categories)by[key]=items.filter(x=>catOf(x)===key);
  const duplicates=duplicateGroups(clubs);
  return {items,clubs,by,duplicates,overLimit:clubs.length>14,remainingSlots:Math.max(0,14-clubs.length)};
}
function esc(v){return String(v??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));}
function label(x){return [x.brand||x.display?.brand,x.model||x.display?.model,x.club||x.slotCode].filter(Boolean).join(' · ')||idOf(x)||'Saved equipment';}
function governedImage(x){return x.governedImageUrl||x.media?.governedUrl||x.display?.governedImageUrl||'';}

function loadPresentation(){
  try{
    const parsed=JSON.parse(localStorage.getItem(PRESENTATION_STORAGE)||'{}');
    return {
      tee:PRESENTATION_ASSETS.tee[parsed.tee]?parsed.tee:DEFAULT_PRESENTATION.tee,
      bag:PRESENTATION_ASSETS.bag[parsed.bag]?parsed.bag:DEFAULT_PRESENTATION.bag
    };
  }catch(e){return {...DEFAULT_PRESENTATION};}
}
function savePresentation(value){try{localStorage.setItem(PRESENTATION_STORAGE,JSON.stringify(value));}catch(e){}}
function applyPresentation(value){
  const tee=PRESENTATION_ASSETS.tee[value.tee]||PRESENTATION_ASSETS.tee[DEFAULT_PRESENTATION.tee];
  const bag=PRESENTATION_ASSETS.bag[value.bag]||PRESENTATION_ASSETS.bag[DEFAULT_PRESENTATION.bag];
  const teeImg=document.getElementById('teeBoxBackground');
  const bagImg=document.getElementById('bagVisualImage');
  teeImg.src=tee.src; teeImg.dataset.assetBlob=tee.blob;
  bagImg.src=bag.src; bagImg.alt=bag.label; bagImg.dataset.assetBlob=bag.blob;
  document.querySelectorAll('[data-tee-theme]').forEach(button=>{const on=button.dataset.teeTheme===value.tee;button.classList.toggle('active',on);button.setAttribute('aria-pressed',String(on));});
  document.querySelectorAll('[data-bag-visual]').forEach(button=>{const on=button.dataset.bagVisual===value.bag;button.classList.toggle('active',on);button.setAttribute('aria-pressed',String(on));});
}
function bindPresentation(){
  const value=loadPresentation();
  applyPresentation(value);
  document.querySelectorAll('[data-tee-theme]').forEach(button=>button.addEventListener('click',()=>{value.tee=button.dataset.teeTheme;savePresentation(value);applyPresentation(value);}));
  document.querySelectorAll('[data-bag-visual]').forEach(button=>button.addEventListener('click',()=>{value.bag=button.dataset.bagVisual;savePresentation(value);applyPresentation(value);}));
}

function renderCategories(p){
  const host=document.getElementById('categoryStatus');
  host.innerHTML=categories.map(([key,name])=>{
    const count=p.by[key].length;
    return `<button class="status-row ${count?'saved':'empty'}" type="button" data-category="${key}"><span><strong>${name}</strong><small>${count?`${count} saved`:'Not in current bag'}</small></span><b>${count?'Saved':'—'}</b></button>`;
  }).join('');
  host.querySelectorAll('[data-category]').forEach(button=>button.addEventListener('click',()=>renderContextDrawer(button.dataset.category,p)));
}
function renderContextDrawer(key,p){
  const row=categories.find(([candidate])=>candidate===key);
  if(!row)return;
  const [,name,href]=row;
  const items=p.by[key]||[];
  const host=document.getElementById('contextDrawer');
  host.innerHTML=`<div><span class="eyebrow">${esc(name.toUpperCase())}</span><h3>${esc(name)} in your bag</h3><p>${items.length?`${items.length} current ${items.length===1?'item':'items'} saved.`:'No current item is recorded for this category. This is a bag state, not a fit judgment.'}</p></div><div class="drawer-items">${items.length?items.map(item=>`<span>${esc(label(item))}</span>`).join(''):'<span class="data-hold">No governed item to display.</span>'}</div><a href="${esc(href)}">Open ${esc(name)} guide</a>`;
  host.hidden=false;
}
function renderEquipment(p){
  const host=document.getElementById('equipmentList');
  if(!p.items.length){host.innerHTML='<div class="empty-state">No saved equipment yet. Add only the equipment you actually play; GAL will not invent a baseline.</div>';return;}
  host.innerHTML=p.items.map(item=>{
    const src=governedImage(item);
    const visual=src?`<img class="equipment-thumb" src="${esc(src)}" alt="${esc(label(item))}">`:'<span class="image-hold" aria-label="Governed product image unavailable">Image hold</span>';
    return `<div class="equipment-item">${visual}<span class="equipment-copy"><strong>${esc(label(item))}</strong><small>${esc(catOf(item).replaceAll('_',' '))}</small></span><small>${esc(idOf(item)||'No canonical ID')}</small></div>`;
  }).join('');
}
function renderBagStatus(p){
  const status=document.getElementById('bagStatus');
  const copy=document.getElementById('bagStatusCopy');
  document.getElementById('bagCount').textContent=`${p.clubs.length} / 14 clubs`;
  document.getElementById('bagCaption').textContent=p.clubs.length?'Showing your recorded current equipment.':'No club baseline is recorded yet.';
  if(p.overLimit){status.textContent='Limit exceeded';copy.textContent=`${p.clubs.length} clubs are active. Resolve the bag before adding another club.`;}
  else if(p.duplicates.length){status.textContent='Duplicate review';copy.textContent='The same club appears more than once in the active bag record.';}
  else if(!p.clubs.length){status.textContent='Baseline needed';copy.textContent='Add the clubs you actually play. Unknown stays unknown.';}
  else{status.textContent=`${p.clubs.length} / 14 clubs`;copy.textContent=p.remainingSlots?`${p.remainingSlots} club ${p.remainingSlots===1?'slot remains':'slots remain'} before the 14-club limit.`:'The active bag is at the 14-club limit.';}
  const duplicate=document.getElementById('duplicateWarning');
  duplicate.hidden=!p.duplicates.length;
  duplicate.textContent=p.duplicates.length?`${p.duplicates.length} duplicate ${p.duplicates.length===1?'club record':'club records'} detected. Review before adding equipment.`:'';
}
function renderGovernedHolds(){
  document.getElementById('nextOpportunity').textContent='Not yet governed';
  document.getElementById('nextOpportunityCopy').textContent='No category recommendation result is loaded on this surface. Open a Buyer Guide to establish evidence.';
  document.getElementById('bagValue').textContent='Not available';
  document.getElementById('bagValueCopy').textContent='No governed bag-value source is connected here, so UX11 does not estimate a number.';
  document.getElementById('recentInsight').innerHTML='<strong>No governed insight loaded</strong><span>Insights appear here only after a governed insight source provides one.</span>';
  document.getElementById('progressGlance').innerHTML='<strong>No progress series loaded</strong><span>UX11 will not convert profile completeness or bag count into an invented progress score.</span>';
}
async function profileState(){try{if(!root.GALRecommendationProfile)return null;return await root.GALRecommendationProfile.load();}catch(e){return null;}}
async function renderProfileState(){
  const state=await profileState();
  const strong=document.getElementById('profileCompleteness');
  const copy=document.getElementById('profileCopy');
  if(state&&state.snapshot&&!state.authRequired){
    const count=(state.snapshot.facts||[]).length;
    strong.textContent=`Revision ${state.snapshot.revision??'—'}`;
    copy.textContent=count?`${count} governed profile ${count===1?'fact is':'facts are'} available to category engines.`:'Profile is connected but contains no active facts.';
  }else{strong.textContent='Sign in';copy.textContent='Sign in to connect your governed Golfer Profile.';}
}

async function mount(){
  bindPresentation();
  const raw=loadRaw();
  const p=projection(raw.data);
  document.getElementById('bagSource').textContent=raw.source==='This browser'?'Bag source: browser-local review data':'Bag source: governed GAL Bag';
  renderBagStatus(p);
  renderCategories(p);
  renderEquipment(p);
  renderGovernedHolds();
  await renderProfileState();
}

if(typeof document!=='undefined')document.addEventListener('DOMContentLoaded',mount);
root.GALMyBagReview=Object.freeze({mount,projection,catOf,itemsOf,duplicateGroups,PRESENTATION_ASSETS,loadPresentation,applyPresentation});
})(typeof window!=='undefined'?window:globalThis);
