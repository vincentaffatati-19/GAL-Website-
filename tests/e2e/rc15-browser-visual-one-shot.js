const fs = require('fs');
const assert = require('assert');
const { chromium } = require('playwright');

const TARGET = process.env.RC15_TARGET || 'http://127.0.0.1:4173/rc15-browser-acceptance.html';

async function openHarness(browser) {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(TARGET, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => !!window.__RC15_ACCEPTANCE && !!window.GALDriverRC15);
  return { context, page };
}

async function installRemoteStub(page, mode) {
  await page.evaluate(mode => {
    const internalBagId = mode === 'warning'
      ? '22222222-2222-2222-2222-222222222222'
      : '11111111-1111-1111-1111-111111111111';

    window.GALIntelligence = { emit: async () => ({ ok: true }), init: async () => ({ ok: true }) };
    window.GALRemote = {
      getSessionUser: async () => ({ id: 'synthetic-browser-user' }),
      signOut: async () => true,
      loadBag: async () => ({ mode: 'REGISTERED_LIVE', items: [], decisions: [] }),
      ready: () => ({
        from: () => ({
          select: () => ({
            eq: () => ({
              limit: () => ({
                maybeSingle: async () => ({ data: { id: internalBagId, bag_id: 'GAL-BAG-SYNTHETIC' }, error: null })
              })
            })
          })
        }),
        rpc: async (name) => {
          if (name === 'gal_slot_conflicts') {
            return mode === 'conflict'
              ? { data: [{ slot_code: 'D', existing_bag_item_id: 'GAL-BI-SYNTHETIC' }], error: null }
              : { data: [], error: null };
          }
          if (name === 'gal_add_to_my_bag') {
            return { data: { ok: true, activeClubCount: 15 }, error: null };
          }
          if (name === 'gal_my_bag_warnings') {
            return mode === 'warning'
              ? {
                  data: {
                    bagId: 'GAL-BAG-SYNTHETIC',
                    club_count: 15,
                    over_14: true,
                    warnings: [{
                      code: 'USGA_14_CLUB_LIMIT',
                      severity: 'ERROR',
                      message: '15 clubs in this bag. Rule 4.1b limits a player to 14 clubs during a round.',
                      details: { limit: 14, club_count: 15 }
                    }]
                  },
                  error: null
                }
              : { data: { warnings: [] }, error: null };
          }
          return { data: { ok: true }, error: null };
        }
      })
    };
  }, mode);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const result = { status: 'RUNNING', checks: {} };
  try {
    {
      const { context, page } = await openHarness(browser);
      await installRemoteStub(page, 'warning');
      await page.click('#addPrimary');
      await page.locator('#driverBagStatus').waitFor({ state: 'visible' });
      await page.waitForTimeout(250);
      const text = (await page.locator('#driverBagStatus').innerText()).trim();
      assert(text.includes('Saved to My GAL.'), text);
      assert(text.includes('15 clubs in this bag. Rule 4.1b limits a player to 14 clubs during a round.'), text);
      result.checks.fourteen_club_browser_warning = 'PASS';
      result.warning_text = text;
      await page.screenshot({ path: 'rc15-browser-14-club-warning.png', fullPage: true });
      await context.close();
    }

    {
      const { context, page } = await openHarness(browser);
      await installRemoteStub(page, 'conflict');
      await page.click('#addSecond');
      await page.locator('#driverBagStatus').waitFor({ state: 'visible' });
      await page.waitForTimeout(250);
      const text = (await page.locator('#driverBagStatus').innerText()).trim();
      assert(text.includes('A Driver is already active in My Bag.'), text);
      assert(text.includes('Open My Bag to review or replace it.'), text);
      result.checks.duplicate_slot_d_browser = 'PASS';
      result.conflict_text = text;
      await page.screenshot({ path: 'rc15-browser-duplicate-driver.png', fullPage: true });
      await context.close();
    }

    result.status = 'PASS';
    fs.writeFileSync('rc15-browser-visual-result.json', JSON.stringify(result, null, 2));
    console.log('RC15_BROWSER_VISUAL_RESULT=' + JSON.stringify(result));
  } catch (err) {
    result.status = 'FAIL';
    result.error = String(err && err.stack || err);
    fs.writeFileSync('rc15-browser-visual-result.json', JSON.stringify(result, null, 2));
    console.error('RC15_BROWSER_VISUAL_RESULT=' + JSON.stringify(result));
    throw err;
  } finally {
    await browser.close();
  }
})();
