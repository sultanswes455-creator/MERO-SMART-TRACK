import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function response(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;

  let mismatch = 0;

  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return mismatch === 0;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return response(
      { success: false, message: 0, errorCode: 400 },
      405,
    );
  }

  const clientId = Deno.env.get("OROPLAY_CLIENT_ID") ?? "";
  const clientSecret = Deno.env.get("OROPLAY_CLIENT_SECRET") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!clientId || !clientSecret || !supabaseUrl || !serviceKey) {
    return response(
      { success: false, message: 0, errorCode: 500 },
      500,
    );
  }

  // Verify OroPlay Basic Authentication
  const expectedAuth =
    "Basic " + btoa(`${clientId}:${clientSecret}`);

  const receivedAuth = req.headers.get("authorization") ?? "";

  if (!safeEqual(receivedAuth, expectedAuth)) {
    return response(
      { success: false, message: 0, errorCode: 401 },
      401,
    );
  }

  const requestPath = new URL(req.url).pathname.replace(/\/$/, "");

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  let body: Record<string, unknown>;

  try {
    const parsed = await req.json();

    if (
      parsed === null ||
      typeof parsed !== "object" ||
      Array.isArray(parsed)
    ) {
      return response(
        { success: false, message: 0, errorCode: 400 },
        400,
      );
    }

    body = parsed as Record<string, unknown>;
  } catch {
    return response(
      { success: false, message: 0, errorCode: 400 },
      400,
    );
  }

  // =========================================
  // BALANCE CALLBACK
  // POST /api/balance
  // =========================================

  if (requestPath.endsWith("/api/balance")) {
    const userCode = String(body.userCode ?? "").trim();

    if (!userCode) {
      return response({
        success: false,
        message: 0,
        errorCode: 2,
      });
    }

    const { data, error } = await supabase.rpc(
      "oroplay_wallet_balance",
      {
        p_user_code: userCode,
      },
    );

    if (error || !data) {
      console.error("OroPlay balance RPC failed:", error?.message);

      return response(
        { success: false, message: 0, errorCode: 500 },
        500,
      );
    }

    return response(data);
  }

  // =========================================
  // TRANSACTION CALLBACK
  // POST /api/transaction
  // =========================================

  if (requestPath.endsWith("/api/transaction")) {
    const requiredFields = [
      "userCode",
      "transactionCode",
      "roundId",
      "amount",
    ];

    for (const field of requiredFields) {
      if (
        body[field] === undefined ||
        body[field] === null ||
        String(body[field]).trim() === ""
      ) {
        return response({
          success: false,
          message: 0,
          errorCode: 400,
        });
      }
    }

    const { data, error } = await supabase.rpc(
      "oroplay_wallet_apply_transaction",
      {
        p_tx: body,
      },
    );

    if (error || !data) {
      console.error("OroPlay transaction RPC failed:", error?.message);

      return response(
        { success: false, message: 0, errorCode: 500 },
        500,
      );
    }

    return response(data);
  }

  // =========================================
  // UNKNOWN CALLBACK
  // =========================================

  return response(
    { success: false, message: 0, errorCode: 400 },
    404,
  );
});
