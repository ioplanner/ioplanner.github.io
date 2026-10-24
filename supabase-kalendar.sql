-- Osobný diár: tajná adresa pre odoberaný kalendár (Kalendár Apple / iCloud)
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

-- Pre istotu: stĺpec s prílohami (ak ešte nebol spustený supabase-prilohy.sql)
alter table public.events
  add column if not exists attachments jsonb not null default '[]'::jsonb;

-- Jeden tajný kľúč na používateľa. Kto pozná adresu s kľúčom, vidí kalendár,
-- preto ju nikomu neposielaj. V diári sa dá kedykoľvek vytvoriť nová.
create table if not exists public.calendar_feeds (
  user_id    uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  token      text not null unique
             default (replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '')),
  created_at timestamptz not null default now()
);

alter table public.calendar_feeds enable row level security;

drop policy if exists "vlastny kalendar - citanie"  on public.calendar_feeds;
drop policy if exists "vlastny kalendar - pridanie" on public.calendar_feeds;
drop policy if exists "vlastny kalendar - mazanie"  on public.calendar_feeds;

create policy "vlastny kalendar - citanie" on public.calendar_feeds
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "vlastny kalendar - pridanie" on public.calendar_feeds
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "vlastny kalendar - mazanie" on public.calendar_feeds
  for delete to authenticated using ((select auth.uid()) = user_id);
