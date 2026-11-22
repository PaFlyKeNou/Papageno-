-- Papageno · étape 3 : désinscription des Rencontres
-- À coller dans Supabase > SQL Editor > New query, puis « Run », après l'étape 2.
-- Chaque inscription reçoit un jeton secret, gardé seulement sur l'appareil de la personne.
-- La base ne garde que son empreinte : sans le jeton, impossible d'effacer la ligne.

alter table public.inscriptions_rencontre add column if not exists token_hash text unique;

drop function if exists public.inscrire_rencontre(text, text, text, text[], text);

create or replace function public.inscrire_rencontre(p_name text, p_contact text, p_city text, p_acts text[], p_idea text, p_token text)
returns void
language sql
security definer
set search_path = public, extensions
as $$
  insert into public.inscriptions_rencontre (name, contact, city, acts, idea, token_hash)
  values (
    left(trim(p_name), 40),
    nullif(left(trim(coalesce(p_contact, '')), 80), ''),
    nullif(left(trim(coalesce(p_city, '')), 50), ''),
    coalesce(p_acts, '{}'),
    nullif(left(trim(coalesce(p_idea, '')), 80), ''),
    encode(extensions.digest(p_token, 'sha256'), 'hex')
  );
$$;

create or replace function public.desinscrire_rencontre(p_token text)
returns void
language sql
security definer
set search_path = public, extensions
as $$
  delete from public.inscriptions_rencontre
  where token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
$$;

grant execute on function public.inscrire_rencontre(text, text, text, text[], text, text) to anon, authenticated;
grant execute on function public.desinscrire_rencontre(text) to anon, authenticated;
