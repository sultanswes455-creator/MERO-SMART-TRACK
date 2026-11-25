
-- MERO BET - OroPlay Seamless Wallet RPCs
-- JOD wallet integration
-- Preserves existing wallet and deposit/withdrawal functions.

BEGIN;

ALTER TABLE public.oroplay_wallet_transactions
ADD COLUMN IF NOT EXISTS is_refunded BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_oroplay_unrefunded_debits
ON public.oroplay_wallet_transactions (user_id, round_id, amount)
WHERE amount < 0
AND is_canceled = FALSE
AND is_refunded = FALSE;

CREATE OR REPLACE FUNCTION public.oroplay_wallet_balance(
    p_user_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_balance NUMERIC(18,3);
BEGIN
    BEGIN
        v_user_id := p_user_code::UUID;
    EXCEPTION WHEN invalid_text_representation THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 2
        );
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = v_user_id
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 2
        );
    END IF;

    SELECT COALESCE(SUM(amount), 0)
    INTO v_balance
    FROM public.wallet_ledger
    WHERE user_id = v_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', v_balance,
        'errorCode', 0
    );
END;
$$;


CREATE OR REPLACE FUNCTION public.oroplay_wallet_apply_transaction(
    p_tx JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_tx_code TEXT;
    v_round_id TEXT;
    v_amount NUMERIC;
    v_is_finished BOOLEAN;
    v_is_canceled BOOLEAN;
    v_balance NUMERIC(18,3);
    v_ledger_amount NUMERIC(18,3);
    v_round_uuid UUID;
    v_round_finished BOOLEAN;
    v_match_count INTEGER;
    v_debit_id UUID;
    v_debit_amount NUMERIC;
    v_kind TEXT;
BEGIN
    IF p_tx IS NULL OR jsonb_typeof(p_tx) <> 'object' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 400
        );
    END IF;

    BEGIN
        v_user_id := NULLIF(p_tx->>'userCode', '')::UUID;
        v_tx_code := NULLIF(trim(p_tx->>'transactionCode'), '');
        v_round_id := NULLIF(trim(p_tx->>'roundId'), '');
        v_amount := (p_tx->>'amount')::NUMERIC;
        v_is_finished := COALESCE(
            (p_tx->>'isFinished')::BOOLEAN, FALSE
        );
        v_is_canceled := COALESCE(
            (p_tx->>'isCanceled')::BOOLEAN, FALSE
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 400
        );
    END;

    IF v_user_id IS NULL
       OR v_tx_code IS NULL
       OR v_round_id IS NULL
       OR v_amount IS NULL
       OR (v_amount = 0 AND NOT v_is_canceled) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 400
        );
    END IF;

    PERFORM pg_advisory_xact_lock(
        hashtextextended(v_tx_code, 0)
    );

    PERFORM 1
    FROM public.profiles
    WHERE id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 2
        );
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.oroplay_wallet_transactions
        WHERE transaction_code = v_tx_code
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 6
        );
    END IF;

    SELECT id, is_finished
    INTO v_round_uuid, v_round_finished
    FROM public.oroplay_wallet_rounds
    WHERE user_id = v_user_id
      AND round_id = v_round_id
    FOR UPDATE;

    IF v_round_uuid IS NULL THEN
        INSERT INTO public.oroplay_wallet_rounds (
            user_id,
            round_id
        )
        VALUES (
            v_user_id,
            v_round_id
        )
        RETURNING id, is_finished
        INTO v_round_uuid, v_round_finished;

    ELSIF v_round_finished THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 0,
            'errorCode', 7
        );
    END IF;

    IF v_is_canceled THEN

        SELECT COUNT(*)::INTEGER
        INTO v_match_count
        FROM public.oroplay_wallet_transactions
        WHERE user_id = v_user_id
          AND round_id = v_round_id
          AND amount < 0
          AND is_canceled = FALSE
          AND is_refunded = FALSE
          AND (
              v_amount = 0
              OR ABS(amount) = ABS(v_amount)
          );

        IF v_match_count <> 1 THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'message', 0,
                'errorCode', 7
            );
        END IF;

        SELECT id, amount
        INTO v_debit_id, v_debit_amount
        FROM public.oroplay_wallet_transactions
        WHERE user_id = v_user_id
          AND round_id = v_round_id
          AND amount < 0
          AND is_canceled = FALSE
          AND is_refunded = FALSE
          AND (
              v_amount = 0
              OR ABS(amount) = ABS(v_amount)
          )
        ORDER BY created_at DESC
        LIMIT 1
        FOR UPDATE;

        UPDATE public.oroplay_wallet_transactions
        SET is_refunded = TRUE
        WHERE id = v_debit_id;

        v_ledger_amount := ABS(v_debit_amount);
        v_kind := 'oroplay_refund';

    ELSE
        v_ledger_amount := v_amount;

        IF v_amount < 0 THEN

            SELECT COALESCE(SUM(amount), 0)
            INTO v_balance
            FROM public.wallet_ledger
            WHERE user_id = v_user_id;

            IF v_balance < ABS(v_amount) THEN
                RETURN jsonb_build_object(
                    'success', FALSE,
                    'message', v_balance,
                    'errorCode', 4
                );
            END IF;

            v_kind := 'oroplay_bet';

        ELSE
            v_kind := 'oroplay_win';
        END IF;
    END IF;

    INSERT INTO public.oroplay_wallet_transactions (
        transaction_code,
        user_id,
        round_id,
        history_id,
        vendor_code,
        game_code,
        amount,
        is_finished,
        is_canceled,
        provider_payload
    )
    VALUES (
        v_tx_code,
        v_user_id,
        v_round_id,
        p_tx->>'historyId',
        p_tx->>'vendorCode',
        p_tx->>'gameCode',
        v_amount,
        v_is_finished,
        v_is_canceled,
        p_tx
    );

    INSERT INTO public.wallet_ledger (
        user_id,
        amount,
        kind,
        reference_type,
        reference_id,
        note
    )
    VALUES (
        v_user_id,
        v_ledger_amount,
        v_kind,
        'oroplay',
        v_round_uuid,
        CASE
            WHEN v_is_canceled
                THEN 'OroPlay canceled bet refund'
            WHEN v_amount < 0
                THEN 'OroPlay bet debit'
            ELSE 'OroPlay win credit'
        END
    );

    IF v_is_finished THEN
        UPDATE public.oroplay_wallet_rounds
        SET is_finished = TRUE,
            finished_at = NOW()
        WHERE id = v_round_uuid;
    END IF;

    SELECT COALESCE(SUM(amount), 0)
    INTO v_balance
    FROM public.wallet_ledger
    WHERE user_id = v_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', v_balance,
        'errorCode', 0
    );
END;
$$;


REVOKE ALL ON FUNCTION
public.oroplay_wallet_balance(TEXT)
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
public.oroplay_wallet_apply_transaction(JSONB)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
public.oroplay_wallet_balance(TEXT)
TO service_role;

GRANT EXECUTE ON FUNCTION
public.oroplay_wallet_apply_transaction(JSONB)
TO service_role;

COMMIT;
