
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BASE_URL = (
  Deno.env.get("OROPLAY_BASE_URL") ??
  "https://bs.sxvwlkohlv.com/api/v2"
).replace(/\/+$/, "");

const CLIENT_ID = Deno.env.get("OROPLAY_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("OROPLAY_CLIENT_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

let cachedToken = "";
let tokenExpiresAt = 0;

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function failure(message: string, errorCode = 500, status = 200) {
  return json({
    success: false,
    message,
    errorCode,
  }, status);
}

async function getOroPlayToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  if (cachedToken && tokenExpiresAt > now + 60) {
    return cachedToken;
  }

  const response = await fetch(
    `${BASE_URL}/auth/createtoken`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
      }),
      signal: AbortSignal.timeout(20000),
    },
  );

  const data = await response.json();

  if (!response.ok || !data.token) {
    console.error(
      "OroPlay token request failed:",
      response.status,
      data.errorCode ?? "unknown",
    );

    throw new Error("تعذر الحصول على رمز OroPlay");
  }

  cachedToken = String(data.token);

  const expiration = Number(data.expiration ?? 0);

  tokenExpiresAt = expiration > now
    ? expiration
    : now + 300;

  return cachedToken;
}

async function callOroPlay(
  path: string,
  method: "GET" | "POST",
  body?: Record<string, unknown>,
): Promise<any> {
  const token = await getOroPlayToken();

  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(30000),
  });

  const text = await response.text();

  let data: any;

  try {
    data = JSON.parse(text);
  } catch {
    throw new Error("استجابة OroPlay ليست JSON");
  }

  if (!response.ok || data.success === false) {
    console.error(
      "OroPlay API error:",
      path,
      response.status,
      data.errorCode ?? "unknown",
    );

    throw new Error(
      `فشل طلب OroPlay (${data.errorCode ?? response.status})`,
    );
  }

  return data;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return failure("Method not allowed", 400, 405);
  }

  if (
    !CLIENT_ID ||
    !CLIENT_SECRET ||
    !SUPABASE_URL ||
    !SERVICE_KEY
  ) {
    return failure("Server configuration is incomplete");
  }

  const authorization = req.headers.get("Authorization") ?? "";

  if (!authorization.startsWith("Bearer ")) {
    return failure("Authentication required", 401, 401);
  }

  const accessToken = authorization.substring(7).trim();

  if (!accessToken) {
    return failure("Authentication required", 401, 401);
  }

  const supabase = createClient(
    SUPABASE_URL,
    SERVICE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  );

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(accessToken);

  if (authError || !user) {
    return failure("Invalid user session", 401, 401);
  }

  let body: Record<string, unknown>;

  try {
    const parsed = await req.json();

    if (
      !parsed ||
      typeof parsed !== "object" ||
      Array.isArray(parsed)
    ) {
      return failure("Invalid request body", 400);
    }

    body = parsed as Record<string, unknown>;
  } catch {
    return failure("Invalid JSON body", 400);
  }

  const action = String(body.action ?? "").trim();

  try {
    // قائمة شركات الألعاب
    if (action === "vendors") {
      const result = await callOroPlay(
        "/vendors/list",
        "GET",
      );

      return json(result);
    }

    // قائمة الألعاب الخاصة بالشركة
    if (action === "games") {
      const vendorCode = String(
        body.vendorCode ?? "",
      ).trim();

      const language = String(
        body.language ?? "en",
      ).trim();

      if (!vendorCode) {
        return failure("vendorCode is required", 400);
      }

      const result = await callOroPlay(
        "/games/list",
        "POST",
        {
          vendorCode,
          language,
        },
      );

      return json(result);
    }

    // تفاصيل اللعبة
    if (action === "detail") {
      const vendorCode = String(
        body.vendorCode ?? "",
      ).trim();

      const gameCode = String(
        body.gameCode ?? "",
      ).trim();

      if (!vendorCode || !gameCode) {
        return failure(
          "vendorCode and gameCode are required",
          400,
        );
      }

      const result = await callOroPlay(
        "/game/detail",
        "POST",
        {
          vendorCode,
          gameCode,
        },
      );

      return json(result);
    }

    // تشغيل اللعبة بحساب اللاعب الحقيقي
    if (action === "launch") {
      const vendorCode = String(
        body.vendorCode ?? "",
      ).trim();

      const gameCode = String(
        body.gameCode ?? "",
      ).trim();

      const language = String(
        body.language ?? "en",
      ).trim();

      if (!vendorCode || !gameCode) {
        return failure(
          "vendorCode and gameCode are required",
          400,
        );
      }

      const launchBody: Record<string, unknown> = {
        vendorCode,
        gameCode,
        userCode: user.id,
        language,
      };

      if (body.lobbyUrl) {
        launchBody.lobbyUrl = String(body.lobbyUrl);
      }

      if (body.theme !== undefined) {
        const theme = Number(body.theme);

        if (!Number.isInteger(theme)) {
          return failure("Invalid theme", 400);
        }

        launchBody.theme = theme;
      }

      const result = await callOroPlay(
        "/game/launch-url",
        "POST",
        launchBody,
      );

      return json(result);
    }

    return failure("Unknown action", 400);
  } catch (error) {
    console.error(
      "oroplay-games error:",
      error instanceof Error ? error.message : "unknown",
    );

    return failure(
      error instanceof Error
        ? error.message
        : "OroPlay request failed",
    );
  }
});
