-- GI-1.1 Foundation Task 2: canonical golfer Fact Catalog vocabulary.
-- TDD contract: this test is added before the FACT-1.0 seed migration.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(16);

select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'game.handicap_index' and status = 'ACTIVE'),
  'GI-FACT-001 game.handicap_index is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'swing.driver.speed_mph' and status = 'ACTIVE'),
  'GI-FACT-002 swing.driver.speed_mph is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'swing.driver.carry_yards' and status = 'ACTIVE'),
  'GI-FACT-003 swing.driver.carry_yards is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'swing.iron_7.carry_yards' and status = 'ACTIVE'),
  'GI-FACT-004 swing.iron_7.carry_yards is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'swing.driver.shot_shape' and status = 'ACTIVE'),
  'GI-FACT-005 swing.driver.shot_shape is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'swing.driver.typical_miss' and status = 'ACTIVE'),
  'GI-FACT-006 swing.driver.typical_miss is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'preference.value.price_sensitivity' and status = 'ACTIVE'),
  'GI-FACT-007 preference.value.price_sensitivity is cataloged and active');
select ok(exists(select 1 from public.gal_fact_catalog where fact_key = 'goal.primary_game_goal' and status = 'ACTIVE'),
  'GI-FACT-008 goal.primary_game_goal is cataloged and active');

select is((select schema_version from public.gal_fact_catalog where fact_key = 'game.handicap_index'), 'FACT-1.0',
  'GI-FACT-009 handicap uses FACT-1.0 semantics');
select is((select commercial_class from public.gal_fact_catalog where fact_key = 'game.handicap_index'), 'aggregate_eligible',
  'GI-FACT-010 handicap is aggregate eligible');
select is((select refresh_class from public.gal_fact_catalog where fact_key = 'game.handicap_index'), 'dynamic',
  'GI-FACT-011 handicap is dynamically refreshed');
select is((select unit from public.gal_fact_catalog where fact_key = 'swing.driver.speed_mph'), 'mph',
  'GI-FACT-012 driver speed uses mph');
select is((select unit from public.gal_fact_catalog where fact_key = 'swing.iron_7.carry_yards'), 'yards',
  'GI-FACT-013 7-iron carry uses yards');
select ok((select can_be_inferred from public.gal_fact_catalog where fact_key = 'swing.driver.speed_mph'),
  'GI-FACT-014 driver speed may be inferred from approved proxies');
select is((select value_type from public.gal_fact_catalog where fact_key = 'swing.driver.typical_miss'), 'enum',
  'GI-FACT-015 typical miss is a governed enum');
select is((select commercial_class from public.gal_fact_catalog where fact_key = 'golfer.display_name'), 'personal_only',
  'GI-FACT-016 display name is personal-only');

select * from finish();
rollback;
