# Longitudinal Release Security Blockers

## Leaked-password protection

Status: BLOCKED BY SUPABASE PLAN

Supabase Security Advisor reports leaked-password protection disabled. Supabase documentation states this control is available on the Pro Plan and above. The current GAL Supabase organization is on the Free plan.

Required before real registered-golfer launch:

1. approve the Supabase plan change/cost separately;
2. upgrade the organization/project to a plan supporting leaked-password protection;
3. enable **Prevent use of leaked passwords** in Supabase Authentication password settings;
4. rerun Security Advisor in staging and production and require the warning to be absent.

This blocker does not justify weakening database controls or embedding a substitute password-breach list in GAL application code.
