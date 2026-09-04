import {
  UX10_BAG_VISUALS,
  UX10_TEE_BOX_THEMES,
  loadUx10PresentationPreferences,
  saveUx10PresentationPreferences,
  type BagVisualId,
  type TeeBoxThemeId,
} from './personalization';

function setPressed(root: ParentNode, selector: string, selected: string, attribute: string): void {
  root.querySelectorAll<HTMLElement>(selector).forEach((element) => {
    element.setAttribute('aria-pressed', element.dataset[attribute] === selected ? 'true' : 'false');
  });
}

export function bindUx10Personalization(root: ParentNode = document): void {
  root.querySelectorAll<HTMLElement>('[data-tee-box-theme-id]').forEach((control) => {
    control.addEventListener('click', () => {
      const teeBoxThemeId = control.dataset.teeBoxThemeId as TeeBoxThemeId | undefined;
      const theme = UX10_TEE_BOX_THEMES.find((item) => item.id === teeBoxThemeId);
      if (!theme) return;

      const preferences = loadUx10PresentationPreferences();
      saveUx10PresentationPreferences({ ...preferences, teeBoxThemeId: theme.id });

      const background = root.querySelector<HTMLImageElement>('.ux10-tee-box-background');
      if (background) {
        background.src = theme.src;
        background.dataset.currentTeeBox = theme.id;
      }
      setPressed(root, '[data-tee-box-theme-id]', theme.id, 'teeBoxThemeId');
    });
  });

  root.querySelectorAll<HTMLElement>('[data-bag-visual-id]').forEach((control) => {
    control.addEventListener('click', () => {
      const bagVisualId = control.dataset.bagVisualId as BagVisualId | undefined;
      const bag = UX10_BAG_VISUALS.find((item) => item.id === bagVisualId);
      if (!bag) return;

      const preferences = loadUx10PresentationPreferences();
      saveUx10PresentationPreferences({ ...preferences, bagVisualId: bag.id });

      const bagImage = root.querySelector<HTMLImageElement>('.ux10-bag-image');
      if (bagImage) {
        bagImage.src = bag.src;
        bagImage.dataset.currentBagVisual = bag.id;
      }
      setPressed(root, '[data-bag-visual-id]', bag.id, 'bagVisualId');
    });
  });
}
