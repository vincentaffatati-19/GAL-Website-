import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const TEST_DIR = dirname(fileURLToPath(import.meta.url));
const SRC_DIR = dirname(TEST_DIR);
const ALLOWED = new Set([
  'equipment/client.ts',
  '__tests__/equipmentClient.test.ts',
  '__tests__/equipmentArchitecture.test.ts',
]);
const RPC_NAMES = ['gal_public_equipment_guide', 'gal_authenticated_equipment_ai_fit'];

function sourceFiles(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const fullPath = join(directory, entry);
    if (statSync(fullPath).isDirectory()) return sourceFiles(fullPath);
    return fullPath.endsWith('.ts') ? [fullPath] : [];
  });
}

describe('equipment architecture boundary', () => {
  it('keeps governed Equipment Knowledge RPC names inside the shared equipment client', () => {
    const violations = sourceFiles(SRC_DIR).flatMap((file) => {
      const rel = relative(SRC_DIR, file).replaceAll('\\', '/');
      if (ALLOWED.has(rel)) return [];
      const source = readFileSync(file, 'utf8');
      return RPC_NAMES.some((name) => source.includes(name)) ? [rel] : [];
    });

    expect(violations).toEqual([]);
  });
});
