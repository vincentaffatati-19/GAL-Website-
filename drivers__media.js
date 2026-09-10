(function(root){
"use strict";
const APPROVED="VERIFIED_REVIEW_ASSET";
const WIDTHS=Object.freeze([320,640,960]);

function clampWidth(width){
  const n=Number(width);
  if(!Number.isFinite(n))return 640;
  return Math.max(160,Math.min(1200,Math.round(n)));
}
function responsiveUrl(masterUrl,width){
  if(!masterUrl||typeof masterUrl!=="string")return null;
  const w=clampWidth(width);
  return masterUrl.replace("/image/upload/","/image/upload/f_auto,q_auto,w_"+w+"/");
}
function unavailable(record){
  return {available:false,src:null,masterUrl:null,
    alt:record&&record.imageAltText?record.imageAltText:((record&&record.brand||"Driver")+" "+(record&&record.model||"")),
    status:record&&record.imageStatus?record.imageStatus:"IMAGE_UNAVAILABLE",
    reviewStatus:record&&record.imageReviewStatus?record.imageReviewStatus:null,
    label:"Image coming soon"};
}
function resolve(record,width){
  if(!record||record.imageStatus!==APPROVED||!record.imageAssetPath)return unavailable(record);
  return {available:true,src:responsiveUrl(record.imageAssetPath,width),masterUrl:record.imageAssetPath,
    alt:record.imageAltText||((record.brand||"")+" "+(record.model||"")+" driver").trim(),
    status:record.imageStatus,reviewStatus:record.imageReviewStatus||null,width:clampWidth(width)};
}
function picture(record){
  const base=resolve(record,640);
  if(!base.available)return base;
  const srcset=WIDTHS.map(w=>responsiveUrl(record.imageAssetPath,w)+" "+w+"w").join(", ");
  return Object.assign({},base,{src:responsiveUrl(record.imageAssetPath,640),srcset,
    sizes:"(max-width: 640px) 92vw, (max-width: 1024px) 46vw, 300px"});
}
root.GALDriverMedia=Object.freeze({APPROVED,WIDTHS,resolve,picture,responsiveUrl});
})(typeof window!=="undefined"?window:globalThis);
