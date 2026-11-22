-- Papageno · étape 2 : la liste des inscriptions aux Rencontres
-- À coller dans Supabase > SQL Editor > New query, puis « Run ».
-- Le site ne peut qu'ajouter une ligne (via la fonction ci-dessous). Seule l'organisatrice lit la table, dans le tableau de bord Supabase.

create table if not exists public.inscriptions_rencontre (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  contact text,
  city text,
  acts text[] not null default '{}',
  idea text
);

alter table public.inscriptions_rencontre enable row level security;
revoke all on public.inscriptions_rencontre from anon, authenticated;

-- Ajoute une inscription. Le contact (pseudo ou e-mail) reste facultatif ; aucun numéro de portable n'est demandé.
create or replace function public.inscrire_rencontre(p_name text, p_contact text, p_city text, p_acts text[], p_idea text)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.inscriptions_rencontre (name, contact, city, acts, idea)
  values (
    left(trim(p_name), 40),
    nullif(left(trim(coalesce(p_contact, '')), 80), ''),
    nullif(left(trim(coalesce(p_city, '')), 50), ''),
    coalesce(p_acts, '{}'),
    nullif(left(trim(coalesce(p_idea, '')), 80), '')
  );
$$;

grant execute on function public.inscrire_rencontre(text, text, text, text[], text) to anon, authenticated;
