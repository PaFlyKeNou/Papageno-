-- Papageno · étape 1 : les codes du porte-monnaie
-- À coller dans Supabase > SQL Editor > New query, puis « Run ».
-- Les visiteurs n'ont jamais accès direct à la table : ils passent par les deux fonctions ci-dessous.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.porte_monnaie (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,          -- on ne garde jamais le code lui-même, seulement son empreinte
  handle text not null default 'Visiteur',
  created_at timestamptz not null default now()
);

alter table public.porte_monnaie enable row level security;
revoke all on public.porte_monnaie from anon, authenticated;

-- Crée un porte-monnaie et renvoie son code (12 caractères, sans 0, O, 1, I ni L)
create or replace function public.creer_porte_monnaie(p_handle text default 'Visiteur')
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';   -- 31 caractères
  bytes bytea;
  code text;
  h text;
  i int;
begin
  loop
    bytes := extensions.gen_random_bytes(12);
    code := '';
    for i in 0..11 loop
      code := code || substr(alphabet, 1 + (get_byte(bytes, i) % 31), 1);
    end loop;
    h := encode(extensions.digest(code, 'sha256'), 'hex');
    exit when not exists (select 1 from public.porte_monnaie where code_hash = h);
  end loop;
  insert into public.porte_monnaie (code_hash, handle)
  values (h, left(coalesce(nullif(trim(p_handle), ''), 'Visiteur'), 40));
  return code;
end;
$$;

-- Ouvre un porte-monnaie avec son code : renvoie son pseudo, ou rien si le code est inconnu
create or replace function public.ouvrir_porte_monnaie(p_code text)
returns table (handle text)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select pm.handle
  from public.porte_monnaie pm
  where pm.code_hash = encode(
    extensions.digest(upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')), 'sha256'),
    'hex')
  limit 1;
$$;

grant execute on function public.creer_porte_monnaie(text) to anon, authenticated;
grant execute on function public.ouvrir_porte_monnaie(text) to anon, authenticated;
