-- Tien Len online play.
-- Clients only read these tables (filtered by RLS). Every write goes through
-- the `tienlen` Edge Function using the service role.

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_id uuid not null references auth.users on delete cascade,
  status text not null default 'lobby' check (status in ('lobby', 'playing', 'closed')),
  created_at timestamptz not null default now()
);

create table public.room_players (
  room_id uuid not null references public.rooms on delete cascade,
  seat smallint not null check (seat between 0 and 3),
  user_id uuid references auth.users on delete set null, -- null for bots
  display_name text not null,
  is_bot boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (room_id, seat)
);
create unique index room_players_user_idx
  on public.room_players (room_id, user_id) where user_id is not null;

-- Current game of a room. `state` is the public part of the engine state
-- (see supabase/functions/_shared/tienlen/engine.ts PublicState).
create table public.games (
  room_id uuid primary key references public.rooms on delete cascade,
  game_no int not null,
  state jsonb not null,
  version int not null default 0,
  updated_at timestamptz not null default now()
);

-- Private hands. Bots' hands have a null user_id and are never readable by clients.
create table public.hands (
  room_id uuid not null references public.rooms on delete cascade,
  seat smallint not null check (seat between 0 and 3),
  user_id uuid references auth.users on delete set null,
  cards jsonb not null,
  primary key (room_id, seat)
);

create or replace function public.is_room_member(rid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from room_players where room_id = rid and user_id = auth.uid()
  );
$$;

alter table public.rooms enable row level security;
alter table public.room_players enable row level security;
alter table public.games enable row level security;
alter table public.hands enable row level security;

create policy "members read rooms" on public.rooms
  for select to authenticated using (public.is_room_member(id));
create policy "members read players" on public.room_players
  for select to authenticated using (public.is_room_member(room_id));
create policy "members read games" on public.games
  for select to authenticated using (public.is_room_member(room_id));
create policy "owner reads hand" on public.hands
  for select to authenticated using (user_id = auth.uid());

-- Atomically write a new game state and all hands, guarded by an optimistic
-- version check. Returns false if another request updated the game first.
create or replace function public.save_game(
  p_room_id uuid,
  p_expected_version int,
  p_game_no int,
  p_state jsonb,
  p_hands jsonb -- [{seat, user_id, cards}]
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  rows int;
begin
  if p_expected_version is null then
    insert into games (room_id, game_no, state, version)
    values (p_room_id, p_game_no, p_state, 1)
    on conflict (room_id) do nothing;
  else
    update games
      set game_no = p_game_no, state = p_state,
          version = version + 1, updated_at = now()
      where room_id = p_room_id and version = p_expected_version;
  end if;
  get diagnostics rows = row_count;
  if rows = 0 then
    return false;
  end if;

  insert into hands (room_id, seat, user_id, cards)
  select p_room_id, (h->>'seat')::smallint, (h->>'user_id')::uuid, h->'cards'
  from jsonb_array_elements(p_hands) h
  on conflict (room_id, seat) do update
    set user_id = excluded.user_id, cards = excluded.cards
    where hands.cards is distinct from excluded.cards
       or hands.user_id is distinct from excluded.user_id;
  return true;
end;
$$;

revoke execute on function public.save_game from public, anon, authenticated;

-- Live updates for the lobby and table.
alter publication supabase_realtime
  add table public.rooms, public.room_players, public.games, public.hands;
