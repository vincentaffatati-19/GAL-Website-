import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const rootDir=path.resolve(here,'..');
const ids=['driverStatus','driverGrid','driverCount','driverCompareGrid','driverBagCount','driverBagWarning','driverBagList','driverBrand','driverProfile','driverSearch','driverImageFilter','driverDetail','driverDetailContent'];
const elements=new Map(ids.map(id=>[id,{id,innerHTML:'',textContent:'',value:'all',dataset:{},addEventListener(){},setAttribute(){},removeAttribute(){},showModal(){this.open=true},close(){this.open=false}}]));
elements.get('driverSearch').value='';
const documentStub={readyState:'complete',getElementById:id=>elements.get(id)||null,addEventListener(){}};
const storage=new Map();
const localStorageStub={getItem:k=>storage.has(k)?storage.get(k):null,setItem:(k,v)=>storage.set(k,String(v)),removeItem:k=>storage.delete(k),clear:()=>storage.clear()};

globalThis.window=globalThis;
globalThis.document=documentStub;
globalThis.localStorage=localStorageStub;
function load(name){vm.runInThisContext(fs.readFileSync(path.join(rootDir,name),'utf8'),{filename:name});}
load('drivers__data.js');load('drivers__media.js');load('drivers__app.js');

assert.equal(globalThis.GAL_DRIVER_APP_SELF_TEST.passed,true,'app self-test must pass');
assert.equal(globalThis.GAL_DRIVER_APP_SELF_TEST.records,64);
assert.equal(globalThis.GAL_DRIVER_APP_SELF_TEST.approved,54);
assert.equal(globalThis.GAL_DRIVER_APP_SELF_TEST.holds,10);
const grid=elements.get('driverGrid').innerHTML;
assert.equal((grid.match(/data-driver=/g)||[]).length,64,'catalog must render 64 Driver cards');
assert.equal((grid.match(/<img /g)||[]).length,54,'catalog must render images only for 54 governed records');
assert.equal((grid.match(/Image coming soon/g)||[]).length,10,'catalog must render 10 controlled hold states');

const app=globalThis.GALDriversAppContract;
app.addToBag(globalThis.GAL_DRIVERS[0].canonicalProductId);
assert.equal(JSON.parse(localStorage.getItem('gal_equipment_bag_v1')).length,1,'first Driver should add to bag');
app.addToBag(globalThis.GAL_DRIVERS[1].canonicalProductId);
assert.equal(JSON.parse(localStorage.getItem('gal_equipment_bag_v1')).length,2,'second Driver is allowed with duplicate-category warning');
assert.match(elements.get('driverStatus').textContent,/DUPLICATE_DRIVER/,'second Driver must emit duplicate category warning');

localStorage.setItem('gal_equipment_bag_v1',JSON.stringify(globalThis.GAL_DRIVERS.slice(0,14).map(d=>({canonicalProductId:d.canonicalProductId,productType:'Driver',brand:d.brand,model:d.model}))));
app.addToBag(globalThis.GAL_DRIVERS[14].canonicalProductId);
assert.equal(JSON.parse(localStorage.getItem('gal_equipment_bag_v1')).length,14,'15th club must not be added');
assert.match(elements.get('driverStatus').textContent,/14-club limit reached/,'14-club guard must surface an error');

console.log('PASS driver image v2 runtime contract');
