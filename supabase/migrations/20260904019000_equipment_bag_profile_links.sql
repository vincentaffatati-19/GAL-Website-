-- Link golfer-owned equipment to governed configurations without replacing legacy snapshots.

alter table public.gal_bag_items
  add column if not exists equipment_configuration_id uuid references public.gal_equipment_configurations(id);

create index if not exists gal_bag_items_equipment_configuration_idx
  on public.gal_bag_items(equipment_configuration_id)
  where equipment_configuration_id is not null;

alter table public.gal_profile_facts
  add column if not exists source_reference text;

comment on column public.gal_profile_facts.source_reference is
  'Optional provenance pointer for Tell GAL Once / Connect It Once reuse, including Buyers Guide and connected-source references.';
