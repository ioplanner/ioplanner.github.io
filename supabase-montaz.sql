-- Osobný diár: zoznam na montáž pri akcii (ostane aj po odstránení alebo výmene cenovej ponuky)
-- Spusti raz v Supabase: SQL Editor → New query → vlož celý text → Run.
-- Nič existujúce neprepíše, dá sa spustiť aj opakovane.

alter table public.events
  add column if not exists packlist jsonb;
