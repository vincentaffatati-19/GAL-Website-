const fs=require('fs');
const path=require('path');
const assert=require('assert');
const ROOT=path.resolve(__dirname,'..');
const read=(name)=>fs.readFileSync(path.join(ROOT,name),'utf8');

const bag=read('my-gal.html');
const bagCss=read('my-gal__styles.css');
const bagApp=read('my-gal__app.js');
const profile=read('profile.html');
const profileCss=read('profile__styles.css');
const profileApp=read('profile__app.js');
const recs=read('recommendations.html');

// My GAL must use governed photographic presentation layers, never CSS-drawn scenery/bags.
for(const token of ['class="sky"','class="tree-line"','class="fairway"','class="teeing-ground"','class="bag-mouth"','class="bag-body"','class="bag-pocket"','class="club-fan"']){
  assert(!bag.includes(token),`UX11 forbids crude presentation token ${token}`);
}
for(const token of ['.sky{','.tree-line{','.fairway{','.teeing-ground{','.bag-mouth{','.bag-body{','.bag-pocket{','.club-stick{']){
  assert(!bagCss.includes(token),`UX11 forbids CSS-drawn presentation rule ${token}`);
}
assert(bag.includes('id="teeBoxBackground"'),'UX11 My GAL requires a photographic tee-box image layer');
assert(bag.includes('id="bagVisualImage"'),'UX11 My GAL requires an approved GAL bag image layer');
assert(bag.includes('data-tee-theme="coastal"')&&bag.includes('data-tee-theme="cliffs"'),'UX11 must expose approved independent tee-box presentation choices');
assert(bag.includes('data-bag-visual="tour"')&&bag.includes('data-bag-visual="stand"'),'UX11 must expose approved independent bag presentation choices');
for(const asset of ['coastal-01.webp','cliffs-01.webp','gal-tour-bag.png','gal-stand-bag.png']){
  assert(bagApp.includes(asset)||bag.includes(asset),`UX11 must bind exact recovered asset ${asset}`);
}
assert(!bagApp.includes('const health='),'UX11 forbids invented Bag Health formula');
assert(!bagApp.includes("p.health+'/100'"),'UX11 forbids invented Bag Health score rendering');
assert(!bagApp.includes("count?'Good':'Review'"),'UX11 forbids inferred Good/Review equipment judgments');
assert(bagApp.includes('duplicate'),'UX11 must preserve an explicit duplicate-club warning path');
assert(bagApp.includes("catOf(x)!=='GOLF_BALL'"),'Golf ball must not count toward the 14-club limit');

// My GAL navigation is five primary destinations on every UX11 account surface; Golfer Profile stays separate.
const primaryLabels=['Today','My Bag','Insights','Guides','Progress'];
const assertMyGalNav=(surface,name)=>{
  for(const label of primaryLabels) assert(surface.includes(`>${label}</a>`),`${name} My GAL primary navigation missing ${label}`);
  assert(surface.includes('class="profile-control"')||surface.includes('data-profile-control'),`${name} must keep Golfer Profile as a separate destination/control`);
};
assertMyGalNav(bag,'My Bag');
assertMyGalNav(profile,'Golfer Profile');
assertMyGalNav(recs,'Recommendations');

// Governed profile visual resolver is a required locked dependency.
const visualPath=path.join(ROOT,'profile__visuals.js');
assert(fs.existsSync(visualPath),'profile__visuals.js must implement the locked UX11 visual resolver');
const visuals=require(visualPath);
const personaKeys=['junior_male','junior_female','male_young','female_young','male_middle','female_middle','male_mature','female_mature','male_senior','female_senior','neutral_junior','neutral_adult'];
assert.deepStrictEqual([...visuals.PERSONA_KEYS].sort(),[...personaKeys].sort(),'UX11 must expose exactly 12 base persona families');
for(const key of personaKeys){
  const record=visuals.PERSONAS[key];
  assert(record&&record.body&&record.swing,`Missing governed Body/Swing pair for ${key}`);
}
const genders=['','Male','Female','Non-binary / another identity','Prefer not to say'];
const ages=['','Under 18','18–24','25–34','35–44','45–54','55–64','65–74','75+','Prefer not to say'];
const family=(key)=>key.startsWith('male_')||key==='junior_male'?'male':key.startsWith('female_')||key==='junior_female'?'female':'neutral';
const expectedFamily=(gender,age)=>age==='Under 18'?(gender==='Male'?'male':gender==='Female'?'female':'neutral'):(gender==='Male'?'male':gender==='Female'?'female':'neutral');
let matrix=0;
for(const gender of genders){
  for(const age of ages){
    const key=visuals.resolveGolferVisual(gender,age);
    assert.strictEqual(family(key),expectedFamily(gender,age),`Gender×Age route mismatch for ${gender||'unknown'} / ${age||'unknown'} -> ${key}`);
    matrix++;
  }
}
assert.strictEqual(matrix,50,'Full Gender × Age matrix must contain 50 cases');
assert.strictEqual(visuals.resolveGolferVisual('Male',''),'male_age_unspecified');
assert.strictEqual(visuals.resolveGolferVisual('Female',''),'female_age_unspecified');
assert.strictEqual(visuals.resolveGolferVisual('Male','Prefer not to say'),'male_age_unspecified');
assert.strictEqual(visuals.resolveGolferVisual('Female','Prefer not to say'),'female_age_unspecified');
assert.strictEqual(visuals.resolveGolferVisual('Male','65–74'),'male_senior');
assert.strictEqual(visuals.resolveGolferVisual('Male','75+'),'male_senior');
assert.strictEqual(visuals.resolveGolferVisual('Female','65–74'),'female_senior');
assert.strictEqual(visuals.resolveGolferVisual('Female','75+'),'female_senior');
for(const alias of ['male_age_unspecified','female_age_unspecified']) assert(visuals.PERSONAS[alias]&&visuals.PERSONAS[alias].ageClaim===null,`${alias} must not make an age claim`);

// Body/Swing presentation parity and native-aspect Swing rendering.
assert(profile.includes('id="dynamicMeasurementVisual"'),'Profile requires dynamic Body visual');
assert(profile.includes('id="swingStages"'),'Profile requires four-stage Swing visual');
for(const stage of ['Address','Backswing','Impact','Finish']) assert(profile.includes(`>${stage}<`),`Swing stage missing ${stage}`);
assert(profileCss.includes('height:auto'),'Swing/body images must preserve native source aspect ratio');
assert(!profileCss.includes('background-size:400% 100%')&&!profileApp.includes("backgroundSize='400% 100%'")&&!profileApp.includes('backgroundSize="400% 100%"'),'UX11 forbids stretched fixed-height Swing plate cropping');
assert(profileApp.includes('scaleX(-1)')||profileCss.includes('scaleX(-1)'),'Left-handed photographic mirror behavior missing');
assert(profileApp.includes('resolveGolferVisual')||profile.includes('profile__visuals.js'),'Profile must route Body and Swing through the governed resolver');

// Six governed long sections default collapsed with accessible +/- disclosure controls.
for(const id of ['swingDisclosure','missDisclosure','playDisclosure','connectedDisclosure','reviewDisclosure','auditDisclosure']){
  assert(profile.includes(`id="${id}"`),`Missing collapsed profile disclosure ${id}`);
}
assert(profileApp.includes('aria-expanded')||profile.includes('aria-expanded="false"'),'Profile disclosures must maintain aria-expanded state');

// The approved Your Miss reference art is inherited exactly and remains informational, isolated from Save controls.
assert(profile.includes('class="miss-reference"'),'Your Miss must retain the approved reference-art container');
assert(profile.includes('src="profile__miss-reference.png"'),'Your Miss must bind the exact approved reference asset');
assert(profileCss.includes('.miss-reference')&&profileCss.includes('object-fit:contain'),'Your Miss art must remain fully visible rather than hero-cropped');
const missStart=profile.indexOf('id="missContent"');
const missArt=profile.indexOf('class="miss-reference"');
const saveBar=profile.indexOf('class="save-bar"');
assert(missStart>=0&&missArt>missStart&&saveBar>missArt,'Your Miss reference art must remain inside the Miss section and isolated above Save controls');

// UX10.03 scorecard direction remains excluded; Top 3 remains category-contextual only.
const active=[bag,profile,recs,bagApp,profileApp].join('\n');
for(const forbidden of ['Better Bag Priority Index','Your Top 3 Better Bag Priorities']) assert(!active.includes(forbidden),`Rejected UX10.03 hierarchy restored: ${forbidden}`);
assert(!recs.includes('cross-category'),'Recommendations must not promote cross-category priority scoring');
assert(recs.includes('Equipment Categories')||recs.includes('equipment category'),'Recommendations must retain equipment-category context');

console.log('PASS UX11 My GAL intelligence regression contract');
