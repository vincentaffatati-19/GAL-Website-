export type TeeBoxThemeId = 'coastal' | 'cliffs';
export type BagVisualId = 'tour' | 'stand';

export type Ux10PresentationPreferences = {
  teeBoxThemeId: TeeBoxThemeId;
  bagVisualId: BagVisualId;
};

export type Ux10Storage = Pick<Storage, 'getItem' | 'setItem'>;

export const UX10_TEE_BOX_THEMES = [
  {
    id: 'coastal' as const,
    label: 'Spyglass-inspired Coastal',
    shortLabel: 'Coastal',
    src: '/portal/ux10/tee-boxes/coastal-01.webp',
  },
  {
    id: 'cliffs' as const,
    label: 'Torrey-inspired Cliffs',
    shortLabel: 'Cliffs',
    src: '/portal/ux10/tee-boxes/cliffs-01.webp',
  },
];

export const UX10_BAG_VISUALS = [
  {
    id: 'tour' as const,
    label: 'GAL Tour Bag',
    src: '/portal/ux10/bags/gal-tour-bag.png',
  },
  {
    id: 'stand' as const,
    label: 'GAL Stand Bag',
    src: '/portal/ux10/bags/gal-stand-bag.png',
  },
];

export const DEFAULT_UX10_PREFERENCES: Ux10PresentationPreferences = {
  teeBoxThemeId: 'coastal',
  bagVisualId: 'tour',
};

const STORAGE_KEY = 'gal.ux10.presentation';

function isTeeBoxThemeId(value: unknown): value is TeeBoxThemeId {
  return UX10_TEE_BOX_THEMES.some((item) => item.id === value);
}

function isBagVisualId(value: unknown): value is BagVisualId {
  return UX10_BAG_VISUALS.some((item) => item.id === value);
}

export function loadUx10PresentationPreferences(storage?: Ux10Storage): Ux10PresentationPreferences {
  const source = storage ?? (typeof window === 'undefined' ? undefined : window.localStorage);
  if (!source) return { ...DEFAULT_UX10_PREFERENCES };

  try {
    const parsed = JSON.parse(source.getItem(STORAGE_KEY) ?? '{}') as Partial<Ux10PresentationPreferences>;
    return {
      teeBoxThemeId: isTeeBoxThemeId(parsed.teeBoxThemeId) ? parsed.teeBoxThemeId : DEFAULT_UX10_PREFERENCES.teeBoxThemeId,
      bagVisualId: isBagVisualId(parsed.bagVisualId) ? parsed.bagVisualId : DEFAULT_UX10_PREFERENCES.bagVisualId,
    };
  } catch {
    return { ...DEFAULT_UX10_PREFERENCES };
  }
}

export function saveUx10PresentationPreferences(
  preferences: Ux10PresentationPreferences,
  storage?: Ux10Storage,
): void {
  const target = storage ?? (typeof window === 'undefined' ? undefined : window.localStorage);
  target?.setItem(STORAGE_KEY, JSON.stringify(preferences));
}
