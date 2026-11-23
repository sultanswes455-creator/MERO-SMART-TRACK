
BEGIN;

-- =========================================
-- MERO BET - FIX CRASH WALLET INTEGRATION
-- wallet_ledger.amount is stored in JOD.
-- crash_rounds stake_fils and payout_fils
-- are stored in fils.
-- =========================================

-- 1. START CRASH ROUND
CREATE OR REPLACE FUNCTION public.mero_crash_start(
    p_stake numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_user uuid := auth.uid();
    v_locked uuid;
    v_stake_fils bigint;
    v_balance numeric;
    v_round public.crash_rounds%ROWTYPE;
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF p_stake IS NULL OR p_stake <= 0 THEN
        RAISE EXCEPTION 'Invalid stake';
    END IF;

    v_stake_fils := pg_catalog.round(p_stake * 1000)::bigint;

    IF v_stake_fils < 100 OR v_stake_fils > 435000 THEN
        RAISE EXCEPTION 'Stake must be between 0.100 and 435.000 JOD';
    END IF;

    SELECT id
    INTO v_locked
    FROM public.profiles
    WHERE id = v_user
    FOR UPDATE;

    IF v_locked IS NULL THEN
        RAISE EXCEPTION 'User profile not found';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.crash_rounds
        WHERE user_id = v_user
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'You already have an active crash round';
    END IF;

    SELECT COALESCE(pg_catalog.sum(amount), 0)
    INTO v_balance
    FROM public.wallet_ledger
    WHERE user_id = v_user;

    IF v_balance < (v_stake_fils / 1000.0) THEN
        RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;

    INSERT INTO public.crash_rounds (
        user_id,
        stake_fils,
        crash_point
    )
    VALUES (
        v_user,
        v_stake_fils,
        LEAST(
            100.00,
            GREATEST(
                1.00,
                pg_catalog.floor(
                    (0.99 / (1.0 - pg_catalog.random())) * 100
                ) / 100
            )
        )
    )
    RETURNING * INTO v_round;

    INSERT INTO public.wallet_ledger (
        user_id,
        amount,
        kind,
        reference_type,
        reference_id,
        note
    )
    VALUES (
        v_user,
        -(v_stake_fils / 1000.0),
        'crash_stake',
        'crash',
        v_round.id,
        'Crash game stake'
    );

    RETURN pg_catalog.jsonb_build_object(
        'round_id', v_round.id,
        'status', 'active',
        'stake', v_stake_fils / 1000.0,
        'multiplier', 1.0,
        'payout', 0
    );
END;
$function$;


-- 2. GET ACTIVE ROUND
CREATE OR REPLACE FUNCTION public.mero_crash_active()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_user uuid := auth.uid();
    v_round public.crash_rounds%ROWTYPE;
    v_elapsed numeric;
    v_multiplier numeric;
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT *
    INTO v_round
    FROM public.crash_rounds
    WHERE user_id = v_user
      AND status = 'active'
    ORDER BY started_at DESC
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    v_elapsed := GREATEST(
        0,
        EXTRACT(
            EPOCH FROM (
                pg_catalog.clock_timestamp() - v_round.started_at
            )
        ) * 1000
    );

    v_multiplier := pg_catalog.exp(
        (v_elapsed / 10000.0) * 0.6931471805599453
    );

    v_multiplier := LEAST(v_multiplier, 100.0);

    IF v_multiplier >= v_round.crash_point THEN
        UPDATE public.crash_rounds
        SET status = 'crashed',
            current_multiplier = v_round.crash_point,
            finished_at = pg_catalog.clock_timestamp()
        WHERE id = v_round.id;

        RETURN pg_catalog.jsonb_build_object(
            'round_id', v_round.id,
            'status', 'crashed',
            'stake', v_round.stake_fils / 1000.0,
            'multiplier', v_round.crash_point,
            'payout', 0
        );
    END IF;

    UPDATE public.crash_rounds
    SET current_multiplier = v_multiplier
    WHERE id = v_round.id;

    RETURN pg_catalog.jsonb_build_object(
        'round_id', v_round.id,
        'status', 'active',
        'stake', v_round.stake_fils / 1000.0,
        'multiplier', v_multiplier,
        'payout',
            pg_catalog.floor(
                v_round.stake_fils * v_multiplier
            ) / 1000.0
    );
END;
$function$;


-- 3. GET ROUND STATE
CREATE OR REPLACE FUNCTION public.mero_crash_state(
    p_round_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_user uuid := auth.uid();
    v_round public.crash_rounds%ROWTYPE;
    v_elapsed numeric;
    v_multiplier numeric;
    v_payout bigint;
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT *
    INTO v_round
    FROM public.crash_rounds
    WHERE id = p_round_id
      AND user_id = v_user
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Round not found';
    END IF;

    IF v_round.status = 'crashed' THEN
        RETURN pg_catalog.jsonb_build_object(
            'round_id', v_round.id,
            'status', 'crashed',
            'multiplier', v_round.current_multiplier,
            'payout', 0
        );
    END IF;

    IF v_round.status = 'cashed_out' THEN
        RETURN pg_catalog.jsonb_build_object(
            'round_id', v_round.id,
            'status', 'cashed_out',
            'multiplier', v_round.current_multiplier,
            'payout', v_round.payout_fils / 1000.0
        );
    END IF;

    v_elapsed := GREATEST(
        0,
        EXTRACT(
            EPOCH FROM (
                pg_catalog.clock_timestamp() - v_round.started_at
            )
        ) * 1000
    );

    v_multiplier := pg_catalog.exp(
        (v_elapsed / 10000.0) * 0.6931471805599453
    );

    v_multiplier := LEAST(v_multiplier, 100.0);

    IF v_multiplier >= v_round.crash_point THEN
        UPDATE public.crash_rounds
        SET status = 'crashed',
            current_multiplier = v_round.crash_point,
            finished_at = pg_catalog.clock_timestamp()
        WHERE id = v_round.id;

        RETURN pg_catalog.jsonb_build_object(
            'round_id', v_round.id,
            'status', 'crashed',
            'multiplier', v_round.crash_point,
            'payout', 0
        );
    END IF;

    v_payout := pg_catalog.floor(
        v_round.stake_fils * v_multiplier
    )::bigint;

    UPDATE public.crash_rounds
    SET current_multiplier = v_multiplier
    WHERE id = v_round.id;

    RETURN pg_catalog.jsonb_build_object(
        'round_id', v_round.id,
        'status', 'active',
        'multiplier', v_multiplier,
        'payout', v_payout / 1000.0
    );
END;
$function$;


-- 4. CASH OUT
CREATE OR REPLACE FUNCTION public.mero_crash_cashout(
    p_round_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_user uuid := auth.uid();
    v_locked uuid;
    v_round public.crash_rounds%ROWTYPE;
    v_elapsed numeric;
    v_multiplier numeric;
    v_payout bigint;
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT id
    INTO v_locked
    FROM public.profiles
    WHERE id = v_user
    FOR UPDATE;

    IF v_locked IS NULL THEN
        RAISE EXCEPTION 'User profile not found';
    END IF;

    SELECT *
    INTO v_round
    FROM public.crash_rounds
    WHERE id = p_round_id
      AND user_id = v_user
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Round not found';
    END IF;

    IF v_round.status = 'cashed_out' THEN
        RETURN pg_catalog.jsonb_build_object(
            'status', 'cashed_out',
            'multiplier', v_round.current_multiplier,
            'payout', v_round.payout_fils / 1000.0
        );
    END IF;

    IF v_round.status <> 'active' THEN
        RETURN pg_catalog.jsonb_build_object(
            'status', 'crashed',
            'multiplier', v_round.current_multiplier,
            'payout', 0
        );
    END IF;

    v_elapsed := GREATEST(
        0,
        EXTRACT(
            EPOCH FROM (
                pg_catalog.clock_timestamp() - v_round.started_at
            )
        ) * 1000
    );

    v_multiplier := pg_catalog.exp(
        (v_elapsed / 10000.0) * 0.6931471805599453
    );

    v_multiplier := LEAST(v_multiplier, 100.0);

    IF v_multiplier >= v_round.crash_point THEN
        UPDATE public.crash_rounds
        SET status = 'crashed',
            current_multiplier = v_round.crash_point,
            finished_at = pg_catalog.clock_timestamp()
        WHERE id = v_round.id;

        RETURN pg_catalog.jsonb_build_object(
            'status', 'crashed',
            'multiplier', v_round.crash_point,
            'payout', 0
        );
    END IF;

    v_payout := pg_catalog.floor(
        v_round.stake_fils * v_multiplier
    )::bigint;

    UPDATE public.crash_rounds
    SET status = 'cashed_out',
        current_multiplier = v_multiplier,
        payout_fils = v_payout,
        finished_at = pg_catalog.clock_timestamp()
    WHERE id = v_round.id;

    INSERT INTO public.wallet_ledger (
        user_id,
        amount,
        kind,
        reference_type,
        reference_id,
        note
    )
    VALUES (
        v_user,
        v_payout / 1000.0,
        'crash_payout',
        'crash',
        v_round.id,
        'Crash game cashout'
    );

    RETURN pg_catalog.jsonb_build_object(
        'status', 'cashed_out',
        'multiplier', v_multiplier,
        'payout', v_payout / 1000.0
    );
END;
$function$;


-- 5. FUNCTION PERMISSIONS
REVOKE ALL ON FUNCTION public.mero_crash_start(numeric)
FROM PUBLIC, anon;

REVOKE ALL ON FUNCTION public.mero_crash_active()
FROM PUBLIC, anon;

REVOKE ALL ON FUNCTION public.mero_crash_state(uuid)
FROM PUBLIC, anon;

REVOKE ALL ON FUNCTION public.mero_crash_cashout(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.mero_crash_start(numeric)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.mero_crash_active()
TO authenticated;

GRANT EXECUTE ON FUNCTION public.mero_crash_state(uuid)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.mero_crash_cashout(uuid)
TO authenticated;

COMMIT;
