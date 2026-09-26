(function(){
'use strict';
let client=null;
const CONSENT_KEY='gal_pending_signup_consent_v1';
function ready(){if(client)return client;const c=window.GAL_SUPABASE_CONFIG;if(!c||!window.supabase||!window.supabase.createClient)return null;client=window.supabase.createClient(c.url,c.publishableKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});return client;}
function callbackUrl(){const path=window.GAL_SUPABASE_CONFIG?.authCallbackPath||'auth-callback.html';try{return new URL(path,location.href).href}catch(e){return path}}
function savePendingConsent(marketing){const cfg=window.GAL_SUPABASE_CONFIG||{};const v={terms:true,privacy:true,marketing:!!marketing,termsVersion:cfg.termsVersion||'unknown',privacyVersion:cfg.privacyVersion||cfg.policyVersion||'unknown',commercialAggregate:false,commercialPolicyVersion:cfg.commercialAggregatePolicyVersion||null,createdAt:new Date().toISOString(),returnTo:'my-gal.html'};localStorage.setItem(CONSENT_KEY,JSON.stringify(v));return v}
function readPendingConsent(){try{return JSON.parse(localStorage.getItem(CONSENT_KEY)||'null')}catch(e){return null}}
function clearPendingConsent(){localStorage.removeItem(CONSENT_KEY)}
async function getSessionUser(){const c=ready();if(!c)return null;const {data,error}=await c.auth.getSession();if(error)return null;return data.session?.user||null}
async function signInEmail(email,marketing){const c=ready();if(!c)throw new Error('Supabase client unavailable');savePendingConsent(marketing);const {error}=await c.auth.signInWithOtp({email,options:{emailRedirectTo:callbackUrl()}});if(error)throw error;return true}
async function signInOAuth(provider,marketing){const c=ready();if(!c)throw new Error('Supabase client unavailable');const state=window.GAL_SUPABASE_CONFIG?.providerReadiness?.[provider];if(state==='CREDENTIALS_REQUIRED')throw new Error(provider==='google'?'Google sign-in is wired but production OAuth credentials are not configured yet.':'Apple sign-in is wired but production Services ID/key configuration is not complete yet.');savePendingConsent(marketing);const {error}=await c.auth.signInWithOAuth({provider,options:{redirectTo:callbackUrl()}});if(error)throw error;}
async function signOut(){const c=ready();if(!c)return;const {error}=await c.auth.signOut();if(error)throw error}
async function recordSignupConsents(marketing,versions={}){const c=ready();const cfg=window.GAL_SUPABASE_CONFIG||{};const {data,error}=await c.rpc('gal_record_signup_consents_v2',{p_terms_version:versions.termsVersion||cfg.termsVersion||'unknown',p_privacy_version:versions.privacyVersion||cfg.privacyVersion||cfg.policyVersion||'unknown',p_marketing:!!marketing,p_commercial_aggregate:!!versions.commercialAggregate,p_commercial_policy_version:versions.commercialPolicyVersion||cfg.commercialAggregatePolicyVersion||null});if(error)throw error;return data}
async function finalizePendingConsent(){const pending=readPendingConsent();const user=await getSessionUser();if(!user)return {ok:false,code:'NO_SESSION'};if(!pending)return {ok:true,code:'NO_PENDING_CONSENT'};await recordSignupConsents(pending.marketing,pending);clearPendingConsent();return {ok:true,code:'CONSENT_RECORDED',marketing:!!pending.marketing};}
function profileAreaFor(factKey,sourceCategory){
 const k=String(factKey||''); const c=String(sourceCategory||'').toLowerCase();
 if(c.includes('driver'))return 'driver'; if(c.includes('golf ball'))return 'golf_ball'; if(c.includes('putter'))return 'putter';
 if(c.includes('wedge'))return 'wedges'; if(c.includes('iron'))return 'irons'; if(c.includes('fairway')||c.includes('hybrid'))return 'fairway_hybrid';
 if(c.includes('platform'))return 'play';
 if(['gender','age_range','handedness','height_in','wrist_to_floor_in','hand_size','dominant_eye','weight_lb','wingspan_in','athletic_background'].includes(k))return 'measurements';
 if(['handicap_range','typical_score_range','primary_goal','play_frequency'].includes(k))return 'game';
 if(['tempo','driver_swing_speed_mph','seven_iron_speed_mph','driver_launch_deg','driver_spin_rpm','driver_carry_yd','seven_iron_carry_yd'].includes(k))return 'swing';
 if(['driver_miss','iron_strike_consistency','contact_divot'].includes(k))return 'miss';
 if(['country','countryCode','region','regionCode','city','city_area','playing_season','elevation_ft','temperature_f','wind_mph','humidity_pct','course_context','turf_conditions','green_speed_preference','location_country'].includes(k))return 'play';
 if(['budget_orientation','feel_preference','visual_confidence','forgiveness_preference'].includes(k))return 'equipment_preferences';
 if(k.startsWith('fairway_hybrid_'))return 'fairway_hybrid'; if(k.startsWith('putter_')||k.includes('alignment_preference')||k.includes('stability_preference'))return 'putter';
 if(k.startsWith('ball_')||k==='short_game_priority')return 'golf_ball'; if(k.startsWith('iron_')||k==='pw_loft_deg')return 'irons'; if(k.startsWith('driver_')||k==='ball_flight')return 'driver';
 return 'connected';
}
async function applyProfileFact(factKey,value,{area=null,source='buyers_guide',source_category=null,confidence=.9,user_confirmed=true,scope='global',stale_after_days=365,collection_method=null,unit=null,observed_at=null,provenance={},event_type='profile_fact_observed'}={}){
 const c=ready(),u=await getSessionUser(); if(!c||!u||value==null)return null;
 const quality=collection_method==='measured'?'MEASURED':(collection_method==='derived'||user_confirmed===false?'INFERRED_ESTIMATED':'SELF_REPORTED');
 const factMetadata={}; factMetadata[factKey]={staleAfterDays:stale_after_days,sourceCategory:source_category||null,userConfirmed:!!user_confirmed};
 const pprov=Object.assign({},provenance||{},{factMetadata});
 const units={}; if(unit)units[factKey]=unit;
 const args={p_area:area||profileAreaFor(factKey,source_category),p_facts:{[factKey]:value},p_clear_keys:[],p_quality:quality,p_source_type:collection_method||'profile_form',p_source_name:source,p_confidence:Number(confidence),p_scope:scope||'global',p_units:units,p_observed_at:observed_at||new Date().toISOString(),p_provenance:pprov,p_event_type:event_type};
 const {data,error}=await c.rpc('gal_profile_apply_patch',args); if(error)throw error; return data;
}
async function addPayload(payload){const c=ready();const u=await getSessionUser();if(!u)return {ok:false,code:'AUTH_REQUIRED'};const {data,error}=await c.rpc('gal_add_to_my_bag',{p_payload:payload});if(error)throw error;return data}
async function loadBag(){const c=ready(),u=await getSessionUser();if(!c||!u)return null;const [{data:bags,error:be},{data:items,error:ie},{data:decisions,error:de},{data:profile,error:pe}]=await Promise.all([c.from('gal_bags').select('*').eq('is_active',true).limit(1),c.from('gal_bag_items').select('*').order('created_at',{ascending:true}),c.from('gal_decision_snapshots').select('*').order('captured_at',{ascending:true}),c.from('gal_users').select('gal_user_id,preferred_market_code,preferred_units,account_status').limit(1)]);if(be||ie||de||pe)throw(be||ie||de||pe);const bag=bags?.[0]||null;return {mode:'REGISTERED_LIVE',user:u,profile:profile?.[0]||null,bagId:bag?.bag_id||null,items:(items||[]).map(x=>({bagItemId:x.bag_item_id,itemType:x.item_type,category:x.category,slotCode:x.slot_code,groupId:x.group_id,canonicalProductId:x.canonical_product_id,canonicalBrandId:x.canonical_brand_id,display:x.display_snapshot||{},configuration:x.configuration||{},status:x.bag_status,countsToward14:x.counts_toward_14,decisionSnapshotId:x.decision_snapshot_id,createdAt:x.created_at,updatedAt:x.updated_at})),decisions:(decisions||[]).map(d=>({decisionSnapshotId:d.decision_snapshot_id,capturedAt:d.captured_at,sourceTool:d.source_tool,sourceToolVersion:d.source_tool_version,userInputs:d.user_inputs||{},metrics:d.metrics||[],reasonSummary:d.reason_summary,canonicalProductIdAtDecision:d.canonical_product_id,canonicalBrandIdAtDecision:d.canonical_brand_id,marketCodeAtDecision:d.market_code,immutable:d.immutable}))};}
function decisionPayload(d){return {sourceTool:d.sourceTool,sourceToolVersion:d.sourceToolVersion,recommendationRank:null,userInputs:d.userInputs||{},metrics:(d.metrics||[]).map(m=>({metricId:m.metricId||m.metric_id,status:m.status||'UNKNOWN',score:m.score??null,modelVersion:m.modelVersion||m.model_version||null})),reasonSummary:d.reasonSummary||null,marketCode:d.marketCodeAtDecision||null}}
async function syncLocalReviewBag(){const local=window.GALMyBag?.read?.();if(!local)return {ok:true,synced:0};let synced=0;for(const d of local.decisions||[]){const its=(local.items||[]).filter(x=>x.decisionSnapshotId===d.decisionSnapshotId&&x.status!=='RETIRED');if(!its.length)continue;const first=its[0];const payload={canonicalProductId:d.canonicalProductIdAtDecision||first.canonicalProductId,status:first.status,decision:decisionPayload(d),components:first.itemType==='CLUB'?its.map(x=>({slotCode:x.slotCode,configuration:x.configuration||{}})):[],configuration:first.configuration||{}};let res=await addPayload(payload);if(!res?.ok)return {ok:false,code:res?.code||'SYNC_FAILED',synced};synced++;}return {ok:true,synced};}

async function exportMyGal(){
 const c=ready(); if(!c) throw new Error('Supabase client unavailable');
 const {data:{session},error}=await c.auth.getSession(); if(error||!session) throw new Error('Sign in to export your My GAL data.');
 const url=(window.GAL_SUPABASE_CONFIG.url||'').replace(/\/$/,'')+'/functions/v1/my-gal-export';
 const res=await fetch(url,{method:'GET',headers:{Authorization:'Bearer '+session.access_token,apikey:window.GAL_SUPABASE_CONFIG.publishableKey}});
 if(!res.ok){let msg='Export failed';try{const j=await res.json();msg=j.message||j.error||msg}catch(e){}throw new Error(msg)}
 const blob=await res.blob(); const cd=res.headers.get('content-disposition')||''; const match=cd.match(/filename="?([^";]+)"?/i); const name=match?match[1]:'my-gal-export.json';
 const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=name;document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(a.href),5000);return true;
}
async function requestAccountDeletion(){const c=ready();if(!c)throw new Error('Supabase client unavailable');const {data,error}=await c.rpc('gal_request_account_deletion');if(error)throw error;return data;}
async function updatePreferredMarket(code){const c=ready(),u=await getSessionUser();if(!c||!u)throw new Error('Sign in to save a default shopping market.');const {data,error}=await c.rpc('gal_update_account_preferences',{p_market_code:code,p_units:null});if(error)throw error;return data;}
async function getAccountProfile(){const c=ready(),u=await getSessionUser();if(!c||!u)return null;const {data,error}=await c.from('gal_users').select('gal_user_id,account_status,preferred_market_code,preferred_units,created_at').limit(1);if(error)throw error;return data?.[0]||null;}
async function getConsentHistory(){const c=ready(),u=await getSessionUser();if(!c||!u)return [];const {data,error}=await c.from('gal_consent_records').select('consent_type,status,policy_version,source,recorded_at').order('recorded_at',{ascending:false});if(error)throw error;return data||[];}
function onAuthStateChange(cb){const c=ready();if(!c)return null;return c.auth.onAuthStateChange((event,session)=>cb(event,session));}
async function status(){const user=await getSessionUser();return {available:!!ready(),authenticated:!!user,user,providerReadiness:window.GAL_SUPABASE_CONFIG?.providerReadiness||{}}}
window.GALRemote={ready,callbackUrl,savePendingConsent,readPendingConsent,clearPendingConsent,getSessionUser,signInEmail,signInOAuth,signOut,recordSignupConsents,finalizePendingConsent,profileAreaFor,applyProfileFact,addPayload,loadBag,syncLocalReviewBag,exportMyGal,requestAccountDeletion,updatePreferredMarket,getAccountProfile,getConsentHistory,onAuthStateChange,status};
})();