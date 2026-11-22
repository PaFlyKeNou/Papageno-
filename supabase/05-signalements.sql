-- Papageno · étape 5 : les signalements de tickets
-- À coller dans Supabase > SQL Editor > New query, puis « Run ».
-- Un signalement met le ticket « à relire » (il disparaît du bocal) ; une même personne ne signale qu'une fois.

create table if not exists public.signalements (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  author_hash text not null,
  unique (ticket_id, author_hash)
);

alter table public.signalements enable row level security;
revoke all on public.signalements from anon, authenticated;

create or replace function public.signaler_ticket(p_ticket_id uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  insert into public.signalements (ticket_id, author_hash)
  values (p_ticket_id, encode(extensions.digest(p_token, 'sha256'), 'hex'))
  on conflict (ticket_id, author_hash) do nothing;

  update public.tickets set status = 'held'
  where id = p_ticket_id and status = 'published';
end;
$$;

grant execute on function public.signaler_ticket(uuid, text) to anon, authenticated;
