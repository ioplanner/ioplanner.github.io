-- Osobný diár: prílohy (PDF cenové ponuky, faktúry…)
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Dá sa spustiť aj opakovane, nič sa nepokazí.

-- 1) Stĺpec so zoznamom príloh pri každej akcii
alter table public.events
  add column if not exists attachments jsonb not null default '[]'::jsonb;

-- 2) Súkromné úložisko súborov: iba PDF, max 20 MB na súbor
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('prilohy', 'prilohy', false, 20971520, array['application/pdf'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 3) Každý používateľ vidí a mení iba súbory vo svojom priečinku (<id používateľa>/...)
drop policy if exists "prilohy - citanie"  on storage.objects;
drop policy if exists "prilohy - nahranie" on storage.objects;
drop policy if exists "prilohy - uprava"   on storage.objects;
drop policy if exists "prilohy - mazanie"  on storage.objects;

create policy "prilohy - citanie" on storage.objects
  for select to authenticated
  using (bucket_id = 'prilohy' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "prilohy - nahranie" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'prilohy' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "prilohy - uprava" on storage.objects
  for update to authenticated
  using (bucket_id = 'prilohy' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'prilohy' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "prilohy - mazanie" on storage.objects
  for delete to authenticated
  using (bucket_id = 'prilohy' and (storage.foldername(name))[1] = (select auth.uid())::text);
