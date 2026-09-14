(function(root){
'use strict';
const fields={
  measurements:[['genderField','gender',null],['ageField','ageRange',null]],
  game:[['handedness','handedness',null],['handicapIndex','handicap_index','index'],['skillBand','skill_band',null]],
  swing:[['driverSwingSpeed','driver_swing_speed_mph','mph'],['driverLaunchPreference','driver_launch_preference',null]],
  miss:[['driverPrimaryMiss','driver_primary_miss',null]],
  play:[['topBagTarget','top_bag_target_yards','yards'],['homePlayLocation','home_play_location_text',null]]
};
let snapshot=null,original={};
function flatten(s){const o={};((s&&s.facts)||[]).forEach(f=>o[f.key]=f.value);return o;}
function display(v){if(v===null||v===undefined)return '';if(typeof v==='object')return JSON.stringify(v);return String(v);}
function coerce(el){const v=el.value.trim();if(!v)return null;if(el.type==='number'){const n=Number(v);return Number.isFinite(n)?n:null;}return v;}
function showWorkspace(on){document.getElementById('profileAuth').hidden=on;document.getElementById('profileWorkspace').hidden=!on;}
function isLeftHanded(){return (document.getElementById('handedness')?.value||'')==='LH';}
function visualApi(){return root.GALProfileVisuals||null;}
function renderSwingPlateFrames(plate,left){
  const stages=['Address','Backswing','Impact','Finish'];
  const source=new Image();
  if(/^https?:/.test(plate)) source.crossOrigin='anonymous';
  source.decoding='async';
  source.onload=()=>{
    const naturalWidth=source.naturalWidth,naturalHeight=source.naturalHeight;
    stages.forEach((stage,i)=>{
      const canvas=document.getElementById(`dynamicSwingFrame${i}`);if(!canvas)return;
      const sourceX=Math.round(i*naturalWidth/4),sourceEndX=Math.round((i+1)*naturalWidth/4);
      const frameWidth=Math.max(1,sourceEndX-sourceX);
      canvas.width=frameWidth;canvas.height=Math.max(1,naturalHeight);canvas.style.aspectRatio=`${canvas.width} / ${canvas.height}`;
      canvas.style.transform=left?'scaleX(-1)':'';
      const ctx=canvas.getContext('2d');ctx.clearRect(0,0,canvas.width,canvas.height);
      ctx.drawImage(source,sourceX,0,frameWidth,naturalHeight,0,0,canvas.width,canvas.height);
      canvas.setAttribute('aria-label',`${stage} swing frame`);
    });
  };
  source.onerror=()=>{const status=document.getElementById('dynamicVisualStatus');if(status)status.textContent='Approved Swing visual could not be loaded.';};
  source.src=plate;
}
function updateGolferVisuals(){
  const api=visualApi(),status=document.getElementById('dynamicVisualStatus');
  if(!api){if(status)status.textContent='Approved Profile visual module is not loaded.';return;}
  const gender=document.getElementById('genderField')?.value||'';
  const ageRange=document.getElementById('ageField')?.value||'';
  const key=api.resolveGolferVisual(gender,ageRange),persona=api.PERSONAS[key],left=isLeftHanded();
  if(!persona){if(status)status.textContent='No governed visual is available for this Profile route.';return;}
  const body=document.getElementById('dynamicMeasurementVisual');
  if(body){body.src=persona.body;body.style.transform=left?'scaleX(-1)':'';body.hidden=false;}
  renderSwingPlateFrames(persona.swing,left);
  if(status){const age=ageRange||'age not provided';const hand=left?'Left-handed':(document.getElementById('handedness')?.value==='RH'?'Right-handed':'handedness not provided');status.textContent=`${key.replaceAll('_',' ')} · ${age} · ${hand}`;}
}
function bindDisclosure(id){
  const button=document.getElementById(id);if(!button)return;
  const target=document.getElementById(button.getAttribute('aria-controls'));if(!target)return;
  const label=button.dataset.label||button.textContent.trim();
  const apply=(open)=>{button.setAttribute('aria-expanded',String(open));target.hidden=!open;button.textContent=`${open?'−':'+'} ${label}`;};
  apply(false);button.addEventListener('click',()=>apply(button.getAttribute('aria-expanded')!=='true'));
}
async function loadSnapshot(){
  const c=root.GALSupabaseProfileClient.ready();const res=await c.rpc('gal_profile_snapshot');if(res.error)throw res.error;
  snapshot=res.data||{facts:[],revision:0};original=flatten(snapshot);
  for(const area of Object.values(fields))for(const [id,key] of area){const el=document.getElementById(id);if(el)el.value=display(original[key]);}
  render();updateGolferVisuals();return snapshot;
}
function escapeHtml(v){return String(v??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));}
function render(){
  const facts=(snapshot&&snapshot.facts)||[];
  document.getElementById('profileRevision').textContent='Profile revision '+((snapshot&&snapshot.revision)??0);
  document.getElementById('profileFactCount').textContent=facts.length+' active '+(facts.length===1?'fact':'facts');
  document.getElementById('profileStatusCopy').textContent=facts.length?'GAL will reuse these facts across recommendation experiences.':'Your Profile is connected but empty. Add only the facts you know.';
  const host=document.getElementById('knownFacts');
  host.innerHTML=facts.length?'<div class="fact-list">'+facts.map(f=>`<div class="fact-row"><span><strong>${escapeHtml(f.key.replaceAll('_',' '))}</strong><small>${escapeHtml((f.quality||'')+' · '+(f.source||f.sourceType||''))}</small></span><span class="fact-value">${escapeHtml(display(f.value)+(f.unit?' '+f.unit:''))}</span></div>`).join('')+'</div>':'<div class="empty-facts">No active Profile facts yet. Unknown stays unknown until you provide or connect reliable information.</div>';
}
function areaPatch(area){const facts={},units={},clear=[];for(const [id,key,unit] of fields[area]){const el=document.getElementById(id);if(!el)continue;const value=coerce(el),before=original[key];if(value===null){if(before!==undefined&&before!==null&&display(before)!=='')clear.push(key);continue;}if(display(before)!==display(value)){facts[key]=value;if(unit)units[key]=unit;}}return {facts,units,clear};}
async function saveArea(area,patch){if(!Object.keys(patch.facts).length&&!patch.clear.length)return null;const c=root.GALSupabaseProfileClient.ready();const res=await c.rpc('gal_profile_apply_patch',{p_area:area,p_facts:patch.facts,p_clear_keys:patch.clear,p_quality:'SELF_REPORTED',p_source_type:'profile_form',p_source_name:'My Golfer Profile',p_confidence:null,p_scope:'global',p_units:patch.units,p_provenance:{surface:'profile.html',ux:'UX11'},p_event_type:'profile_facts_updated'});if(res.error)throw res.error;return res.data;}
async function save(e){e.preventDefault();const btn=document.getElementById('profileSave'),msg=document.getElementById('profileSaveMessage');btn.disabled=true;msg.textContent='Saving governed Profile revision…';try{let changed=0;for(const area of Object.keys(fields)){const p=areaPatch(area);if(Object.keys(p.facts).length||p.clear.length){await saveArea(area,p);changed++;}}await loadSnapshot();msg.textContent=changed?'Profile saved. Your recommendations will use revision '+(snapshot.revision??'—')+'.':'No Profile changes to save.';}catch(err){msg.textContent='Profile save failed: '+(err.message||String(err));}finally{btn.disabled=false;}}
async function mount(){
  ['swingDisclosure','missDisclosure','playDisclosure','connectedDisclosure','reviewDisclosure','auditDisclosure'].forEach(bindDisclosure);
  ['genderField','ageField','handedness'].forEach(id=>document.getElementById(id)?.addEventListener('change',updateGolferVisuals));
  const pc=root.GALSupabaseProfileClient;if(!pc){document.getElementById('profileAuthMessage').textContent='Profile client unavailable.';return;}
  const auth=await pc.currentUser();if(!auth.user){showWorkspace(false);document.getElementById('profileAuthForm').onsubmit=async e=>{e.preventDefault();const m=document.getElementById('profileAuthMessage'),email=document.getElementById('profileEmail').value.trim();m.textContent='Sending secure sign-in link…';const r=await pc.sendMagicLink(email);m.textContent=r.error?'Unable to send link: '+r.error.message:'Check your email for your GAL sign-in link.';};return;}
  showWorkspace(true);try{await loadSnapshot();}catch(err){document.getElementById('profileSaveMessage').textContent='Profile load failed: '+(err.message||String(err));}
  document.getElementById('profileForm').addEventListener('submit',save);
  document.getElementById('profileSignOut').onclick=async()=>{await pc.signOut();location.reload();};
  pc.onAuthStateChange&&pc.onAuthStateChange((event)=>{if(event==='SIGNED_OUT')location.reload();});
}
if(typeof document!=='undefined')document.addEventListener('DOMContentLoaded',mount);
root.GALProfileEditor=Object.freeze({mount,loadSnapshot,areaPatch,saveArea,flatten,updateGolferVisuals,renderSwingPlateFrames});
})(typeof window!=='undefined'?window:globalThis);