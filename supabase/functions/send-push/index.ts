import {
  createDoc,
  getDoc,
  sendFcm,
  ts,
} from "../_shared/firebase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function resolveToken(
  recipientUid: string | undefined,
  token: string | undefined
): Promise<string | null> {
  if (token) return token;
  if (!recipientUid) return null;
  const snap = await getDoc(`users/${recipientUid}`);
  const t = snap.data?.fcmToken;
  return typeof t === "string" && t.length > 0 ? t : null;
}

async function saveInbox(
  recipientUid: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  if (!recipientUid) return;
  await createDoc("notifications", {
    recipientId: recipientUid,
    title,
    body,
    type: data.type ?? "system",
    data,
    read: false,
    createdAt: ts(),
  }).catch(() => {});
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const body = await req.json() as {
      recipientUid?: string;
      token?: string;
      title?: string;
      body?: string;
      data?: Record<string, string>;
    };
    const title = body.title ?? "REM S notification";
    const message = body.body ?? "";
    const data = body.data ?? {};

    const deviceToken = await resolveToken(body.recipientUid, body.token);
    if (!deviceToken) {
      await saveInbox(body.recipientUid ?? "", title, message, data);
      return json({ ok: true, delivered: "inbox_only", reason: "no device token" });
    }

    const messageId = await sendFcm({
      token: deviceToken,
      title,
      body: message,
      data,
    });

    await saveInbox(body.recipientUid ?? "", title, message, data);
    return json({ ok: true, delivered: "push", messageId });
  } catch (e) {
    return json({ ok: false, reason: String(e) }, 500);
  }
});