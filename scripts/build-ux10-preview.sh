#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Reconstruct the locked UX10 Stylized Option B Motion Arc brand asset.
cat portal/brand/gal-motion-arc-dark-lockup.b64.part* | base64 --decode > portal/public/gal-motion-arc-dark-lockup.webp
test "$(wc -c < portal/public/gal-motion-arc-dark-lockup.webp)" -eq 15580
echo "8cd2030c7b3f4e75a9474dbd3e9f27e6697ce89ea756f22a5c4749192c117636  portal/public/gal-motion-arc-dark-lockup.webp" | sha256sum --check --strict

restore_parts() {
  local pattern="$1"
  local output="$2"
  : > "$output"
  for part in $pattern; do
    base64 --decode "$part" >> "$output"
  done
}

# Reconstruct and verify the four independent UX10 presentation assets.
mkdir -p portal/public/ux10/tee-boxes portal/public/ux10/bags
restore_parts 'portal/ux10-assets/coastal-01.b64.part*' portal/public/ux10/tee-boxes/coastal-01.webp
restore_parts 'portal/ux10-assets/cliffs-01.b64.part*' portal/public/ux10/tee-boxes/cliffs-01.webp
cat portal/ux10-assets/gal-tour-bag.fixed.part01 portal/ux10-assets/gal-tour-bag.fixed.part02 portal/ux10-assets/gal-tour-bag.b64.part2 | base64 --decode > portal/public/ux10/bags/gal-tour-bag.png
cat portal/ux10-assets/gal-stand-bag.fixed.part01 portal/ux10-assets/gal-stand-bag.fixed.part02 portal/ux10-assets/gal-stand-bag.b64.part2 | base64 --decode > portal/public/ux10/bags/gal-stand-bag.png

test "$(wc -c < portal/public/ux10/tee-boxes/coastal-01.webp)" -eq 23560
test "$(wc -c < portal/public/ux10/tee-boxes/cliffs-01.webp)" -eq 30352
test "$(wc -c < portal/public/ux10/bags/gal-tour-bag.png)" -eq 17841
test "$(wc -c < portal/public/ux10/bags/gal-stand-bag.png)" -eq 14867
(
  cd portal/public/ux10
  sha256sum --check --strict SHA256SUMS
)

# Retired visuals may remain in repository history but must never ship in UX10.
rm -f portal/public/gal-option7a-motion.jpg
rm -rf portal/public/ux5

# Vercel may expose a different global pnpm even after Corepack activation.
# Invoke the locked package manager version directly so pnpm-lock.yaml v9 is deterministic.
PNPM=(npx --yes pnpm@10.15.1)
cd portal
"${PNPM[@]}" --version | grep -qx '10.15.1'
"${PNPM[@]}" install --frozen-lockfile
"${PNPM[@]}" run test:run
VITE_SUPABASE_URL="${VITE_SUPABASE_URL:-https://example.supabase.co}" \
VITE_SUPABASE_PUBLISHABLE_KEY="${VITE_SUPABASE_PUBLISHABLE_KEY:-test-publishable-key}" \
"${PNPM[@]}" run build
cd "$ROOT"

# Build-time safety gates. A Vercel READY state is invalid unless these pass.
if grep -R -E 'SUPABASE_SERVICE_ROLE_KEY|service_role' portal/dist; then
  echo 'Forbidden service-role material found in portal build.' >&2
  exit 1
fi
if grep -R -n --include='*.js' --include='*.html' -E '94 mph|247 yds|\+12 Yards|\$3,840|78%|71%|\+11\.3 yds' portal/dist; then
  echo 'Forbidden sample golfer fact found in rendered UX10 application material.' >&2
  exit 1
fi
if grep -R -n --include='*.js' --include='*.html' -F '/portal/ux5/reference-bag.webp' portal/dist; then
  echo 'Retired combined UX5 scene found in UX10 build.' >&2
  exit 1
fi
if grep -R -n --include='*.js' --include='*.html' -F '/portal/gal-option7a-motion.jpg' portal/dist; then
  echo 'Retired GAL logo found in active UX10 build.' >&2
  exit 1
fi
test ! -e portal/dist/gal-option7a-motion.jpg
test ! -e portal/dist/ux5

grep -R -q -F 'GAL-UX10.02-RC1' portal/dist/assets
grep -R -q -F '/portal/gal-motion-arc-dark-lockup.webp' portal/dist/assets
grep -R -q -F 'Your Equipment Intelligence Center' portal/dist/assets
grep -R -q -F 'Your bag. Your game. Smarter together.' portal/dist/assets
grep -R -q -F 'My Golfer Profile' portal/dist/assets
grep -R -q -F 'Connected Golf' portal/dist/assets

# Replace any stale committed preview with this exact verified build.
rm -rf preview/portal
mkdir -p preview/portal
cp -R portal/dist/. preview/portal/
printf 'GAL-UX10.02-RC1\ncommit=%s\n' "${VERCEL_GIT_COMMIT_SHA:-local}" > preview/portal/UX_VERSION.txt
