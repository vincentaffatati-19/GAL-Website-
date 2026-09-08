from pathlib import Path
import re, sys

p=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data/gal-step17/GAL-UX10.02-STAGING-RC.html')
s=p.read_text('utf-8')

required_keys=['junior_male','junior_female','male_young','female_young','male_middle','female_middle','male_mature','female_mature','male_senior','female_senior','neutral_junior','neutral_adult']

assert 'const GOLFER_SWING_PLATES=' in s, 'missing dedicated GOLFER_SWING_PLATES contract'
assert 'TRANSPARENT_SWING_PIXEL' in s, 'missing transparent pixel crop mechanism'
assert "backgroundSize='400% 100%'" in s or 'backgroundSize="400% 100%"' in s, 'missing exact four-quarter plate crop sizing'
assert 'backgroundPosition' in s, 'missing per-stage plate positioning'

for key in required_keys:
    assert re.search(rf"\b{re.escape(key)}\s*:\s*\{{[^}}]*bodySource:", s), f'missing governed body manifest for {key}'
    assert re.search(rf"\b{re.escape(key)}\s*:\s*\{{[^}}]*fallback\s*:\s*false", s), f'{key} still uses swing fallback'

for forbidden in ['approved-proof','step17.2-corrected',"fallback:true"]:
    assert forbidden not in s, f'provisional visual marker remains: {forbidden}'

for token in ["ageRange==='Under 18'","['18–24','25–34']","['35–44','45–54']","ageRange==='55–64'","['65–74','75+']","return 'neutral_adult'"]:
    assert token in s, f'resolver regression: {token}'

print('PASS: dynamic visual v3 structural contract')
