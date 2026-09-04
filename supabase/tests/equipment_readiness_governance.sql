do $$ begin
  if to_regclass('public.gal_equipment_readiness_policies') is null then raise exception 'readiness policies missing'; end if;
  if to_regclass('public.gal_equipment_readiness_requirements') is null then raise exception 'readiness requirements missing'; end if;
  if to_regclass('public.gal_equipment_readiness_state') is null then raise exception 'readiness state missing'; end if;
  if to_regclass('public.gal_equipment_evidence_gaps') is null then raise exception 'evidence gaps missing'; end if;
  if to_regclass('public.gal_equipment_readiness_evaluations') is null then raise exception 'readiness evaluations missing'; end if;
end $$;

do $$ begin
  if exists (select 1 from public.gal_equipment_readiness_state where readiness_state='AI_FIT_READY' and blocking_gap_count>0) then
    raise exception 'AI_FIT_READY cannot have blocking gaps';
  end if;
end $$;