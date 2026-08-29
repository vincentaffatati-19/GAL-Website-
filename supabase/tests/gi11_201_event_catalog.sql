-- GI-1.1 Longitudinal Intelligence Task 1: governed EVENT-1.0 vocabulary.
-- Behavior is evidence, not truth. This test governs semantics before buyer-event extension.

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions, pg_catalog;

select plan(35);

select has_column('public','gal_event_catalog','signal_class','GI-EVENT-CAT-001 signal class exists');
select has_column('public','gal_event_catalog','profile_relevance','GI-EVENT-CAT-002 profile relevance exists');
select has_column('public','gal_event_catalog','operational_class','GI-EVENT-CAT-003 operational class exists');
select has_column('public','gal_event_catalog','commercial_class','GI-EVENT-CAT-004 commercial class exists');
select has_column('public','gal_event_catalog','retention_class','GI-EVENT-CAT-005 retention class exists');
select has_column('public','gal_event_catalog','is_active','GI-EVENT-CAT-006 active flag exists');

select ok(coalesce((select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='gal_event_catalog'),false),
 'GI-EVENT-CAT-007 event catalog RLS remains enabled');
select ok(not has_table_privilege('authenticated','public.gal_event_catalog','INSERT'),'GI-EVENT-CAT-008 golfer cannot create event semantics');
select ok(not has_table_privilege('authenticated','public.gal_event_catalog','UPDATE'),'GI-EVENT-CAT-009 golfer cannot rewrite event semantics');
select ok(not has_table_privilege('authenticated','public.gal_event_catalog','DELETE'),'GI-EVENT-CAT-010 golfer cannot delete event semantics');

select is((select count(*)::integer from public.gal_event_catalog where event_version='EVENT-1.0' and status='ACTIVE'),17,
 'GI-EVENT-CAT-011 EVENT-1.0 has exactly 17 active canonical events');

select ok(exists(select 1 from public.gal_event_catalog where event_key='guide.started' and event_version='EVENT-1.0'),'GI-EVENT-CAT-012 guide.started exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='guide.completed' and event_version='EVENT-1.0'),'GI-EVENT-CAT-013 guide.completed exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='guide.question.answered' and event_version='EVENT-1.0'),'GI-EVENT-CAT-014 guide.question.answered exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='recommendation.run.started' and event_version='EVENT-1.0'),'GI-EVENT-CAT-015 recommendation.run.started exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='recommendation.run.completed' and event_version='EVENT-1.0'),'GI-EVENT-CAT-016 recommendation.run.completed exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='recommendation.viewed' and event_version='EVENT-1.0'),'GI-EVENT-CAT-017 recommendation.viewed exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='recommendation.saved' and event_version='EVENT-1.0'),'GI-EVENT-CAT-018 recommendation.saved exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='product.viewed' and event_version='EVENT-1.0'),'GI-EVENT-CAT-019 product.viewed exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='product.compared' and event_version='EVENT-1.0'),'GI-EVENT-CAT-020 product.compared exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='bag.item.added' and event_version='EVENT-1.0'),'GI-EVENT-CAT-021 bag.item.added exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='bag.item.replaced' and event_version='EVENT-1.0'),'GI-EVENT-CAT-022 bag.item.replaced exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='scenario.created' and event_version='EVENT-1.0'),'GI-EVENT-CAT-023 scenario.created exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='scenario.adopted' and event_version='EVENT-1.0'),'GI-EVENT-CAT-024 scenario.adopted exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='commerce.route.clicked' and event_version='EVENT-1.0'),'GI-EVENT-CAT-025 commerce.route.clicked exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='purchase.reported' and event_version='EVENT-1.0'),'GI-EVENT-CAT-026 purchase.reported exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='equipment.adopted' and event_version='EVENT-1.0'),'GI-EVENT-CAT-027 equipment.adopted exists');
select ok(exists(select 1 from public.gal_event_catalog where event_key='recommendation.feedback.submitted' and event_version='EVENT-1.0'),'GI-EVENT-CAT-028 recommendation.feedback.submitted exists');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and (domain is null or object_type is null or action is null or description is null or status <> 'ACTIVE')
), 'GI-EVENT-CAT-029 every EVENT-1.0 row has governed semantic metadata');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and signal_class not in ('NAVIGATION','ENGAGEMENT','INTENT','COMMITMENT','OUTCOME')
), 'GI-EVENT-CAT-030 signal classes use governed values');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and profile_relevance not in ('NONE','LOW','MEDIUM','HIGH')
), 'GI-EVENT-CAT-031 profile relevance uses governed values');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and operational_class not in ('SERVICE_OPERATION','PERSONALIZATION','PRODUCT_ANALYTICS')
), 'GI-EVENT-CAT-032 operational classes use governed values');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and commercial_class not in ('PERSONAL_ONLY','AGGREGATE_ELIGIBLE','RESTRICTED_AGGREGATE','EXCLUDED')
), 'GI-EVENT-CAT-033 commercial classes use privacy-governed values');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0'
    and retention_class not in ('SHORT','STANDARD','LONG_TERM')
), 'GI-EVENT-CAT-034 retention classes use governed values');

select ok(not exists(
  select 1 from public.gal_event_catalog
  where event_version='EVENT-1.0' and is_active is distinct from true
), 'GI-EVENT-CAT-035 all EVENT-1.0 seed definitions are active');

select * from finish();
rollback;
