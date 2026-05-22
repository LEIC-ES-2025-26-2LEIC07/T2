-- Fix: replace overly-permissive insert policy on alerts.
-- The previous policy allowed any role (including anon) to insert alerts for
-- any user_id. The service_role already bypasses RLS automatically, so it
-- does not need its own policy.
drop policy if exists "service role inserts alerts" on public.alerts;
drop policy if exists "users insert own alerts" on public.alerts;

create policy "users insert own alerts" on public.alerts
  for insert with check (auth.uid() = user_id);
