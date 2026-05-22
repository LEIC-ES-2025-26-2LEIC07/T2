import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    user_id: string;
    title: string;
    message: string;
    severity: string;
  };
}

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const header = { alg: "RS256", typ: "JWT" };
  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(
      /\//g,
      "_",
    );

  const signingInput = `${encode(header)}.${encode(payload)}`;

  const pemContents = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${
    btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
  }`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const { access_token } = await tokenResponse.json();
  return access_token;
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();

    if (payload.type !== "INSERT" || payload.table !== "alerts") {
      return new Response("ignored", { status: 200 });
    }

    const { id: alertId, user_id, title, message } = payload.record;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: tokens } = await supabase
      .from("device_push_tokens")
      .select("token, platform")
      .eq("user_id", user_id);

    if (!tokens || tokens.length === 0) {
      return new Response("no tokens", { status: 200 });
    }

    const serviceAccount: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    const accessToken = await getAccessToken(serviceAccount);
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    const expiredTokens: string[] = [];

    await Promise.all(
      tokens.map(async ({ token }: { token: string }) => {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body: message },
              data: { alertId },
              android: { priority: "high" },
            },
          }),
        });

        if (!res.ok) {
          const err = await res.json();
          const status = err?.error?.status;
          if (status === "UNREGISTERED" || status === "INVALID_ARGUMENT") {
            expiredTokens.push(token);
          }
        }
      }),
    );

    if (expiredTokens.length > 0) {
      await supabase
        .from("device_push_tokens")
        .delete()
        .in("token", expiredTokens);
    }

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("error", { status: 500 });
  }
});
