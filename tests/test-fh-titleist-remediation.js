const fs=require('fs'),vm=require('vm'),assert=require('assert');
const root={};root.globalThis=root;root.window=undefined;
vm.createContext(root);
for(const f of ['fairway-hybrids__data.js','fairway-hybrids__media.js']) vm.runInContext(fs.readFileSync(f,'utf8'),root,{filename:f});
const D=root.GALFairwayHybridData,M=root.GALFairwayHybridMedia;
assert.equal(D.length,71);
assert.equal(D.filter(r=>r.imageStatus==='VERIFIED_REVIEW_ASSET').length,68,'68 approved after Titleist remediation');
assert.equal(D.filter(r=>r.imageStatus!=='VERIFIED_REVIEW_ASSET').length,3,'only three Mizuno holds remain');
for(const r of D.filter(r=>r.brand==='Titleist')){
  assert.equal(r.imageStatus,'VERIFIED_REVIEW_ASSET',r.product_id+' must be approved');
  const m=M.resolve(r,640);
  assert.equal(m.available,true,r.product_id+' must resolve governed media');
  assert.ok(m.masterUrl.includes('$rid_!'+r.product_id+'!'),r.product_id+' must use record-specific transform');
  assert.ok(m.masterUrl.endsWith('.webp'),r.product_id+' master must be WebP');
}
for(const r of D.filter(r=>r.brand==='Mizuno')) assert.equal(M.resolve(r,640).available,false,'Mizuno hold must not render img');
console.log('PASS Titleist fairway/hybrid remediation contract');
