-- GI-1.1 Longitudinal Intelligence Task 1
-- Extend the canonical event catalog with governed behavioral semantics and seed EVENT-1.0.
-- Behavior is evidence, not automatically truth.

alter table public.gal_event_catalog
  add column signal_class text,
  add column profile_relevance text,
  add column operational_class text,
  add column commercial_class text,
  add column retention_class text,
  add column is_active boolean not null default true;

alter table public.gal_event_catalog
  add constraint gal_event_catalog_signal_class_check
    check (signal_class is null or signal_class in ('NAVIGATION','ENGAGEMENT','INTENT','COMMITMENT','OUTCOME')),
  add constraint gal_event_catalog_profile_relevance_check
    check (profile_relevance is null or profile_relevance in ('NONE','LOW','MEDIUM','HIGH')),
  add constraint gal_event_catalog_operational_class_check
    check (operational_class is null or operational_class in ('SERVICE_OPERATION','PERSONALIZATION','PRODUCT_ANALYTICS')),
  add constraint gal_event_catalog_commercial_class_check
    check (commercial_class is null or commercial_class in ('PERSONAL_ONLY','AGGREGATE_ELIGIBLE','RESTRICTED_AGGREGATE','EXCLUDED')),
  add constraint gal_event_catalog_retention_class_check
    check (retention_class is null or retention_class in ('SHORT','STANDARD','LONG_TERM'));

insert into public.gal_event_catalog (
  event_key,
  event_version,
  domain,
  object_type,
  action,
  description,
  status,
  signal_class,
  profile_relevance,
  operational_class,
  commercial_class,
  retention_class,
  is_active
)
values
  ('guide.started','EVENT-1.0','GUIDE','guide','started','Golfer starts a governed GAL Buyer''s Guide or fitting workflow.','ACTIVE','ENGAGEMENT','LOW','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('guide.completed','EVENT-1.0','GUIDE','guide','completed','Golfer completes a governed GAL Buyer''s Guide or fitting workflow.','ACTIVE','COMMITMENT','MEDIUM','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('guide.question.answered','EVENT-1.0','GUIDE','question','answered','Golfer submits a governed question response during a guide or fitting workflow.','ACTIVE','ENGAGEMENT','MEDIUM','PERSONALIZATION','PERSONAL_ONLY','LONG_TERM',true),
  ('recommendation.run.started','EVENT-1.0','RECOMMENDATION','recommendation_run','started','A deterministic GAL recommendation run begins.','ACTIVE','INTENT','MEDIUM','PERSONALIZATION','PERSONAL_ONLY','STANDARD',true),
  ('recommendation.run.completed','EVENT-1.0','RECOMMENDATION','recommendation_run','completed','A deterministic GAL recommendation run completes.','ACTIVE','COMMITMENT','MEDIUM','PERSONALIZATION','PERSONAL_ONLY','LONG_TERM',true),
  ('recommendation.viewed','EVENT-1.0','RECOMMENDATION','recommendation','viewed','Golfer views a GAL recommendation result.','ACTIVE','ENGAGEMENT','LOW','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('recommendation.saved','EVENT-1.0','RECOMMENDATION','recommendation','saved','Golfer explicitly saves a GAL recommendation for later consideration.','ACTIVE','INTENT','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('product.viewed','EVENT-1.0','PRODUCT','product','viewed','Golfer views a product detail or product-focused result.','ACTIVE','ENGAGEMENT','LOW','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','SHORT',true),
  ('product.compared','EVENT-1.0','PRODUCT','product','compared','Golfer includes a product in an explicit comparison.','ACTIVE','INTENT','MEDIUM','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('bag.item.added','EVENT-1.0','BAG','bag_item','added','A golfer adds equipment to the authoritative current bag.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('bag.item.replaced','EVENT-1.0','BAG','bag_item','replaced','A golfer replaces equipment in the authoritative current bag.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('scenario.created','EVENT-1.0','BAG_SCENARIO','scenario','created','Golfer creates a what-if bag scenario without mutating the actual bag.','ACTIVE','INTENT','MEDIUM','PERSONALIZATION','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('scenario.adopted','EVENT-1.0','BAG_SCENARIO','scenario','adopted','Golfer explicitly adopts a governed bag scenario into the authoritative bag.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('commerce.route.clicked','EVENT-1.0','COMMERCE','commerce_route','clicked','Golfer follows a commerce route after GAL presents an eligible purchase path.','ACTIVE','INTENT','LOW','PRODUCT_ANALYTICS','AGGREGATE_ELIGIBLE','STANDARD',true),
  ('purchase.reported','EVENT-1.0','COMMERCE','purchase','reported','Golfer explicitly reports a purchase; this does not by itself establish current bag ownership.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('equipment.adopted','EVENT-1.0','EQUIPMENT','equipment','adopted','Golfer explicitly confirms equipment adoption or authoritative bag state establishes adoption.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true),
  ('recommendation.feedback.submitted','EVENT-1.0','RECOMMENDATION','recommendation_feedback','submitted','Golfer submits explicit feedback about a GAL recommendation or its outcome.','ACTIVE','OUTCOME','HIGH','PERSONALIZATION','AGGREGATE_ELIGIBLE','LONG_TERM',true)
on conflict (event_key, event_version) do update set
  domain = excluded.domain,
  object_type = excluded.object_type,
  action = excluded.action,
  description = excluded.description,
  status = excluded.status,
  signal_class = excluded.signal_class,
  profile_relevance = excluded.profile_relevance,
  operational_class = excluded.operational_class,
  commercial_class = excluded.commercial_class,
  retention_class = excluded.retention_class,
  is_active = excluded.is_active,
  updated_at = now();

-- EVENT-1.0 rows are complete governed definitions. Other future/draft versions may be
-- introduced through reviewed migrations before they become active production vocabulary.
alter table public.gal_event_catalog
  add constraint gal_event_catalog_active_semantics_complete_check
  check (
    status <> 'ACTIVE'
    or (
      domain is not null
      and object_type is not null
      and action is not null
      and description is not null
      and signal_class is not null
      and profile_relevance is not null
      and operational_class is not null
      and commercial_class is not null
      and retention_class is not null
      and is_active = true
    )
  );

-- Preserve the Foundation governance boundary explicitly.
revoke all on table public.gal_event_catalog from anon, authenticated;
grant select, insert, update, delete on table public.gal_event_catalog to service_role;

comment on table public.gal_event_catalog is
  'Governed semantic catalog for GAL behavioral events. Event observations are evidence and do not automatically become golfer facts.';
