const fs=require('fs'),vm=require('vm'),assert=require('assert');
let bag=[];
const ctx={globalThis:null,window:undefined,document:undefined,confirm:()=>true,localStorage:{getItem:()=>null,setItem:()=>{}},
 GAL_DRIVERS:[{id:'GAL-DRV-1',canonicalProductId:'GAL-DRV-1',brand:'A',model:'Driver',priceUSD:null,imageStatus:'VERIFIED_REVIEW_ASSET',imageAssetPath:'x'}],
 GALFairwayHybridData:[{product_id:'GAL-FH-1',brand:'B',model:'Fairway',category:'FAIRWAY',club:'7W',loft_deg:21,current_price_usd:null,imageStatus:'SOURCE_RECOVERY_HOLD'}],
 GALDriverMedia:{picture:r=>({available:true,src:'driver.webp',alt:'driver'})},GALFairwayHybridMedia:{picture:r=>({available:false,label:'Image coming soon'})},
 GALBagAdapter:{load:()=>bag.slice(),save:x=>{bag=x.slice();}}};ctx.globalThis=ctx;vm.createContext(ctx);vm.runInContext(fs.readFileSync(require('path').resolve(__dirname,'../recommendations__app.js'),'utf8'),ctx);
const app=ctx.GALRecommendationApp,drv={canonicalProductId:'GAL-DRV-1',category:'DRIVER'},fw={canonicalProductId:'GAL-FH-1',category:'FAIRWAY'};
assert.equal(app.productFor(drv).model,'Driver');assert.equal(app.productFor(fw).club,'7W');assert.equal(app.mediaFor(fw).available,false);assert.equal(app.money(null),'—');
assert.equal(app.add(drv),'Added');assert.equal(bag[0].product_id,'GAL-DRV-1');assert.equal(app.add(drv),'Already in Bag');bag=Array.from({length:14},(_,i)=>({product_id:'X'+i,category:'X'+i}));assert.equal(app.add(fw),'Bag full (14)');assert.equal(bag.length,14);
console.log('PASS recommendation runtime contracts');
