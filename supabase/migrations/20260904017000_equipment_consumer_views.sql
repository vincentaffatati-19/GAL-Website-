-- GAL shared Equipment Knowledge read contracts

create or replace view public.gal_equipment_detail_v as
select
  f.id as family_id,
  f.equipment_family_id,
  f.canonical_product_id,
  f.canonical_brand_id,
  f.category,
  f.family_name,
  f.lifecycle_state,
  coalesce(jsonb_agg(distinct jsonb_build_object(
    'attribute_key',ad.attribute_key,
    'value',ch.value_json,
    'unit',ch.unit,
    'claim_state',ch.claim_state,
    'methodology_version',ch.methodology_version
  )) filter (where ch.id is not null),'[]'::jsonb) as approved_characteristics
from public.gal_equipment_families f
left join public.gal_equipment_characteristics ch on ch.family_id=f.id and ch.governance_status='PRODUCTION'
left join public.gal_equipment_attribute_definitions ad on ad.id=ch.attribute_definition_id
group by f.id;

create or replace view public.gal_equipment_guide_v as
select
  d.*,
  r.id as readiness_state_id,
  r.readiness_state,
  r.use_case,
  coalesce(m.media_assets,'[]'::jsonb) as media_assets
from public.gal_equipment_detail_v d
join lateral (
  select rs.* from public.gal_equipment_readiness_state rs
  where rs.family_id=d.family_id and rs.use_case='BUYERS_GUIDE'
    and rs.readiness_state in ('GUIDE_READY','AI_FIT_READY')
  order by rs.evaluated_at desc limit 1
) r on true
left join lateral (
  select jsonb_agg(jsonb_build_object('media_role',ma.media_role,'asset_reference',ma.asset_reference,'rights_state',ma.rights_state)) as media_assets
  from public.gal_equipment_media_production_v ma where ma.family_id=d.family_id
) m on true;

create or replace view public.gal_equipment_ai_fit_v as
select
  d.*,
  r.id as readiness_state_id,
  r.readiness_state,
  r.use_case,
  r.blocking_gap_count,
  c.id as configuration_id,
  c.equipment_configuration_id,
  c.configuration_key,
  c.display_name as configuration_name,
  c.support_state,
  (r.readiness_state='AI_FIT_LIMITED') as limited_evidence
from public.gal_equipment_detail_v d
join lateral (
  select rs.* from public.gal_equipment_readiness_state rs
  where rs.family_id=d.family_id and rs.use_case='AI_FIT'
    and rs.readiness_state in ('AI_FIT_LIMITED','AI_FIT_READY')
  order by rs.evaluated_at desc limit 1
) r on true
left join public.gal_equipment_configuration_eligible_v c on c.family_id=d.family_id;

grant select on public.gal_equipment_guide_v to anon, authenticated;
grant select on public.gal_equipment_ai_fit_v to authenticated;
grant select on public.gal_equipment_detail_v to authenticated;
