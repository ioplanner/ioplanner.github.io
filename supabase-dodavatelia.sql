-- Osobný diár: zoznam dodávateľov (meno, logo, predvolená DPH, archív) a logá odberateľov
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Obsahuje aj všetko zo supabase-loga.sql, takže stačí spustiť tento súbor.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

-- 1) Logo pri pracovnom mieste (odberateľovi)
alter table public.workplaces
  add column if not exists logo text;

-- 2) Dodávatelia
create table if not exists public.suppliers (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 120),
  logo       text,
  created_at timestamptz not null default now()
);

alter table public.suppliers
  add column if not exists vat smallint not null default 0;
alter table public.suppliers
  add column if not exists archived boolean not null default false;

alter table public.suppliers
  drop constraint if exists suppliers_vat_check;
alter table public.suppliers
  add constraint suppliers_vat_check check (vat in (0, 23));

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
