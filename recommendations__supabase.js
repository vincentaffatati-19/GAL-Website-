(function(root){
'use strict';
const VERSION='2.116.0';
const URL='https://ylrxwtbzavhxxpoqqmho.supabase.co';
const PUBLISHABLE_KEY='sb_publishable_Jgy4llwo5UhX4mg3EZ6VSA_xhyPOcVp';
let client=null;
function ready(){
  if(client)return client;
  if(!root.supabase||typeof root.supabase.createClient!=='function')return null;
  client=root.supabase.createClient(URL,PUBLISHABLE_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
  root.galSupabase=client;
  return client;
}
async function currentUser(){
  const c=ready(); if(!c)return {user:null,error:new Error('Supabase client unavailable')};
  const {data,error}=await c.auth.getUser();
  return {user:data&&data.user||null,error:error||null};
}
function redirectUrl(){return root.location?root.location.origin+root.location.pathname:undefined}
async function sendMagicLink(email){
  const c=ready(); if(!c)return {error:new Error('Supabase client unavailable')};
  return c.auth.signInWithOtp({email:String(email||'').trim(),options:{shouldCreateUser:true,emailRedirectTo:redirectUrl()}});
}
async function signOut(){const c=ready();return c?c.auth.signOut():{error:new Error('Supabase client unavailable')}}
function onAuthStateChange(cb){const c=ready();return c?c.auth.onAuthStateChange(cb):{data:{subscription:{unsubscribe(){}}}}}
root.GALSupabaseProfileClient=Object.freeze({VERSION,URL,ready,currentUser,sendMagicLink,signOut,onAuthStateChange});
ready();
})(typeof window!=='undefined'?window:globalThis);
