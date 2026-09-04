import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(resolve(here, '../fitting/driver/render.ts'), 'utf8');
const css = readFileSync(resolve(here, '../styles/ux10.css'), 'utf8');

describe('GAL UX10 Driver intelligence interaction', () => {
  it('renders the locked contextual club panel and five-part detail model', () => {
    for (const className of ['ux10-club-panel', 'ux10-driver-snapshot', 'ux10-club-tabs', 'ux10-club-overview']) {
      expect(source).toContain(className);
    }
    for (const tab of ['Overview', 'Why It Matters', 'What To Do', 'Recommendations', 'Compare']) {
      expect(source).toContain(tab);
    }
    expect(source).toContain('driver-what-to-do');
    expect(source).toContain('Close Driver intelligence');
    expect(source).toContain('/portal/');
  });

  it('preserves the governed fitting loop without user-declared optimization', () => {
    for (const label of ['Quick View', 'Fit Setup', 'Target Characteristics', 'Outcome Tracking', 'Progress Over Time']) {
      expect(source).toContain(label);
    }
    expect(source).toContain('Characteristics Before Brands');
    for (const action of ['Keep', 'Adjust', 'Test', 'Reconfigure', 'Replace']) expect(source).toContain(action);
    expect(source).toContain('AI_FIT_LIMITED');
    expect(source).not.toContain('Mark as Optimized');
    expect(source).not.toContain('94 mph');
    expect(source).not.toContain('247 yds');
  });

  it('provides a desktop contextual layout and compact mobile adaptation', () => {
    for (const selector of ['.ux10-club-panel-body', '.ux10-club-primary', '.ux10-club-explain', '.ux10-driver-follow-through']) {
      expect(css).toContain(selector);
    }
    expect(css).toContain('@media (max-width: 900px)');
  });
});
