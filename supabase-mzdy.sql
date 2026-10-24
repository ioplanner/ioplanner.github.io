-- Osobný diár: pracovné miesta (odberatelia s dohodnutou sadzbou) a mzdy
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

-- 1) Pracovné miesta: hodinová (hour), denná (day) alebo úkolová (task) sadzba
create table if not exists public.workplaces (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 120),
  rate_type  text not null default 'hour' check (rate_type in ('hour', 'day', 'task')),
  rate       numeric(12, 2) not null default 0 check (rate >= 0),
  note       text not null default '',
  archived   boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists workplaces_user_idx on public.workplaces (user_id, name);

alter table public.workplaces enable row level security;

drop policy if exists "vlastne pracovne miesta - citanie"  on public.workplaces;
drop policy if exists "vlastne pracovne miesta - pridanie" on public.workplaces;
drop policy if exists "vlastne pracovne miesta - uprava"   on public.workplaces;
drop policy if exists "vlastne pracovne miesta - mazanie"  on public.workplaces;

create policy "vlastne pracovne miesta - citanie" on public.workplaces
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "vlastne pracovne miesta - pridanie" on public.workplaces
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "vlastne pracovne miesta - uprava" on public.workplaces
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "vlastne pracovne miesta - mazanie" on public.workplaces
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 2) Pri akcii sa uloží pracovné miesto aj sadzba v čase zadania,
--    takže zmena sadzby neskôr nezmení staré akcie
alter table public.events
  add column if not exists work jsonb;

-- 3) Živé aktualizácie medzi zariadeniami
do $$
begin
  alter publication supabase_realtime add table public.workplaces;
exception when duplicate_object then null;
end $$;
