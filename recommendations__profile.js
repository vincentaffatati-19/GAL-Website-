(function(root){
'use strict';
function flatten(snapshot){const out={};((snapshot&&snapshot.facts)||[]).forEach(f=>{out[f.key]=f.value;});return out;}
async function load(){
  if(root.GALProfileService&&typeof root.GALProfileService.snapshot==='function'){
    const s=await root.GALProfileService.snapshot(); if(s)return {snapshot:s,source:'GALProfileService',authRequired:false,empty:!((s.facts||[]).length)};
  }
  if(root.GAL_PROFILE_SNAPSHOT)return {snapshot:root.GAL_PROFILE_SNAPSHOT,source:'window.GAL_PROFILE_SNAPSHOT',authRequired:false,empty:!((root.GAL_PROFILE_SNAPSHOT.facts||[]).length)};
  const pc=root.GALSupabaseProfileClient;
  if(!pc)return {snapshot:null,source:'auth-unavailable',authRequired:true,error:new Error('Profile client unavailable')};
  const auth=await pc.currentUser();
  if(auth.error&&!auth.user)return {snapshot:null,source:'auth-required',authRequired:true,error:auth.error};
  if(!auth.user)return {snapshot:null,source:'auth-required',authRequired:true,error:null};
  const c=pc.ready();
  const res=await c.rpc('gal_profile_snapshot');
  if(res.error)return {snapshot:null,source:'gal_profile_snapshot',authRequired:false,authenticated:true,user:auth.user,error:res.error};
  const s=res.data;
  return {snapshot:s,source:'gal_profile_snapshot',authRequired:false,authenticated:true,user:auth.user,empty:!s||!((s.facts||[]).length)};
}
root.GALRecommendationProfile=Object.freeze({load,flatten});
})(typeof window!=='undefined'?window:globalThis);
