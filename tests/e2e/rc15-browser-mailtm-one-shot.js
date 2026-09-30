const fs = require('fs');
const crypto = require('crypto');
const assert = require('assert');
const { chromium } = require('playwright');

const TARGET = process.env.RC15_TARGET || 'http://127.0.0.1:4173/rc15-browser-acceptance.html';
const activeClubs = bag => (bag?.items || []).filter(x => x.itemType === 'CLUB' && x.status === 'IN_BAG' && x.countsToward14);
const activeDrivers = bag => activeClubs(bag).filter(x => x.category === 'DRIVER' || x.slotCode === 'D');
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitText(page, selector, patterns, timeout = 20000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const text = ((await page.locator(selector).textContent().catch(() => '')) || '').trim();
    if (patterns.some(p => text.includes(p))) return text;
    await page.waitForTimeout(200);
  }
  throw new Error(`Timed out waiting for ${selector}: ${patterns.join(' | ')}`);
}

async function loadBag(page) {
  return await page.evaluate(async () => await window.__RC15_ACCEPTANCE.loadBag());
}

function allStrings(v, out = []) {
  if (typeof v === 'string') out.push(v);
  else if (Array.isArray(v)) v.forEach(x => allStrings(x, out));
  else if (v && typeof v === 'object') Object.values(v).forEach(x => allStrings(x, out));
  return out;
}

function linksFrom(v) {
  const out = [];
  for (const s of allStrings(v)) {
    for (const m of s.matchAll(/https?:\/\/[^\s"'<>]+/g)) out.push(m[0].replace(/&amp;/g, '&'));
  }
  return [...new Set(out)];
}

async function createMailbox() {
  const domainsRes = await fetch('https://api.mail.tm/domains?page=1');
  assert(domainsRes.ok, `mail.tm domains failed: ${domainsRes.status}`);
  const domains = await domainsRes.json();
  const domain = (domains['hydra:member'] || []).find(d => d.isActive && !d.isPrivate) || (domains['hydra:member'] || []).find(d => d.isActive);
  assert(domain?.domain, 'mail.tm returned no active domain');

  const local = `rc15-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
  const address = `${local}@${domain.domain}`;
  const password = `MailTm!${crypto.randomBytes(18).toString('hex')}Aa7`;
  const createRes = await fetch('https://api.mail.tm/accounts', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ address, password })
  });
  assert(createRes.ok, `mail.tm account create failed: ${createRes.status} ${await createRes.text()}`);
  const account = await createRes.json();

  const tokenRes = await fetch('https://api.mail.tm/token', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ address, password })
  });
  assert(tokenRes.ok, `mail.tm token failed: ${tokenRes.status}`);
  const tokenBody = await tokenRes.json();
  assert(tokenBody.token, 'mail.tm token missing');
  return { id: account.id, address, token: tokenBody.token };
}

async function deleteMailbox(mailbox) {
  if (!mailbox?.id || !mailbox?.token) return;
  await fetch(`https://api.mail.tm/accounts/${encodeURIComponent(mailbox.id)}`, {
    method: 'DELETE',
    headers: { authorization: `Bearer ${mailbox.token}` }
  }).catch(() => {});
}

async function confirmationLink(mailbox) {
  const deadline = Date.now() + 90000;
  while (Date.now() < deadline) {
    const listRes = await fetch('https://api.mail.tm/messages?page=1', {
      headers: { authorization: `Bearer ${mailbox.token}` }
    });
    if (listRes.ok) {
      const list = await listRes.json();
      const messages = list['hydra:member'] || [];
      if (messages.length) {
        const msgRes = await fetch(`https://api.mail.tm/messages/${encodeURIComponent(messages[0].id)}`, {
          headers: { authorization: `Bearer ${mailbox.token}` }
        });
        if (msgRes.ok) {
          const body = await msgRes.json();
          const links = linksFrom(body);
          const verify = links.find(x => x.includes('/auth/v1/verify') || x.includes('token_hash=') || x.includes('token='));
          if (verify) return verify;
        }
      }
    }
    await sleep(1500);
  }
  throw new Error('Supabase confirmation email/link not received in mail.tm inbox');
}

async function confirmInCurrentOrigin(page, verifyUrl) {
  const u = new URL(verifyUrl);
  const tokenHash = u.searchParams.get('token_hash') || u.searchParams.get('token');
  assert(tokenHash, 'Confirmation token hash not found in email link');
  const r = await page.evaluate(async token_hash => {
    const c = window.GALRemote.ready();
    const { data, error } = await c.auth.verifyOtp({ token_hash, type: 'email' });
    return { error: error?.message || null, user: data?.user ? { id: data.user.id } : null, session: !!data?.session };
  }, tokenHash);
  assert(!r.error, r.error || 'verifyOtp failed');
  assert(r.session, 'verifyOtp did not establish session');
  return r;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const result = { checks: {}, status: 'RUNNING' };
  let mailbox = null;
  const appPassword = `Rc15!${crypto.randomBytes(24).toString('hex')}Aa7`;

  try {
    mailbox = await createMailbox();
    const email = mailbox.address;
    result.synthetic_email = email;

    const c1 = await browser.newContext();
    const p1 = await c1.newPage();
    await p1.goto(TARGET, { waitUntil: 'domcontentloaded' });
    await p1.waitForFunction(() => !!window.__RC15_ACCEPTANCE && !!window.GALRemote?.ready?.());

    await p1.fill('#email', email);
    await p1.fill('#password', appPassword);
    await p1.click('#signUp');
    let auth = await waitText(p1, '#authStatus', ['ACCOUNT CREATED', 'ERROR']);
    assert(!auth.startsWith('ERROR'), auth);
    if (!auth.includes('session ACTIVE')) {
      const verify = await confirmationLink(mailbox);
      await confirmInCurrentOrigin(p1, verify);
    }
    const user1 = await p1.evaluate(async () => {
      const c = window.GALRemote.ready();
      const { data, error } = await c.auth.getUser();
      return { error: error?.message || null, id: data?.user?.id || null };
    });
    assert(!user1.error && user1.id, user1.error || 'No authenticated user after confirmation');
    result.synthetic_user_id = user1.id;
    result.checks.synthetic_account = 'PASS';

    const empty = await loadBag(p1);
    assert.strictEqual(activeClubs(empty).length, 0, 'synthetic bag must start empty');

    await p1.click('#seed14');
    const bag14Text = await waitText(p1, '#bagState', ['createdItems', 'ERROR'], 20000);
    assert(!bag14Text.startsWith('ERROR'), bag14Text);
    const bag14 = await loadBag(p1);
    assert.strictEqual(activeClubs(bag14).length, 14, 'fixture must contain 14 active clubs');
    result.checks.seed_14_clubs = 'PASS';

    await p1.click('#addPrimary');
    const addText = await waitText(p1, '#driverBagStatus', ['Saved to My GAL.', 'ERROR', 'My Bag save did not complete']);
    assert(addText.includes('Saved to My GAL.'), addText);
    assert(addText.includes('15 clubs in this bag'), `15-club warning not rendered: ${addText}`);
    const bag15 = await loadBag(p1);
    assert.strictEqual(activeClubs(bag15).length, 15, 'Driver add must produce 15 active clubs');
    assert.strictEqual(activeDrivers(bag15).length, 1, 'exactly one active Driver expected');
    assert.strictEqual(activeDrivers(bag15)[0].canonicalProductId, 'GAL-DRV-0003');
    assert((bag15.decisions || []).some(d => d.canonicalProductIdAtDecision === 'GAL-DRV-0003' && d.sourceTool === 'driver_buyers_guide'), 'Driver recommendation decision lineage missing');
    result.checks.driver_add_15_club_warning = 'PASS';
    result.checks.decision_lineage = 'PASS';

    await p1.click('#addSecond');
    const conflictText = await waitText(p1, '#driverBagStatus', ['A Driver is already active in My Bag.', 'ERROR', 'My Bag save did not complete']);
    assert(conflictText.includes('A Driver is already active in My Bag.'), conflictText);
    const afterConflict = await loadBag(p1);
    assert.strictEqual(activeDrivers(afterConflict).length, 1, 'duplicate Driver must not be added');
    assert.strictEqual(activeDrivers(afterConflict)[0].canonicalProductId, 'GAL-DRV-0003');
    result.checks.duplicate_slot_d_ui = 'PASS';
    await p1.screenshot({ path: 'rc15-session1.png', fullPage: true });

    await p1.click('#signOut');
    let signed = await waitText(p1, '#authStatus', ['SIGNED OUT', 'ERROR']);
    assert.strictEqual(signed, 'SIGNED OUT');
    await p1.fill('#email', email);
    await p1.fill('#password', appPassword);
    await p1.click('#signIn');
    signed = await waitText(p1, '#authStatus', ['SIGNED IN', 'ERROR']);
    assert(signed.startsWith('SIGNED IN'), signed);
    const restored = await loadBag(p1);
    assert.strictEqual(activeDrivers(restored).length, 1);
    assert.strictEqual(activeDrivers(restored)[0].canonicalProductId, 'GAL-DRV-0003');
    result.checks.logout_login_persistence = 'PASS';

    const c2 = await browser.newContext();
    const p2 = await c2.newPage();
    await p2.goto(TARGET, { waitUntil: 'domcontentloaded' });
    await p2.waitForFunction(() => !!window.__RC15_ACCEPTANCE && !!window.GALRemote?.ready?.());
    await p2.fill('#email', email);
    await p2.fill('#password', appPassword);
    await p2.click('#signIn');
    const auth2 = await waitText(p2, '#authStatus', ['SIGNED IN', 'ERROR']);
    assert(auth2.startsWith('SIGNED IN'), auth2);
    const restored2 = await loadBag(p2);
    assert.strictEqual(activeDrivers(restored2).length, 1);
    assert.strictEqual(activeDrivers(restored2)[0].canonicalProductId, 'GAL-DRV-0003');
    result.checks.second_browser_session = 'PASS';
    await p2.screenshot({ path: 'rc15-session2.png', fullPage: true });

    result.active_club_count = activeClubs(restored2).length;
    result.driver = activeDrivers(restored2)[0].canonicalProductId;
    result.status = 'PASS';
    fs.writeFileSync('rc15-browser-result.json', JSON.stringify(result, null, 2));
    console.log('RC15_BROWSER_RESULT=' + JSON.stringify(result));

    await p2.click('#signOut').catch(() => {});
    await c2.close();
    await p1.click('#signOut').catch(() => {});
    await c1.close();
  } catch (err) {
    result.status = 'FAIL';
    result.error = String(err && err.stack || err);
    fs.writeFileSync('rc15-browser-result.json', JSON.stringify(result, null, 2));
    console.error('RC15_BROWSER_RESULT=' + JSON.stringify(result));
    throw err;
  } finally {
    await deleteMailbox(mailbox);
    await browser.close();
  }
})();
