-- MERO BET - OroPlay Wallet Tables
-- إنشاء جداول لتسجيل معاملات OroPlay فقط.
-- لا يتم تعديل أرصدة اللاعبين أو إجراءات المحفظة الحالية.

BEGIN;

-- جدول جولات ألعاب OroPlay
CREATE TABLE IF NOT EXISTS public.oroplay_wallet_rounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id),

    round_id TEXT NOT NULL,

    is_finished BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    finished_at TIMESTAMPTZ,

    CONSTRAINT oroplay_round_user_unique
        UNIQUE (user_id, round_id)
);

-- جدول معاملات OroPlay
CREATE TABLE IF NOT EXISTS public.oroplay_wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    transaction_code TEXT NOT NULL UNIQUE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id),

    round_id TEXT NOT NULL,

    history_id TEXT,

    vendor_code TEXT,

    game_code TEXT,

    amount NUMERIC,

    is_finished BOOLEAN NOT NULL DEFAULT FALSE,

    is_canceled BOOLEAN NOT NULL DEFAULT FALSE,

    provider_payload JSONB NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- فهارس لتسريع البحث
CREATE INDEX IF NOT EXISTS
    idx_oroplay_rounds_user
ON public.oroplay_wallet_rounds(user_id);

CREATE INDEX IF NOT EXISTS
    idx_oroplay_transactions_user
ON public.oroplay_wallet_transactions(user_id);

CREATE INDEX IF NOT EXISTS
    idx_oroplay_transactions_round
ON public.oroplay_wallet_transactions(user_id, round_id);

CREATE INDEX IF NOT EXISTS
    idx_oroplay_transactions_created
ON public.oroplay_wallet_transactions(created_at DESC);

-- حماية الجداول من الوصول المباشر
ALTER TABLE public.oroplay_wallet_rounds
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.oroplay_wallet_transactions
ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.oroplay_wallet_rounds
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON TABLE public.oroplay_wallet_transactions
FROM PUBLIC, anon, authenticated;

COMMIT;
