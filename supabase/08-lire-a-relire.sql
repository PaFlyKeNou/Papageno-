-- Papageno · étape 8 : la liste à relire, en lecture seule, pour l'agent de relecture (Geno)
-- À coller dans Supabase > SQL Editor > New query, puis « Run », après les étapes précédentes.
-- La fonction ne modifie rien. Elle refuse toute personne qui n'a pas la clé de Geno.
-- Elle ne renvoie jamais les empreintes des auteurs.

create or replace function public.lire_a_relire(p_cle text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
begin
  if encode(extensions.digest(coalesce(p_cle, ''), 'sha256'), 'hex') <> 'd0abf7b42fd2e3b565f32ffd6370ffe8f18de1f2ea14f9371a9054481d1a7172' then
    raise exception 'Clé refusée';
  end if;
  return coalesce((
    select jsonb_agg(q.x order by q.x->>'created_at' desc)
    from (
      select jsonb_build_object(
        'type', 'ticket', 'id', t.id, 'created_at', t.created_at, 'handle', t.handle,
        'note', t.note, 'risk', t.risk, 'status', t.status,
        'signalements', (select count(*) from public.signalements s where s.ticket_id = t.id)
      ) as x
      from public.tickets t
      where t.status = 'held'
      union all
      select jsonb_build_object(
        'type', 'mot doux', 'id', r.id, 'created_at', r.created_at, 'handle', r.handle,
        'body', r.body, 'risk', r.risk, 'status', r.status
      )
      from public.replies r
      where r.status = 'held'
    ) q
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.lire_a_relire(text) to anon, authenticated;
