-- Osobný diár: logá odberateľov (pracovných miest) a dodávateľov
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

-- 1) Logo pri pracovnom mieste (malý obrázok, ukladá ho diár)
alter table public.workplaces
  add column if not exists logo text;

-- 2) Dodávatelia s logom
create table if not exists public.suppliers (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 120),
  logo       text,
  created_at timestamptz not null default now()
);

create unique index if not exists suppliers_user_name_idx on public.suppliers (user_id, lower(name));

alter table public.suppliers enable row level security;

drop policy if exists "vlastni dodavatelia - citanie"  on public.suppliers;
drop policy if exists "vlastni dodavatelia - pridanie" on public.suppliers;
drop policy if exists "vlastni dodavatelia - uprava"   on public.suppliers;
drop policy if exists "vlastni dodavatelia - mazanie"  on public.suppliers;

create policy "vlastni dodavatelia - citanie" on public.suppliers
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "vlastni dodavatelia - pridanie" on public.suppliers
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "vlastni dodavatelia - uprava" on public.suppliers
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "vlastni dodavatelia - mazanie" on public.suppliers
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 3) Živé aktualizácie medzi zariadeniami
do $$
begin
  alter publication supabase_realtime add table public.suppliers;
exception when duplicate_object then null;
end $$;
