import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { BRAND_FONT_FAMILY, BRAND_LOGO_ALT, BRAND_LOGO_SRC } from '../branding';

const here = dirname(fileURLToPath(import.meta.url));
const logoPath = resolve(here, '../../public/gal-option7a-motion.jpg');

function readJpegDimensions(bytes: Buffer): { width: number; height: number } {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) throw new Error('Invalid JPEG SOI');
  let offset = 2;
  const sofMarkers = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);

  while (offset + 3 < bytes.length) {
    if (bytes[offset] !== 0xff) throw new Error(`Invalid JPEG marker at byte ${offset}`);
    while (offset < bytes.length && bytes[offset] === 0xff) offset += 1;
    const marker = bytes[offset++];
    if (marker === 0xd9) break;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 1 >= bytes.length) throw new Error('Truncated JPEG segment length');
    const length = bytes.readUInt16BE(offset);
    if (length < 2 || offset + length > bytes.length) throw new Error('Invalid JPEG segment length');
    if (sofMarkers.has(marker)) {
      if (length < 7) throw new Error('Invalid JPEG SOF segment');
      return {
        height: bytes.readUInt16BE(offset + 3),
        width: bytes.readUInt16BE(offset + 5),
      };
    }
    offset += length;
  }

  throw new Error('JPEG has no decodable SOF dimensions');
}

describe('My GAL Option 7A Motion brand contract', () => {
  it('uses the approved Motion logo asset contract at the stable portal route', () => {
    expect(BRAND_LOGO_ALT).toBe('Golf Analytics Lab');
    expect(BRAND_LOGO_SRC).toBe('/portal/gal-option7a-motion.jpg');
  });

  it('ships a structurally decodable responsive Option 7A Motion logo asset', () => {
    const bytes = readFileSync(logoPath);
    expect(readJpegDimensions(bytes)).toEqual({ width: 400, height: 170 });
    expect(bytes.subarray(-2)).toEqual(Buffer.from([0xff, 0xd9]));
  });

  it('uses Inter as the GAL interface typeface', () => {
    expect(BRAND_FONT_FAMILY).toContain('Inter');
  });
});
