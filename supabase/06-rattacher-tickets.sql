-- Papageno · étape 6 : les tickets suivent le code porte-monnaie
-- À coller dans Supabase > SQL Editor > New query, puis « Run », après les étapes précédentes.
-- Quand un visiteur reçoit son code, les tickets imprimés sur son appareil lui sont rattachés.
-- Le code n'est jamais stocké : seule son empreinte sert à retrouver les tickets.

create or replace function public.rattacher_tickets(p_token text, p_code text)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  n int;
begin
  update public.tickets
  set author_hash = encode(extensions.digest('pm:' || upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')), 'sha256'), 'hex')
  where author_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
  get diagnostics n = row_count;
  return n;
end;
$$;

grant execute on function public.rattacher_tickets(text, text) to anon, authenticated;
