-- Osobný diár: tabuľka akcií a bezpečnostné pravidlá
-- Celý tento text vlož v Supabase do SQL Editora a klikni Run.

create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 200),
  event_date  date not null,
  start_time  time,
  end_time    time,
  status      text not null default 'todo' check (status in ('todo', 'doing', 'done')),
  notes       text not null default '',
  checklist   jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists events_user_date_idx on public.events (user_id, event_date);

-- Pri každej zmene sa automaticky zapíše čas úpravy
create or replace function public.events_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists events_touch on public.events;
create trigger events_touch before update on public.events
  for each row execute function public.events_touch();

-- Každý používateľ vidí a mení iba svoje vlastné akcie
alter table public.events enable row level security;

drop policy if exists "vlastne akcie - citanie" on public.events;
drop policy if exists "vlastne akcie - pridanie" on public.events;
drop policy if exists "vlastne akcie - uprava" on public.events;
drop policy if exists "vlastne akcie - mazanie" on public.events;

create policy "vlastne akcie - citanie" on public.events
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "vlastne akcie - pridanie" on public.events
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "vlastne akcie - uprava" on public.events
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "vlastne akcie - mazanie" on public.events
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Živé aktualizácie medzi zariadeniami (Realtime)
do $$
begin
  alter publication supabase_realtime add table public.events;
exception when duplicate_object then null;
end $$;
