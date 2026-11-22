-- Papageno · étape 4 : le bocal partagé (tickets, mots doux)
-- À coller dans Supabase > SQL Editor > New query, puis « Run ».
-- Le site n'a pas accès direct aux tables : il passe par les fonctions ci-dessous.
-- Un ticket « à relire » (risque détecté) reste caché jusqu'à ce que l'organisatrice le publie.

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  handle text not null default 'Visiteur',
  lines jsonb not null default '[]'::jsonb,
  note text,
  risk text not null default 'none',
  status text not null default 'published' check (status in ('published', 'held', 'hidden')),
  author_hash text not null
);

create table if not exists public.replies (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  handle text not null default 'Client',
  body text not null,
  risk text not null default 'none',
  status text not null default 'published' check (status in ('published', 'held', 'hidden')),
  author_hash text not null
);

alter table public.tickets enable row level security;
alter table public.replies enable row level security;
revoke all on public.tickets from anon, authenticated;
revoke all on public.replies from anon, authenticated;

-- Publie un ticket. Le jeton reste sur l'appareil ; la base ne garde que son empreinte.
create or replace function public.publier_ticket(p_handle text, p_lines jsonb, p_note text, p_risk text, p_token text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  new_id uuid;
begin
  insert into public.tickets (handle, lines, note, risk, status, author_hash)
  values (
    left(coalesce(nullif(trim(p_handle), ''), 'Visiteur'), 40),
    coalesce(p_lines, '[]'::jsonb),
    left(coalesce(p_note, ''), 500),
    coalesce(p_risk, 'none'),
    case when coalesce(p_risk, 'none') = 'none' then 'published' else 'held' end,
    encode(extensions.digest(p_token, 'sha256'), 'hex')
  )
  returning id into new_id;
  return new_id;
end;
$$;

-- Le bocal : les tickets publiés des autres (jamais l'auteur, jamais les tickets à relire)
create or replace function public.lire_bocal(p_token text, p_limit int default 60)
returns table (id uuid, created_at timestamptz, handle text, lines jsonb, note text)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select t.id, t.created_at, t.handle, t.lines, t.note
  from public.tickets t
  where t.status = 'published'
    and t.author_hash <> encode(extensions.digest(p_token, 'sha256'), 'hex')
  order by t.created_at desc
  limit least(greatest(p_limit, 1), 100);
$$;

-- Un mot doux (réponse) à un ticket publié
create or replace function public.repondre_ticket(p_ticket_id uuid, p_handle text, p_body text, p_risk text, p_token text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  st text;
begin
  st := case when coalesce(p_risk, 'none') = 'none' then 'published' else 'held' end;
  insert into public.replies (ticket_id, handle, body, risk, status, author_hash)
  select p_ticket_id, left(coalesce(nullif(trim(p_handle), ''), 'Client'), 40), left(p_body, 500),
         coalesce(p_risk, 'none'), st, encode(extensions.digest(p_token, 'sha256'), 'hex')
  from public.tickets t
  where t.id = p_ticket_id and t.status = 'published';
  return st;
end;
$$;

-- Mes tickets, avec les mots doux publiés reçus (uniquement ceux de cet appareil)
create or replace function public.lire_mes_tickets(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', t.id, 'created_at', t.created_at, 'handle', t.handle, 'lines', t.lines, 'note', t.note, 'status', t.status,
      'replies', coalesce((
          select jsonb_agg(jsonb_build_object('id', r.id, 'created_at', r.created_at, 'handle', r.handle, 'body', r.body, 'status', r.status) order by r.created_at)
          from public.replies r where r.ticket_id = t.id and r.status = 'published'
      ), '[]'::jsonb)
    ) order by t.created_at desc), '[]'::jsonb)
  from public.tickets t
  where t.author_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
$$;

grant execute on function public.publier_ticket(text, jsonb, text, text, text) to anon, authenticated;
grant execute on function public.lire_bocal(text, int) to anon, authenticated;
grant execute on function public.repondre_ticket(uuid, text, text, text, text) to anon, authenticated;
grant execute on function public.lire_mes_tickets(text) to anon, authenticated;
