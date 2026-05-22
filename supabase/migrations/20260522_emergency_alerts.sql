-- alerts table
create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  severity text not null default 'high',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz
);

create index alerts_user_unack_idx on alerts(user_id) where acknowledged_at is null;

alter table alerts enable row level security;

create policy "users read own alerts" on alerts
  for select using (auth.uid() = user_id);

create policy "service role inserts alerts" on alerts
  for insert with check (true);

create policy "users update own alerts" on alerts
  for update using (auth.uid() = user_id);

-- device_push_tokens table
create table public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null,
  updated_at timestamptz not null default now()
);

create index dpt_user_idx on device_push_tokens(user_id);

alter table device_push_tokens enable row level security;

create policy "users manage own tokens" on device_push_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Enable Realtime for alerts
alter publication supabase_realtime add table alerts;
