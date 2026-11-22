-- Papageno · étape 7 : effacer mes tickets et mes mots doux (désinscription des Rencontres)
-- À coller dans Supabase > SQL Editor > New query, puis « Run », après les étapes précédentes.
-- Efface les tickets imprimés par cette personne, et ses mots doux. Les mots doux reçus sur ses tickets disparaissent avec eux.

create or replace function public.effacer_mes_tickets(p_token text)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  n int;
  h text := encode(extensions.digest(p_token, 'sha256'), 'hex');
begin
  delete from public.replies where author_hash = h;
  delete from public.tickets where author_hash = h;
  get diagnostics n = row_count;
  return n;
end;
$$;

grant execute on function public.effacer_mes_tickets(text) to anon, authenticated;
