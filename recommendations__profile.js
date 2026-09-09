(function(root){
'use strict';
const PREVIEW={schemaVersion:'GAL-GIP-1.0',profileId:'staging-preview',revision:0,preview:true,facts:[
  {area:'swing',key:'driver_swing_speed_mph',value:94,unit:'mph',quality:'SELF_REPORTED',confidence:.75},
  {area:'miss',key:'driver_primary_miss',value:'right',quality:'SELF_REPORTED',confidence:.75},
  {area:'swing',key:'driver_launch_preference',value:'mid-high',quality:'SELF_REPORTED',confidence:.75},
  {area:'game',key:'handicap_index',value:14,quality:'SELF_REPORTED',confidence:.75},
  {area:'play',key:'top_bag_target_yards',value:220,unit:'yards',quality:'INFERRED_ESTIMATED',confidence:.5}
]};
function flatten(snapshot){const out={};((snapshot&&snapshot.facts)||[]).forEach(f=>{out[f.key]=f.value;});return out;}
async function load(){
  if(root.GALProfileService&&typeof root.GALProfileService.snapshot==='function'){
    const s=await root.GALProfileService.snapshot(); if(s)return {snapshot:s,source:'GALProfileService',preview:false};
  }
  if(root.galSupabase&&typeof root.galSupabase.rpc==='function'){
    const res=await root.galSupabase.rpc('gal_profile_snapshot');
    if(res&&!res.error&&res.data)return {snapshot:res.data,source:'gal_profile_snapshot',preview:false};
  }
  if(root.GAL_PROFILE_SNAPSHOT)return {snapshot:root.GAL_PROFILE_SNAPSHOT,source:'window.GAL_PROFILE_SNAPSHOT',preview:false};
  try{const raw=root.localStorage&&root.localStorage.getItem('gal_profile_snapshot_v1'); if(raw)return {snapshot:JSON.parse(raw),source:'local-preview-cache',preview:true};}catch(e){}
  return {snapshot:PREVIEW,source:'staging-preview-profile',preview:true};
}
root.GALRecommendationProfile=Object.freeze({load,flatten,PREVIEW});
})(typeof window!=='undefined'?window:globalThis);