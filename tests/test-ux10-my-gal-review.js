const fs=require('fs'),path=require('path'),assert=require('assert');
const ROOT=path.resolve(__dirname,'..');
function read(name){return fs.readFileSync(path.join(ROOT,name),'utf8');}
const bag=read('my-gal.html');
const profile=read('profile.html');
const profileApp=read('profile__app.js');
const recs=read('recommendations.html');
// UX11 supersedes the old UX10 teeScene/back-middle-forward presentation controls while preserving the photographic My Bag intent.
assert(bag.includes('id="teeBoxBackground"'),'My Bag must retain the approved photographic tee-box scene');
assert(bag.includes('id="bagStage"'),'My Bag must retain the central bag stage');
assert(bag.includes('data-tee-theme="coastal"')&&bag.includes('data-tee-theme="cliffs"'),'My Bag must expose the approved UX11 tee-box presentation choices');
assert(bag.includes('href="profile.html"'),'My Bag must link to Golfer Profile');
assert(bag.includes('href="recommendations.html"'),'My Bag must link to Bag Needs / Recommendations');
assert(bag.includes('my-gal__app.js'),'My Bag must load its governed projection app');
for(const id of ['handedness','handicapIndex','skillBand','driverSwingSpeed','driverPrimaryMiss','driverLaunchPreference','topBagTarget','homePlayLocation'])assert(profile.includes(`id="${id}"`),`Profile missing ${id}`);
assert(profile.includes('profile__app.js'),'Profile must load its application module');
assert(profileApp.includes("rpc('gal_profile_apply_patch'"),'Profile save must call governed patch RPC');
assert(profileApp.includes("rpc('gal_profile_snapshot'"),'Profile must reload governed snapshot');
assert(profileApp.includes("p_quality:'SELF_REPORTED'"),'Profile edits must be self-reported facts');
assert(recs.includes('href="my-gal.html"')&&recs.includes('href="profile.html"'),'Recommendations must expose corrected My GAL navigation');
console.log('PASS UX10 compatibility contracts under approved UX11 presentation');
