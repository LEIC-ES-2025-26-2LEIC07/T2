import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

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

  if (!tokenResponse.ok) {
    const errText = await tokenResponse.text();
    throw new Error(
      `FCM token request failed (${tokenResponse.status}): ${errText}`,
    );
  }

  const { access_token } = await tokenResponse.json();
  if (!access_token) throw new Error("FCM token response missing access_token");
  return access_token;
}

function getLisbonTimeParts(now: Date) {
  const dateParts = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Lisbon",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    })
      .formatToParts(now)
      .map(({ type, value }) => [type, value]),
  );

  const weekday = new Intl.DateTimeFormat("en-US", {
    timeZone: "Europe/Lisbon",
    weekday: "long",
  })
    .format(now)
    .toLowerCase();

  return {
    hour: parseInt(dateParts.hour ?? "0"),
    minute: parseInt(dateParts.minute ?? "0"),
    weekday,
    dateStr: `${dateParts.year}-${dateParts.month}-${dateParts.day}`,
  };
}

Deno.serve(async (_req) => {
  try {
    const now = new Date();
    const { hour, minute, weekday, dateStr } = getLisbonTimeParts(now);
    const reminderTime = `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00`;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: reminders, error: remErr } = await supabase
      .from("medication_reminders")
      .select("id, medication_id, reminder_time")
      .eq("is_active", true)
      .eq("reminder_time", reminderTime)
      .contains("days_of_week", [weekday]);

    if (remErr) throw remErr;
    if (!reminders || reminders.length === 0) {
      return new Response("no reminders", { status: 200 });
    }

    const medicationIds = reminders.map((r: { medication_id: string }) => r.medication_id);

    const { data: medications, error: medErr } = await supabase
      .from("medications")
      .select("id, name, dosage, dosage_unit, user_id")
      .in("id", medicationIds)
      .or(`end_date.is.null,end_date.gte.${dateStr}`);

    if (medErr) throw medErr;
    if (!medications || medications.length === 0) {
      return new Response("no active medications", { status: 200 });
    }

    const userIds = [...new Set(medications.map((m: { user_id: string }) => m.user_id))];

    const { data: tokenRows, error: tokErr } = await supabase
      .from("device_push_tokens")
      .select("user_id, token")
      .in("user_id", userIds);

    if (tokErr) throw tokErr;
    if (!tokenRows || tokenRows.length === 0) {
      return new Response("no device tokens", { status: 200 });
    }

    const medById = Object.fromEntries(
      medications.map((m: { id: string; name: string; dosage: number | null; dosage_unit: string | null; user_id: string }) => [m.id, m]),
    );
    const tokensByUser: Record<string, string[]> = {};
    for (const row of tokenRows as { user_id: string; token: string }[]) {
      (tokensByUser[row.user_id] ??= []).push(row.token);
    }

    const serviceAccount: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
    const accessToken = await getAccessToken(serviceAccount);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    const expiredTokens: string[] = [];

    await Promise.all(
      reminders.flatMap((reminder: { id: string; medication_id: string }) => {
        const med = medById[reminder.medication_id];
        if (!med) return [];

        const tokens = tokensByUser[med.user_id] ?? [];
        if (tokens.length === 0) return [];

        const dosageDisplay = med.dosage
          ? `${med.dosage}${med.dosage_unit ?? ""}`
          : "";
        const scheduledTimeIso = `${dateStr}T${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00.000`;
        const doseId = `${reminder.id}_${dateStr.replace(/-/g, "")}T${String(hour).padStart(2, "0")}${String(minute).padStart(2, "0")}`;
        const route =
          `/log-dose/${encodeURIComponent(doseId)}?status=scheduled` +
          `&medicationId=${encodeURIComponent(med.id)}` +
          `&medicationName=${encodeURIComponent(med.name)}` +
          `&dosage=${encodeURIComponent(dosageDisplay)}` +
          `&scheduledTime=${encodeURIComponent(scheduledTimeIso)}`;

        return tokens.map(async (token: string) => {
          const res = await fetch(fcmUrl, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: {
                  title: "Hora do Medicamento",
                  body: dosageDisplay
                    ? `Toma ${dosageDisplay} de ${med.name}`
                    : `Hora de tomar ${med.name}`,
                },
                data: {
                  type: "medication_reminder",
                  doseId,
                  route,
                  medicationId: med.id,
                  medicationName: med.name,
                  dosage: dosageDisplay,
                  scheduledTime: scheduledTimeIso,
                },
                android: {
                  priority: "high",
                  notification: { channel_id: "medication_reminders" },
                },
              },
            }),
          });

          if (!res.ok) {
            const err = await res.json();
            const status = err?.error?.status;
            if (
              status === "UNREGISTERED" || status === "INVALID_ARGUMENT"
            ) {
              expiredTokens.push(token);
            } else {
              console.error(`FCM error for token ${token}:`, err);
            }
          }
        });
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
