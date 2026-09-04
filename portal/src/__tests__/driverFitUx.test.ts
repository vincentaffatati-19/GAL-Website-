import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const here = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(resolve(here, '../fitting/driver/render.ts'), 'utf8');

describe('RC-UX3 Driver AI Fitting UX', () => {
  it('implements the locked nine-step mobile flow in order', () => {
    const labels = ['Quick View','Fit Setup','Target Characteristics','Recommendations','Why This Fit','Compare','Next Action','Outcome Tracking','Progress Over Time'];
    let lastIndex = -1;
    for (const label of labels) {
      const index = source.indexOf(label);
      expect(index).toBeGreaterThan(lastIndex);
      lastIndex = index;
    }
  });

  it('keeps characteristics before brands and supports optimize-current peer actions', () => {
    expect(source).toContain('Characteristics Before Brands');
    const targetIndex = source.indexOf('Target Characteristics');
    const recommendationsIndex = source.indexOf('Recommendations');
    expect(targetIndex).toBeGreaterThanOrEqual(0);
    expect(recommendationsIndex).toBeGreaterThan(targetIndex);
    for (const action of ['Keep', 'Adjust', 'Reconfigure', 'Replace']) expect(source).toContain(action);
    expect(source).toContain('AI_FIT_LIMITED');
  });
});
