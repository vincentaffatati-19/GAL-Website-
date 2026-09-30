-- RC14 account deletion regression: active bag items must not break full erasure.
-- Transactional only: this test must always roll back its synthetic auth user.
begin;

insert into auth.users(
  id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at
) values (
  'fe33b2ab-3940-40c1-8407-ac16fc02e399'::uuid,
  'authenticated','authenticated','rc14-delete-regression@invalid.example',now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"qa":"rc14_account_deletion_active_bag_regression"}'::jsonb,
  now(),now()
);

select set_config('request.jwt.claim.sub','fe33b2ab-3940-40c1-8407-ac16fc02e399',true);
set local role authenticated;

select public.gal_add_to_my_bag(
  jsonb_build_object(
    'canonicalProductId','GAL-DRV-0003',
    'status','IN_BAG',
    'displaySnapshot',jsonb_build_object('brand','TaylorMade','model','Qi4D Max'),
    'configuration','{}'::jsonb,
    'components',jsonb_build_array(jsonb_build_object('slotCode','D','slotLabel','Driver','clubCount',1,'configuration','{}'::jsonb)),
    'decision',jsonb_build_object(
      'sourceTool','rc14_account_deletion_regression',
      'sourceToolVersion','1.0',
      'recommendationRank',1,
      'userInputs',jsonb_build_object('synthetic',true),
      'metrics',jsonb_build_object('fixture',1),
      'reasonSummary','Synthetic active-bag deletion regression',
      'marketCode','US'
    )
  )
);

select public.gal_request_account_deletion();
reset role;

-- RED on the current RC14 implementation: bag-item cascade invokes
-- gal_private.capture_bag_history_event() after gal_users has been deleted,
-- violating gal_bag_history_events_user_id_fkey.
select public.gal_finalize_account_deletion(
  (select id from public.gal_users where auth_user_id='fe33b2ab-3940-40c1-8407-ac16fc02e399'::uuid)
);

do $$
begin
  if exists (
    select 1 from public.gal_users
    where auth_user_id='fe33b2ab-3940-40c1-8407-ac16fc02e399'::uuid
  ) then
    raise exception 'REGRESSION_FAILED_GAL_USER_STILL_PRESENT';
  end if;
end $$;

rollback;
