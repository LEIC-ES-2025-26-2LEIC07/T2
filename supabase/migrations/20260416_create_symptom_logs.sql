create extension if not exists pgcrypto;

create table if not exists public.symptom_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  symptom_type text not null,
  severity int not null check (severity between 1 and 10),
  notes text,
  occurred_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.symptom_logs enable row level security;

drop policy if exists "Users can read their own symptom logs" on public.symptom_logs;
create policy "Users can read their own symptom logs"
on public.symptom_logs
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their own symptom logs" on public.symptom_logs;
create policy "Users can insert their own symptom logs"
on public.symptom_logs
for insert
with check (auth.uid() = user_id);
