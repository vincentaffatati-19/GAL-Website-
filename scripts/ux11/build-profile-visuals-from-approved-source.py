#!/usr/bin/env python3
"""Build the UX11 governed visual resolver from the approved Final Profile RC.

The source file is intentionally not reconstructed. This generator accepts only the
locked source SHA-256 and copies its exact body/swing asset strings into the module.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

EXPECTED_SOURCE_SHA256 = "c2dd228f782fd357949c472a07d6a2cb68be6308ea60d749dfac8fe0bdc5c084"
BASE_KEYS = [
    "junior_male", "junior_female", "male_young", "female_young",
    "male_middle", "female_middle", "male_mature", "female_mature",
    "male_senior", "female_senior", "neutral_junior", "neutral_adult",
]
EMBEDDED_KEYS = {"female_young", "male_mature", "female_mature", "female_senior"}
SUPABASE_KEYS = set(BASE_KEYS) - EMBEDDED_KEYS
SUPABASE_PREFIX = "https://ylrxwtbzavhxxpoqqmho.supabase.co/storage/v1/object/public/gal-profile-visuals/ux10-02/v3/"


def extract_json_object(source: str, const_name: str) -> dict[str, str]:
    marker = f"const {const_name}="
    start = source.find(marker)
    if start < 0:
        raise ValueError(f"Locked source is missing {marker}")
    start += len(marker)
    if source[start] != "{":
        raise ValueError(f"{const_name} must begin with a JSON object")
    depth = 0
    quoted = False
    escaped = False
    end = None
    for index in range(start, len(source)):
        char = source[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end is None:
        raise ValueError(f"Unterminated {const_name} object")
    parsed = json.loads(source[start:end])
    if not isinstance(parsed, dict):
        raise ValueError(f"{const_name} did not decode to an object")
    return parsed


def validate_assets(body: dict[str, str], swing: dict[str, str]) -> None:
    expected = set(BASE_KEYS)
    if set(body) != expected or set(swing) != expected:
        raise ValueError("Locked source must contain exactly the 12 governed Body/Swing persona keys")
    for key in EMBEDDED_KEYS:
        if not body[key].startswith("data:image/png;base64,") or not swing[key].startswith("data:image/png;base64,"):
            raise ValueError(f"{key} must remain embedded in the approved source")
    for key in SUPABASE_KEYS:
        if not body[key].startswith(SUPABASE_PREFIX) or not swing[key].startswith(SUPABASE_PREFIX):
            raise ValueError(f"{key} must remain in GAL-owned Supabase custody")


def module_text(body: dict[str, str], swing: dict[str, str]) -> str:
    body_json = json.dumps(body, ensure_ascii=False, separators=(",", ":"))
    swing_json = json.dumps(swing, ensure_ascii=False, separators=(",", ":"))
    keys_json = json.dumps(BASE_KEYS, separators=(",", ":"))
    return f'''/* AUTO-GENERATED from the locked GAL UX10.02 Final Profile RC. DO NOT HAND-EDIT. */
const PERSONA_KEYS={keys_json};
const BODY={body_json};
const SWING={swing_json};
const PERSONAS=Object.fromEntries(PERSONA_KEYS.map((key)=>[key,{{body:BODY[key],swing:SWING[key],ageClaim:true}}]));
PERSONAS.male_age_unspecified={{body:BODY.male_mature,swing:SWING.male_mature,ageClaim:null}};
PERSONAS.female_age_unspecified={{body:BODY.female_mature,swing:SWING.female_mature,ageClaim:null}};
function resolveGolferVisual(gender,ageRange){{
  if(ageRange==='Under 18') return gender==='Male'?'junior_male':gender==='Female'?'junior_female':'neutral_junior';
  const young=['18–24','25–34'].includes(ageRange);
  const middle=['35–44','45–54'].includes(ageRange);
  const mature=ageRange==='55–64';
  const senior=['65–74','75+'].includes(ageRange);
  if(gender==='Male'&&young)return 'male_young';
  if(gender==='Female'&&young)return 'female_young';
  if(gender==='Male'&&middle)return 'male_middle';
  if(gender==='Female'&&middle)return 'female_middle';
  if(gender==='Male'&&mature)return 'male_mature';
  if(gender==='Female'&&mature)return 'female_mature';
  if(gender==='Male'&&senior)return 'male_senior';
  if(gender==='Female'&&senior)return 'female_senior';
  if(gender==='Male')return 'male_age_unspecified';
  if(gender==='Female')return 'female_age_unspecified';
  return 'neutral_adult';
}}
function resolveGolferSwingVisual(gender,ageRange){{return resolveGolferVisual(gender,ageRange)}}
const api={{PERSONA_KEYS,PERSONAS,resolveGolferVisual,resolveGolferSwingVisual}};
if(typeof module!=='undefined'&&module.exports) module.exports=api;
if(typeof window!=='undefined') window.GALProfileVisuals=api;
'''


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Locked GAL-UX10.02-FINAL-PROFILE-RC.html")
    parser.add_argument("output", type=Path, help="Output profile__visuals.js")
    args = parser.parse_args()
    raw = args.source.read_bytes()
    actual = hashlib.sha256(raw).hexdigest()
    if actual != EXPECTED_SOURCE_SHA256:
        raise SystemExit(f"REFUSED: source SHA-256 {actual} != locked {EXPECTED_SOURCE_SHA256}")
    source = raw.decode("utf-8")
    body = extract_json_object(source, "GOLFER_VISUAL_ASSETS")
    swing = extract_json_object(source, "GOLFER_SWING_PLATES")
    validate_assets(body, swing)
    args.output.write_text(module_text(body, swing), encoding="utf-8")
    print(f"PASS: generated {args.output} from locked source {actual}")

if __name__ == "__main__":
    main()
