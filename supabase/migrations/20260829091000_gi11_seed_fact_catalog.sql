-- GI-1.1
-- Purpose: seed the approved FACT-1.0 canonical golfer vocabulary.
-- Spec: docs/superpowers/specs/2026-08-28-golfer-intelligence-data-model-v1.1-design.md

insert into public.gal_fact_catalog (
  fact_key,
  schema_version,
  domain,
  display_name,
  description,
  value_type,
  unit,
  allowed_values,
  min_value,
  max_value,
  initial_profile,
  fit_importance,
  can_be_inferred,
  refresh_class,
  privacy_class,
  commercial_class,
  status
)
values
  (
    'golfer.display_name', 'FACT-1.0', 'golfer', 'Display name',
    'Golfer-facing display name used for the individual experience.',
    'text', null, null, null, null, true, 'enrichment', false,
    'stable', 'personal', 'personal_only', 'ACTIVE'
  ),
  (
    'physical.height', 'FACT-1.0', 'physical', 'Height',
    'Normalized golfer height used when equipment-fit logic benefits from stature.',
    'number', 'inches', null, 36, 96, true, 'helpful', false,
    'stable', 'restricted', 'restricted_aggregate', 'ACTIVE'
  ),
  (
    'experience.years_playing', 'FACT-1.0', 'experience', 'Years playing',
    'Approximate number of years the golfer has played golf.',
    'number', 'years', null, 0, 90, true, 'helpful', false,
    'seasonal', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'game.handicap_index', 'FACT-1.0', 'game', 'Handicap Index',
    'Current Handicap Index or equivalent golfer-reported index when an official value is unavailable.',
    'number', null, null, -10, 54, true, 'critical', false,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'game.typical_score', 'FACT-1.0', 'game', 'Typical score',
    'Golfer-reported typical 18-hole score used as a proxy when Handicap Index is unavailable.',
    'number', 'strokes', null, 50, 180, true, 'critical', false,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'swing.driver.speed_mph', 'FACT-1.0', 'swing', 'Driver swing speed',
    'Driver clubhead speed in miles per hour; may be measured, declared, imported, or inferred from approved proxies.',
    'number', 'mph', null, 40, 160, true, 'critical', true,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'swing.driver.carry_yards', 'FACT-1.0', 'swing', 'Driver carry',
    'Typical driver carry distance in yards.',
    'number', 'yards', null, 80, 400, true, 'critical', true,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'swing.iron_7.carry_yards', 'FACT-1.0', 'swing', '7-iron carry',
    'Typical 7-iron carry distance in yards.',
    'number', 'yards', null, 50, 250, true, 'critical', false,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'swing.driver.shot_shape', 'FACT-1.0', 'swing', 'Typical driver shot shape',
    'Golfer''s typical driver shot curvature pattern.',
    'enum', null, '["STRAIGHT","DRAW","FADE","HOOK","SLICE","VARIABLE"]'::jsonb,
    null, null, true, 'helpful', true,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'swing.driver.typical_miss', 'FACT-1.0', 'swing', 'Typical driver miss',
    'Primary driver miss pattern used for forgiveness and directional-fit decisions.',
    'enum', null, '["LEFT","RIGHT","SHORT","LONG","BOTH_SIDES","CONTACT","VARIABLE"]'::jsonb,
    null, null, true, 'critical', true,
    'dynamic', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'preference.performance.forgiveness', 'FACT-1.0', 'preferences', 'Forgiveness preference',
    'Golfer preference for forgiveness relative to workability and other performance tradeoffs.',
    'enum', null, '["LOW","BALANCED","HIGH"]'::jsonb,
    null, null, true, 'helpful', false,
    'seasonal', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'preference.appearance.irons', 'FACT-1.0', 'preferences', 'Iron appearance preference',
    'Golfer preference for the visual profile of irons at address.',
    'enum', null, null, null, null, false, 'enrichment', false,
    'seasonal', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'preference.value.price_sensitivity', 'FACT-1.0', 'value', 'Price sensitivity',
    'How strongly purchase price should influence golfer-specific value scoring.',
    'enum', null, '["LOW","MEDIUM","HIGH"]'::jsonb,
    null, null, true, 'helpful', false,
    'seasonal', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'goal.primary_game_goal', 'FACT-1.0', 'goals', 'Primary golf goal',
    'The golfer''s primary current game-improvement or enjoyment objective.',
    'enum', null, null, null, null, true, 'critical', false,
    'seasonal', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'goal.equipment_priority', 'FACT-1.0', 'goals', 'Equipment priority',
    'The equipment-related outcome the golfer most wants to improve next.',
    'enum', null, null, null, null, false, 'helpful', false,
    'event_driven', 'standard', 'aggregate_eligible', 'ACTIVE'
  ),
  (
    'environment.primary_region', 'FACT-1.0', 'environment', 'Primary playing region',
    'Coarse primary golf region used for climate, turf, market, and seasonal context.',
    'text', null, null, null, null, true, 'helpful', false,
    'seasonal', 'restricted', 'restricted_aggregate', 'ACTIVE'
  ),
  (
    'behavior.brand_consideration', 'FACT-1.0', 'behavior', 'Brand consideration',
    'Governed behavioral signal that a brand is being considered; it remains distinct from declared preference.',
    'multiselect', null, null, null, null, false, 'enrichment', true,
    'event_driven', 'standard', 'aggregate_eligible', 'ACTIVE'
  );
