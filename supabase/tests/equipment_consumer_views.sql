do $$ begin
  if to_regclass('public.gal_equipment_guide_v') is null then raise exception 'guide view missing'; end if;
  if to_regclass('public.gal_equipment_ai_fit_v') is null then raise exception 'ai fit view missing'; end if;
  if to_regclass('public.gal_equipment_detail_v') is null then raise exception 'detail view missing'; end if;
end $$;

do $$ begin
  if exists (
    select 1 from public.gal_equipment_guide_v g
    left join public.gal_equipment_readiness_state r on r.id=g.readiness_state_id
    where r.readiness_state not in ('GUIDE_READY','AI_FIT_READY')
  ) then raise exception 'guide view contains non-guide-ready equipment'; end if;
end $$;

do $$ begin
  if exists (
    select 1 from public.gal_equipment_guide_v g
    join public.gal_equipment_ai_fit_v a on a.canonical_product_id=g.canonical_product_id
    where g.category is distinct from a.category
       or g.family_name is distinct from a.family_name
       or g.lifecycle_state is distinct from a.lifecycle_state
  ) then raise exception 'guide and ai fit views disagree on canonical facts'; end if;
end $$;