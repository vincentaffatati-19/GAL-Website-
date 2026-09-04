do $$
begin
  if to_regclass('public.gal_equipment_families') is null then raise exception 'gal_equipment_families missing'; end if;
  if to_regclass('public.gal_equipment_variants') is null then raise exception 'gal_equipment_variants missing'; end if;
  if to_regclass('public.gal_equipment_components') is null then raise exception 'gal_equipment_components missing'; end if;
  if to_regclass('public.gal_equipment_aliases') is null then raise exception 'gal_equipment_aliases missing'; end if;
  if to_regclass('public.gal_equipment_lifecycle_events') is null then raise exception 'gal_equipment_lifecycle_events missing'; end if;
end $$;

do $$
begin
  if exists (
    select canonical_product_id from public.gal_equipment_families
    where canonical_product_id is not null
    group by canonical_product_id having count(*) > 1
  ) then raise exception 'canonical product maps to multiple equipment families'; end if;
end $$;

do $$
begin
  if exists (
    select 1 from public.gal_catalog_products c
    where not exists (select 1 from public.gal_equipment_families f where f.canonical_product_id=c.canonical_product_id)
  ) then raise exception 'catalog product missing canonical family mapping'; end if;
end $$;