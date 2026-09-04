import { fetchGuideEquipment } from '../equipment/client';
import { escapeHtml } from '../render/escape';
import { driverGuideRows } from './model';
import { fetchDriverReusableProfileFacts } from './profileReuse';

export async function renderDriverGuide(): Promise<string> {
  try {
    const [equipment, reused] = await Promise.all([fetchGuideEquipment(), fetchDriverReusableProfileFacts()]);
    const drivers = driverGuideRows(equipment);
    const reuse = reused.length ? `<section class="my-gal-state"><h2>Using what GAL already knows about you.</h2>${reused.map((fact) => `<p><strong>${escapeHtml(fact.key.replaceAll('_',' '))}:</strong> ${escapeHtml(fact.value)} <small>Source: ${escapeHtml(fact.source)}</small></p>`).join('')}<p><button type="button">Looks right</button> <a href="/portal/profile">Update</a></p></section>` : '';
    return `<div class="driver-guide"><p class="eyebrow">Build a Better Bag</p><h1>Driver Buyers Guide</h1>${reuse}<section><h2>Governed Driver options</h2>${drivers.length ? drivers.map((driver) => `<article><h3>${escapeHtml(driver.item.familyName)}</h3><p>${escapeHtml(driver.readiness)}</p></article>`).join('') : '<p>No governed Driver guide entries are available yet.</p>'}</section><p>This guide is a lightweight discovery tool. Sign in for full GAL AI Fitting.</p><a class="button" href="/portal/insights?fit=driver">Open My AI Driver Fit</a></div>`;
  } catch {
    return '<section class="my-gal-state"><h2>The Driver Buyers Guide is temporarily unavailable.</h2></section>';
  }
}
