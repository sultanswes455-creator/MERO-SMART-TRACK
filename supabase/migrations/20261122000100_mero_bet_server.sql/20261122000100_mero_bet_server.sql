
-- =====================================================
-- MERO BET - SUPABASE DATABASE SERVER
-- Currency: JOD (1000 fils = 1 JOD)
-- Manual Orange Money / CliQ wallet workflow
-- =====================================================

create extension if not exists pgcrypto;

create type public.mero_role as enum ('player','owner');
create type public.mero_event_status as enum
('upcoming','live','finished','cancelled');
create type public.mero_result as enum
('pending','won','lost','void');
create type public.mero_bet_status as enum
('open','won','lost','void');
create type public.mero_request_kind as enum
('deposit','withdrawal');
create type public.mero_request_status as enum
('pending','approved','rejected');

-- =====================================================
-- PROFILES
-- =====================================================

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role public.mero_role not null default 'player',
  created_at timestamptz not null default now()
);

-- =====================================================
-- SPORTS EVENTS
-- =====================================================

create table public.events (
  id uuid primary key default gen_random_uuid(),
  sport text not null,
  league text not null default '',
  home_name text not null,
  away_name text not null,
  starts_at timestamptz not null,
  status public.mero_event_status not null default 'upcoming',
  created_at timestamptz not null default now()
);

create table public.markets (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id),
  name text not null,
  is_open boolean not null default true
);

create table public.selections (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id),
  label text not null,
  odds numeric(10,3) not null check (odds > 1 and odds <= 1000),
  is_active boolean not null default true,
  result public.mero_result not null default 'pending'
);

-- =====================================================
-- BETS
-- =====================================================

create table public.bets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  stake_fils bigint not null check (stake_fils > 0),
  combined_odds numeric(18,6) not null,
  potential_payout_fils bigint not null,
  actual_payout_fils bigint not null default 0,
  status public.mero_bet_status not null default 'open',
  created_at timestamptz not null default now(),
  settled_at timestamptz
);

create table public.bet_items (
  id uuid primary key default gen_random_uuid(),
  bet_id uuid not null references public.bets(id) on delete cascade,
  event_id uuid not null references public.events(id),
  market_id uuid not null references public.markets(id),
  selection_id uuid not null references public.selections(id),
  selection_label text not null,
  odds_snapshot numeric(10,3) not null
);

-- =====================================================
-- WALLET LEDGER
-- All amounts are integer fils.
-- =====================================================

create table public.wallet_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  amount_fils bigint not null check (amount_fils <> 0),
  entry_type text not null,
  reference_id uuid,
  idempotency_key text unique,
  note text not null default '',
  created_at timestamptz not null default now()
);

-- =====================================================
-- DEPOSIT / WITHDRAWAL REQUESTS
-- =====================================================

create table public.wallet_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  kind public.mero_request_kind not null,
  amount_fils bigint not null check (amount_fils > 0),
  method text not null check (method in ('Orange Money','CliQ')),
  payment_reference text not null default '',
  destination text not null default '',
  proof_path text,
  status public.mero_request_status not null default 'pending',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  review_note text not null default '',
  created_at timestamptz not null default now()
);

-- =====================================================
-- INDEXES
-- =====================================================

create index events_start_idx
on public.events(starts_at);

create index markets_event_idx
on public.markets(event_id);

create index selections_market_idx
on public.selections(market_id);

create index bets_user_idx
on public.bets(user_id,created_at desc);

create index ledger_user_idx
on public.wallet_ledger(user_id,created_at desc);

create index requests_user_idx
on public.wallet_requests(user_id,created_at desc);

-- =====================================================
-- OWNER CHECK
-- =====================================================

create or replace function public.mero_is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'owner'
  );
$$;

-- =====================================================
-- CURRENT PLAYER BALANCE
-- =====================================================

create or replace function public.mero_balance()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
begin
  if v_user is null then
    raise exception 'Login required';
  end if;

  return (
    select coalesce(sum(amount_fils),0)::bigint
    from public.wallet_ledger
    where user_id = v_user
  );
end;
$$;

-- =====================================================
-- CREATE PROFILE AFTER SIGNUP
-- =====================================================

create or replace function public.mero_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles(id,display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name','')
  );
  return new;
end;
$$;

create trigger mero_auth_user_created
after insert on auth.users
for each row execute procedure public.mero_new_user();

-- Add profiles for existing accounts
insert into public.profiles(id,display_name)
select id, coalesce(raw_user_meta_data->>'display_name','')
from auth.users
on conflict (id) do nothing;

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.markets enable row level security;
alter table public.selections enable row level security;
alter table public.bets enable row level security;
alter table public.bet_items enable row level security;
alter table public.wallet_ledger enable row level security;
alter table public.wallet_requests enable row level security;

create policy profile_read
on public.profiles for select
to authenticated
using (
  id = (select auth.uid())
  or (select public.mero_is_owner())
);

create policy events_read
on public.events for select
to authenticated
using (true);

create policy events_owner
on public.events for all
to authenticated
using ((select public.mero_is_owner()))
with check ((select public.mero_is_owner()));

create policy markets_read
on public.markets for select
to authenticated
using (true);

create policy markets_owner
on public.markets for all
to authenticated
using ((select public.mero_is_owner()))
with check ((select public.mero_is_owner()));

create policy selections_read
on public.selections for select
to authenticated
using (true);

create policy selections_owner
on public.selections for all
to authenticated
using ((select public.mero_is_owner()))
with check ((select public.mero_is_owner()));

create policy bets_read
on public.bets for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select public.mero_is_owner())
);

create policy bet_items_read
on public.bet_items for select
to authenticated
using (
  exists (
    select 1
    from public.bets b
    where b.id = bet_id
      and (
        b.user_id = (select auth.uid())
        or (select public.mero_is_owner())
      )
  )
);

create policy ledger_read
on public.wallet_ledger for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select public.mero_is_owner())
);

create policy requests_read
on public.wallet_requests for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select public.mero_is_owner())
);

-- =====================================================
-- PREVENT DIRECT CLIENT FINANCIAL WRITES
-- =====================================================

revoke all on public.wallet_ledger from anon, authenticated;
revoke all on public.bets from anon, authenticated;
revoke all on public.bet_items from anon, authenticated;
revoke all on public.wallet_requests from anon, authenticated;

grant select on public.wallet_ledger to authenticated;
grant select on public.bets to authenticated;
grant select on public.bet_items to authenticated;
grant select on public.wallet_requests to authenticated;

revoke insert,update,delete on public.profiles
from anon, authenticated;

grant select on public.profiles to authenticated;

-- =====================================================
-- PLACE BET
-- =====================================================

create or replace function public.mero_place_bet(
  p_selection_ids uuid[],
  p_stake_fils bigint
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_bet uuid := gen_random_uuid();
  v_balance bigint;
  v_odds numeric(18,6) := 1;
  v_payout bigint;
  v_count integer := 0;
  v_distinct_events integer;
  r record;
begin
  if v_user is null then
    raise exception 'Login required';
  end if;

  if p_stake_fils < 100 or p_stake_fils > 100000000 then
    raise exception 'Stake outside configured limits';
  end if;

  if p_selection_ids is null
     or cardinality(p_selection_ids) < 1
     or cardinality(p_selection_ids) > 20 then
    raise exception 'Invalid selections';
  end if;

  if (
    select count(distinct x)
    from unnest(p_selection_ids) as t(x)
  ) <> cardinality(p_selection_ids) then
    raise exception 'Duplicate selections';
  end if;

  -- Lock the player's account before checking balance.
  perform 1
  from public.profiles
  where id = v_user
  for update;

  if not found then
    raise exception 'Profile not found';
  end if;

  select coalesce(sum(amount_fils),0)
  into v_balance
  from public.wallet_ledger
  where user_id = v_user;

  if v_balance < p_stake_fils then
    raise exception 'Insufficient balance';
  end if;

  -- Do not allow two selections from the same event in one bet.
  select count(distinct m.event_id)
  into v_distinct_events
  from public.selections s
  join public.markets m on m.id = s.market_id
  where s.id = any(p_selection_ids);

  if v_distinct_events <> cardinality(p_selection_ids) then
    raise exception 'Only one selection per event is allowed';
  end if;

  for r in
    select
      s.id,
      s.label,
      s.odds,
      s.market_id,
      m.event_id,
      m.is_open,
      s.is_active,
      e.status,
      e.starts_at
    from unnest(p_selection_ids) with ordinality q(id,n)
    join public.selections s on s.id = q.id
    join public.markets m on m.id = s.market_id
    join public.events e on e.id = m.event_id
    order by q.n
    for update of s,m,e
  loop
    v_count := v_count + 1;

    if not r.is_active
       or not r.is_open
       or r.status <> 'upcoming'
       or r.starts_at <= now() then
      raise exception 'Selection is closed';
    end if;

    v_odds := v_odds * r.odds;
  end loop;

  if v_count <> cardinality(p_selection_ids) then
    raise exception 'Invalid selection ID';
  end if;

  v_payout := floor(p_stake_fils * v_odds)::bigint;

  insert into public.bets(
    id,user_id,stake_fils,combined_odds,potential_payout_fils
  )
  values (
    v_bet,v_user,p_stake_fils,v_odds,v_payout
  );

  insert into public.bet_items(
    bet_id,event_id,market_id,selection_id,
    selection_label,odds_snapshot
  )
  select
    v_bet,m.event_id,m.id,s.id,s.label,s.odds
  from public.selections s
  join public.markets m on m.id=s.market_id
  where s.id = any(p_selection_ids);

  insert into public.wallet_ledger(
    user_id,amount_fils,entry_type,reference_id,idempotency_key,note
  )
  values (
    v_user,-p_stake_fils,'bet_stake',v_bet,
    'bet_stake:' || v_bet::text,
    'Bet stake'
  );

  return v_bet;
end;
$$;

-- =====================================================
-- CREATE DEPOSIT OR WITHDRAWAL REQUEST
-- Withdrawal amount is reserved immediately.
-- Deposit is credited only after owner approval.
-- =====================================================

create or replace function public.mero_create_wallet_request(
  p_kind public.mero_request_kind,
  p_amount_fils bigint,
  p_method text,
  p_payment_reference text default '',
  p_destination text default '',
  p_proof_path text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_id uuid := gen_random_uuid();
  v_balance bigint;
begin
  if v_user is null then
    raise exception 'Login required';
  end if;

  if p_amount_fils < 100 or p_amount_fils > 100000000 then
    raise exception 'Invalid amount';
  end if;

  if p_method not in ('Orange Money','CliQ') then
    raise exception 'Invalid payment method';
  end if;

  perform 1 from public.profiles
  where id=v_user
  for update;

  if not found then
    raise exception 'Profile not found';
  end if;

  if p_kind = 'withdrawal' then
    select coalesce(sum(amount_fils),0)
    into v_balance
    from public.wallet_ledger
    where user_id=v_user;

    if v_balance < p_amount_fils then
      raise exception 'Insufficient balance';
    end if;
  end if;

  insert into public.wallet_requests(
    id,user_id,kind,amount_fils,method,
    payment_reference,destination,proof_path
  )
  values (
    v_id,v_user,p_kind,p_amount_fils,p_method,
    coalesce(p_payment_reference,''),
    coalesce(p_destination,''),
    p_proof_path
  );

  if p_kind = 'withdrawal' then
    insert into public.wallet_ledger(
      user_id,amount_fils,entry_type,reference_id,
      idempotency_key,note
    )
    values (
      v_user,-p_amount_fils,'withdrawal_hold',v_id,
      'withdrawal_hold:' || v_id::text,
      'Withdrawal pending'
    );
  end if;

  return v_id;
end;
$$;

-- =====================================================
-- OWNER REVIEWS DEPOSIT / WITHDRAWAL
-- =====================================================

create or replace function public.mero_review_wallet_request(
  p_request_id uuid,
  p_approve boolean,
  p_note text default ''
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.wallet_requests%rowtype;
  v_owner uuid := (select auth.uid());
begin
  if not (select public.mero_is_owner()) then
    raise exception 'Owner access required';
  end if;

  select *
  into v_request
  from public.wallet_requests
  where id=p_request_id
  for update;

  if not found then
    raise exception 'Request not found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Request already reviewed';
  end if;

  -- Serialize wallet operations for this player.
  perform 1
  from public.profiles
  where id=v_request.user_id
  for update;

  if p_approve then
    if v_request.kind = 'deposit' then
      insert into public.wallet_ledger(
        user_id,amount_fils,entry_type,reference_id,
        idempotency_key,note
      )
      values (
        v_request.user_id,
        v_request.amount_fils,
        'deposit',
        v_request.id,
        'deposit:' || v_request.id::text,
        'Approved deposit'
      );
    end if;

    update public.wallet_requests
    set status='approved',
        reviewed_by=v_owner,
        reviewed_at=now(),
        review_note=coalesce(p_note,'')
    where id=p_request_id;

  else
    if v_request.kind = 'withdrawal' then
      insert into public.wallet_ledger(
        user_id,amount_fils,entry_type,reference_id,
        idempotency_key,note
      )
      values (
        v_request.user_id,
        v_request.amount_fils,
        'withdrawal_refund',
        v_request.id,
        'withdrawal_refund:' || v_request.id::text,
        'Rejected withdrawal refund'
      );
    end if;

    update public.wallet_requests
    set status='rejected',
        reviewed_by=v_owner,
        reviewed_at=now(),
        review_note=coalesce(p_note,'')
    where id=p_request_id;
  end if;
end;
$$;

-- =====================================================
-- SETTLE BET
-- Selection results must be entered by the owner.
-- =====================================================

create or replace function public.mero_settle_bet(
  p_bet_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bet public.bets%rowtype;
  v_lost integer;
  v_pending integer;
  v_won integer;
  v_void integer;
  v_payout bigint;
  v_odds numeric(18,6) := 1;
  r record;
  v_status public.mero_bet_status;
begin
  if not (select public.mero_is_owner()) then
    raise exception 'Owner access required';
  end if;

  select *
  into v_bet
  from public.bets
  where id=p_bet_id
  for update;

  if not found then
    raise exception 'Bet not found';
  end if;

  if v_bet.status <> 'open' then
    raise exception 'Bet already settled';
  end if;

  select
    count(*) filter (where s.result='lost'),
    count(*) filter (where s.result='pending'),
    count(*) filter (where s.result='won'),
    count(*) filter (where s.result='void')
  into v_lost,v_pending,v_won,v_void
  from public.bet_items bi
  join public.selections s on s.id=bi.selection_id
  join public.events e on e.id=bi.event_id
  where bi.bet_id=p_bet_id
    and e.status not in ('upcoming','live');

  if v_pending > 0 then
    raise exception 'Some selections are not settled';
  end if;

  if (
    select count(*)
    from public.bet_items
    where bet_id=p_bet_id
  ) = 0 then
    raise exception 'Bet has no selections';
  end if;

  if v_lost > 0 then
    v_status := 'lost';
    v_payout := 0;

  elsif v_won = 0 and v_void > 0 then
    v_status := 'void';
    v_payout := v_bet.stake_fils;

  else
    v_status := 'won';

    for r in
      select bi.odds_snapshot,s.result
      from public.bet_items bi
      join public.selections s on s.id=bi.selection_id
      where bi.bet_id=p_bet_id
    loop
      if r.result='won' then
        v_odds := v_odds * r.odds_snapshot;
      end if;
    end loop;

    v_payout := floor(v_bet.stake_fils * v_odds)::bigint;
  end if;

  update public.bets
  set status=v_status,
      actual_payout_fils=v_payout,
      settled_at=now()
  where id=p_bet_id;

  if v_payout > 0 then
    insert into public.wallet_ledger(
      user_id,amount_fils,entry_type,reference_id,
      idempotency_key,note
    )
    values (
      v_bet.user_id,
      v_payout,
      'bet_payout',
      p_bet_id,
      'bet_payout:' || p_bet_id::text,
      'Bet settlement payout'
    );
  end if;
end;
$$;

-- =====================================================
-- FUNCTION PERMISSIONS
-- =====================================================

revoke all on function public.mero_is_owner() from public;
revoke all on function public.mero_balance() from public;
revoke all on function public.mero_place_bet(uuid[],bigint) from public;
revoke all on function public.mero_create_wallet_request(
  public.mero_request_kind,bigint,text,text,text,text
) from public;
revoke all on function public.mero_review_wallet_request(uuid,boolean,text)
from public;
revoke all on function public.mero_settle_bet(uuid) from public;

grant execute on function public.mero_is_owner()
to authenticated;

grant execute on function public.mero_balance()
to authenticated;

grant execute on function public.mero_place_bet(uuid[],bigint)
to authenticated;

grant execute on function public.mero_create_wallet_request(
  public.mero_request_kind,bigint,text,text,text,text
) to authenticated;

grant execute on function public.mero_review_wallet_request(uuid,boolean,text)
to authenticated;

grant execute on function public.mero_settle_bet(uuid)
to authenticated;

-- =====================================================
-- OWNER SETUP
-- After creating your own account in Supabase Auth,
-- copy its UUID and run this separately in SQL Editor:
--
-- update public.profiles
-- set role = 'owner'
-- where id = 'YOUR_AUTH_USER_UUID';
--
-- Never give players permission to change their role.
-- =====================================================
