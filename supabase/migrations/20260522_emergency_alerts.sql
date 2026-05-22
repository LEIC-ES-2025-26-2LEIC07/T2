-- alerts table
create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  severity text not null default 'high',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz
);

create index if not exists alerts_user_unack_idx on alerts(user_id) where acknowledged_at is null;

alter table alerts enable row level security;

drop policy if exists "users read own alerts" on alerts;
create policy "users read own alerts" on alerts
  for select using (auth.uid() = user_id);

drop policy if exists "service role inserts alerts" on alerts;
drop policy if exists "users insert own alerts" on alerts;
create policy "users insert own alerts" on alerts
  for insert with check (auth.uid() = user_id);

drop policy if exists "users update own alerts" on alerts;
create policy "users update own alerts" on alerts
  for update using (auth.uid() = user_id);

-- device_push_tokens table
create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null,
  updated_at timestamptz not null default now()
);

create index if not exists dpt_user_idx on device_push_tokens(user_id);

alter table device_push_tokens enable row level security;

drop policy if exists "users manage own tokens" on device_push_tokens;
create policy "users manage own tokens" on device_push_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Enable Realtime for alerts (idempotent)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'alerts'
  ) then
    alter publication supabase_realtime add table alerts;
  end if;
end $$;
