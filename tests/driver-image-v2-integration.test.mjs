import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
globalThis.window = globalThis;

function loadScript(name) {
  const file = path.join(root, name);
  const code = fs.readFileSync(file, 'utf8');
  vm.runInThisContext(code, { filename: name });
}

loadScript('drivers__data.js');
loadScript('drivers__media.js');

const drivers = globalThis.GAL_DRIVERS;
const media = globalThis.GALDriverMedia;

assert.ok(Array.isArray(drivers), 'GAL_DRIVERS must be an array');
assert.equal(drivers.length, 64, 'must preserve all 64 canonical Driver records');
assert.equal(new Set(drivers.map(d => d.canonicalProductId)).size, 64, 'canonical Driver IDs must be unique');

const approved = drivers.filter(d => d.imageStatus === 'VERIFIED_REVIEW_ASSET');
const holds = drivers.filter(d => d.imageStatus !== 'VERIFIED_REVIEW_ASSET');
assert.equal(approved.length, 54, 'must expose exactly 54 governed Driver images');
assert.equal(holds.length, 10, 'must preserve exactly 10 governed image holds');

const approvedUrls = approved.map(d => d.imageAssetPath);
assert.equal(new Set(approvedUrls).size, 54, 'every approved Driver must have a unique governed image URL');
for (const d of approved) {
  assert.match(d.imageAssetPath, /^https:\/\/res\.cloudinary\.com\/bevzhkct\/image\/upload\/v\d+\/.*\.webp$/, `${d.canonicalProductId} must use a versioned Cloudinary WebP`);
  assert.equal(d.imageNormalizedWidth, 1200, `${d.canonicalProductId} must retain 1200px governed width`);
  assert.equal(d.imageNormalizedHeight, 1200, `${d.canonicalProductId} must retain 1200px governed height`);
}
for (const d of holds) {
  assert.ok(!d.imageAssetPath, `${d.canonicalProductId} hold must not expose a production image URL`);
  assert.ok(!d.imageCardAssetPath, `${d.canonicalProductId} hold must not expose a card image URL`);
}

assert.equal(typeof media.resolve, 'function', 'media resolver must expose resolve()');
assert.equal(typeof media.picture, 'function', 'media resolver must expose picture()');

const sample = approved[0];
const resolved = media.resolve(sample, 480);
assert.equal(resolved.available, true, 'approved Driver must resolve as available');
assert.equal(resolved.masterUrl, sample.imageAssetPath, 'resolver must preserve canonical governed master URL');
assert.match(resolved.src, /\/image\/upload\/f_auto,q_auto,w_480\/v\d+\//, 'responsive URL must add delivery transforms before the version segment');
assert.equal(resolved.alt, sample.imageAltText, 'resolver must use governed alt text');

const held = media.resolve(holds[0], 480);
assert.equal(held.available, false, 'hold must resolve as unavailable');
assert.equal(held.src, null, 'hold must never resolve a fallback image');
assert.equal(held.masterUrl, null, 'hold must never expose a master URL');
assert.ok(held.status, 'hold state must preserve governance status');

const picture = media.picture(sample);
assert.equal(picture.available, true, 'picture() must support approved records');
assert.ok(picture.srcset.includes('w_320'), 'picture() must include a 320px responsive source');
assert.ok(picture.srcset.includes('w_640'), 'picture() must include a 640px responsive source');
assert.ok(picture.srcset.includes('w_960'), 'picture() must include a 960px responsive source');

console.log('PASS driver image v2 data/media contract');

const html = fs.readFileSync(path.join(root, 'drivers.html'), 'utf8');
const appSource = fs.readFileSync(path.join(root, 'drivers__app.js'), 'utf8');
const css = fs.readFileSync(path.join(root, 'drivers__styles.css'), 'utf8');

assert.match(html, /drivers__styles\.css/, 'Driver page must load Driver-specific styles');
assert.match(html, /drivers__data\.js[\s\S]*drivers__media\.js[\s\S]*drivers__app\.js/, 'Driver modules must load data -> media -> app in order');
assert.match(html, /id="driverGrid"/, 'Driver page must expose catalog grid');
assert.match(html, /id="driverCompare"/, 'Driver page must expose compare surface');
assert.match(html, /id="driverBag"/, 'Driver page must expose bag surface');
assert.match(html, /id="driverDetail"/, 'Driver page must expose detail surface');

assert.doesNotMatch(appSource, /res\.cloudinary\.com/, 'Driver app must never hard-code image URLs outside the media resolver');
assert.match(appSource, /GALDriverMedia\.picture/, 'Driver app must consume the governed media resolver');
for (const surface of ['catalog','detail','compare','bag']) {
  assert.match(appSource, new RegExp(`mediaMarkup\\(.*${surface}`, 'i'), `${surface} must render through mediaMarkup()`);
}
assert.match(appSource, /MAX_BAG_CLUBS\s*=\s*14/, 'bag behavior must enforce the 14-club warning contract');
assert.match(appSource, /DUPLICATE_DRIVER/, 'internal duplicate Driver status code must remain available to the app contract');
assert.doesNotMatch(appSource, /statusMessage\(DUPLICATE_DRIVER\s*\+/, 'golfer-facing duplicate warning must not prepend the internal status code');
assert.match(appSource, /canonicalProductId/, 'bag and compare state must use canonical product identity');
assert.match(appSource, /Image coming soon/, 'hold records must render a controlled image placeholder');
assert.match(css, /\.driver-image-hold/, 'controlled hold state must be styled');

console.log('PASS driver equipment UI contract');
