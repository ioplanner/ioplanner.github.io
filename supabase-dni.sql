-- Osobný diár: vlastný čas od – do pre každý deň viacdňovej akcie
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

alter table public.events
  add column if not exists days jsonb;
