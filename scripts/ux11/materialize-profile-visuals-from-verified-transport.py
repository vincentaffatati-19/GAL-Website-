#!/usr/bin/env python3
"""One-time UX11 materializer for the locked Profile visual resolver.

The four approved embedded persona pairs are downloaded only from expiring transfer
URLs, verified byte-for-byte against the locked SHA-256 hashes, and re-embedded as
PNG data URIs. The other eight persona pairs remain at their exact GAL-owned
Supabase URLs. This script must not be used to regenerate or substitute imagery.
"""
from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen

BASE_KEYS = [
    "junior_male", "junior_female", "male_young", "female_young",
    "male_middle", "female_middle", "male_mature", "female_mature",
    "male_senior", "female_senior", "neutral_junior", "neutral_adult",
]
SUPABASE_PREFIX = "https://ylrxwtbzavhxxpoqqmho.supabase.co/storage/v1/object/public/gal-profile-visuals/ux10-02/v3/"

SUPABASE = {
    "junior_male": ("junior_male_body.png", "junior_male_swing.png"),
    "junior_female": ("junior_female_body.png", "junior_female_swing.png"),
    "male_young": ("male_young_body.png", "male_young_swing.png"),
    "male_middle": ("male_middle_body.png", "male_middle_swing.png"),
    "female_middle": ("female_middle_body.png", "female_middle_swing.png"),
    "male_senior": ("male_senior_body.png", "male_senior_swing.png"),
    "neutral_junior": ("neutral_junior_body.png", "neutral_junior_swing.png"),
    "neutral_adult": ("neutral_adult_body.png", "neutral_adult_swing.png"),
}

TRANSPORT = {
    "female_young": {
        "body": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/f0ac1bdc-6e4f-4c90-b49f-ed1d32352ad6.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiMzNkOGViOGFiMDRhMTkxMiIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTIzNjQ5MH0.8lOVmPBh2aW0W_zjpPL8EZbR6NAXH-bZxEcVxlUEcCE", "4db490de2ed248bd30318d08f4735a480e6b953c1c9a8727e089756521217ad9", 1241253),
        "swing": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/729e2ce6-c444-4a49-b2de-edbd69d0198b.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiMmFiMGYyOGNhOGRhNzY4NyIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTI0MTEwMH0.MxADY1sH4zD4PvzZhAHhMJh3CYag6TP7oBMb68jp8aY", "b734a87dd16c3ac237899ee9b4c2848e5c2804649f00cb3c526ae7c1ac5cdfee", 1065590),
    },
    "male_mature": {
        "body": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/84ad20d0-e4f7-4d05-abd5-4357f02578f9.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiMWQ1NGFlMzJjMDkxZDYxMyIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTI5ODQ4Mn0.WaNG3dZHQL3D2aKuhQPPPdIRni9jai5FAHQBsfcfSYc", "98564cb6639041404834ab7f40c1ff77c07f977f9a88c430be25c1d1570ba949", 799007),
        "swing": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/0ab90da0-5ac1-43de-afbe-08737e41c22d.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiMDliMzZkNTM1ZDljOWI1YyIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTIzMzg3NX0.tPWECQmPOjsS4oCs-e2pSlQCHizeYtdVyYvHOnRWpzA", "bb7c678600b4465889644a4981a8eebc9949064ac2716916a8e6e66b4391fc1f", 716331),
    },
    "female_mature": {
        "body": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/9cc83227-52f1-45ab-960e-f76f657674f5.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiMDcyZWJlNWE0MzVhMzdjYSIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTIzMzQ5OH0.EDxw3JJfFL9DYUS1otaiZmMn38zoKhLVg2HaCgmVmi0", "414145e902a0a9020c4d2ab7c0902c0dd2c951016a905a896f3bfc97aea4ba04", 1392715),
        "swing": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/745b8087-31b4-4f96-a9fc-69ca48fd6424.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiNjUwMWZiYWU2NTU2OWJkZCIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTIzNjc4Mn0.bs2TQcd0LftUrF95P5MvOOIbVac1N6rNWk4Y6c88IRg", "22ba76d61639f5a9e6ec120b40358771d4b22f855a2506cb68af23fa065dd143", 963867),
    },
    "female_senior": {
        "body": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/87493248-f141-48ee-b2c8-65c208f53421.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiNjkxNWM4ZTFmNmVlY2E3ZSIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTMwMDk2MX0.UN_wEsZGm4qhJrhpn8FydQqNF5s8CuR4u55Heg3BaiA", "e52013c135dd38a24bf9d411ae5ac3b0130ace03a0cadc728ae7a350f67392d5", 1454060),
        "swing": ("https://d2jqrm6oza8nb6.cloudfront.net/datasets/ed7da4d2-bc42-4e8d-950a-e635e690ac01.png?_jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlIYXNoIjoiOTFmYWVkMjdiMTljMjZjOCIsImJ1Y2tldCI6InJ1bndheS1kYXRhc2V0cyIsInN0YWdlIjoicHJvZCIsImV4cCI6MTc4OTIxNzgzMX0.PElG8fZmNh4TzlzT1kDMnWpKZkCz1IE7kccZu4I8LCQ", "e5fdc29e8e5e89472ce6078d62698e6bb4b5bcdc1cd80de44979c9623bd077eb", 995970),
    },
}


def fetch_verified(url: str, expected_sha: str, expected_size: int) -> str:
    req = Request(url, headers={"User-Agent": "GAL-UX11-materializer/1.0"})
    with urlopen(req, timeout=120) as response:
        payload = response.read()
    actual_sha = hashlib.sha256(payload).hexdigest()
    if len(payload) != expected_size:
        raise SystemExit(f"REFUSED: byte length {len(payload)} != locked {expected_size}")
    if actual_sha != expected_sha:
        raise SystemExit(f"REFUSED: SHA-256 {actual_sha} != locked {expected_sha}")
    return "data:image/png;base64," + base64.b64encode(payload).decode("ascii")


def module_text(body: dict[str, str], swing: dict[str, str]) -> str:
    body_json = json.dumps(body, ensure_ascii=False, separators=(",", ":"))
    swing_json = json.dumps(swing, ensure_ascii=False, separators=(",", ":"))
    keys_json = json.dumps(BASE_KEYS, separators=(",", ":"))
    return f'''/* AUTO-GENERATED from the locked GAL UX10.02 Final Profile RC. DO NOT HAND-EDIT. */\nconst PERSONA_KEYS={keys_json};\nconst BODY={body_json};\nconst SWING={swing_json};\nconst PERSONAS=Object.fromEntries(PERSONA_KEYS.map((key)=>[key,{{body:BODY[key],swing:SWING[key],ageClaim:true}}]));\nPERSONAS.male_age_unspecified={{body:BODY.male_mature,swing:SWING.male_mature,ageClaim:null}};\nPERSONAS.female_age_unspecified={{body:BODY.female_mature,swing:SWING.female_mature,ageClaim:null}};\nfunction resolveGolferVisual(gender,ageRange){{\n  if(ageRange==='Under 18') return gender==='Male'?'junior_male':gender==='Female'?'junior_female':'neutral_junior';\n  const young=['18–24','25–34'].includes(ageRange);\n  const middle=['35–44','45–54'].includes(ageRange);\n  const mature=ageRange==='55–64';\n  const senior=['65–74','75+'].includes(ageRange);\n  if(gender==='Male'&&young)return 'male_young';\n  if(gender==='Female'&&young)return 'female_young';\n  if(gender==='Male'&&middle)return 'male_middle';\n  if(gender==='Female'&&middle)return 'female_middle';\n  if(gender==='Male'&&mature)return 'male_mature';\n  if(gender==='Female'&&mature)return 'female_mature';\n  if(gender==='Male'&&senior)return 'male_senior';\n  if(gender==='Female'&&senior)return 'female_senior';\n  if(gender==='Male')return 'male_age_unspecified';\n  if(gender==='Female')return 'female_age_unspecified';\n  return 'neutral_adult';\n}}\nfunction resolveGolferSwingVisual(gender,ageRange){{return resolveGolferVisual(gender,ageRange)}}\nconst api={{PERSONA_KEYS,PERSONAS,resolveGolferVisual,resolveGolferSwingVisual}};\nif(typeof module!=='undefined'&&module.exports) module.exports=api;\nif(typeof window!=='undefined') window.GALProfileVisuals=api;\n'''


def main() -> None:
    body: dict[str, str] = {}
    swing: dict[str, str] = {}
    for key, (body_name, swing_name) in SUPABASE.items():
        body[key] = SUPABASE_PREFIX + body_name
        swing[key] = SUPABASE_PREFIX + swing_name
    for key, records in TRANSPORT.items():
        body[key] = fetch_verified(*records["body"])
        swing[key] = fetch_verified(*records["swing"])
    if set(body) != set(BASE_KEYS) or set(swing) != set(BASE_KEYS):
        raise SystemExit("REFUSED: materialized resolver does not contain exactly 12 governed Body/Swing keys")
    output = Path("profile__visuals.js")
    output.write_text(module_text(body, swing), encoding="utf-8")
    raw = output.read_bytes()
    print(f"PASS: materialized {output} ({len(raw)} bytes, sha256={hashlib.sha256(raw).hexdigest()})")


if __name__ == "__main__":
    main()
