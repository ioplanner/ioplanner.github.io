-- Osobný diár: voľné poznámky a checklisty na nástenke (nepatria k žiadnej akcii)
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

create table if not exists public.notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title      text not null default '',
  body       text not null default '',
  items      jsonb not null default '[]'::jsonb,
  pinned     boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists notes_user_idx on public.notes (user_id, updated_at desc);

alter table public.notes enable row level security;

drop policy if exists "vlastne poznamky - citanie"  on public.notes;
drop policy if exists "vlastne poznamky - pridanie" on public.notes;
drop policy if exists "vlastne poznamky - uprava"   on public.notes;
drop policy if exists "vlastne poznamky - mazanie"  on public.notes;

create policy "vlastne poznamky - citanie" on public.notes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "vlastne poznamky - pridanie" on public.notes
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "vlastne poznamky - uprava" on public.notes
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "vlastne poznamky - mazanie" on public.notes
  for delete to authenticated using ((select auth.uid()) = user_id);

do $$
begin
  alter publication supabase_realtime add table public.notes;
exception when duplicate_object then null;
end $$;
