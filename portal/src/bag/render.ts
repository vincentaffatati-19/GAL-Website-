import { fetchMyBag } from './client';

export async function renderMyBag(): Promise<string> {
  try {
    const items = await fetchMyBag();
    if (!items.length) return '<section class="my-gal-state"><h2>Build your bag</h2><p>Add equipment so GAL can connect your bag to governed equipment intelligence.</p></section>';
    return `<section class="equipment-list" aria-label="My Bag equipment">${items.map((item) => `
      <article class="equipment-card">
        <p class="eyebrow">${item.category.replaceAll('_',' ')}</p>
        <h2>${item.equipmentName}</h2>
        <p>${item.state === 'KNOWN' ? (item.configuration ? `Configuration: ${item.configuration.name}` : 'Configuration linked to GAL Equipment Knowledge.') : 'Configuration details needed'}</p>
        ${item.fittingHref ? `<a class="button" href="${item.fittingHref}">${item.state === 'KNOWN' ? 'Open Driver Fit' : 'Complete Driver Details'}</a>` : ''}
      </article>`).join('')}</section>`;
  } catch (error) {
    const message = error instanceof Error && error.message === 'AUTH_REQUIRED' ? 'Sign in to view My Bag.' : 'My Bag is temporarily unavailable.';
    return `<section class="my-gal-state"><h2>${message}</h2></section>`;
  }
}
