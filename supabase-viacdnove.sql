-- Osobný diár: viacdňové akcie (dátum konca)
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

alter table public.events
  add column if not exists end_date date;

alter table public.events
  drop constraint if exists events_end_after_start;
alter table public.events
  add constraint events_end_after_start check (end_date is null or end_date >= event_date);
