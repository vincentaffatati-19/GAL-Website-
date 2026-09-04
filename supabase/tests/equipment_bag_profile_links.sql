do $$ begin
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_bag_items' and column_name='equipment_configuration_id') then
    raise exception 'gal_bag_items.equipment_configuration_id missing';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_bag_items' and column_name='configuration') then
    raise exception 'legacy bag configuration snapshot removed';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema='public' and table_name='gal_profile_facts' and column_name='source_reference') then
    raise exception 'profile source_reference missing';
  end if;
end $$;

do $$ begin
  if exists (select 1 from public.gal_bag_items where equipment_configuration_id is not null and not exists (select 1 from public.gal_equipment_configurations c where c.id=gal_bag_items.equipment_configuration_id)) then
    raise exception 'bag item has invalid governed configuration link';
  end if;
end $$;