// Firebase REST + OAuth helpers (no firebase-admin/gRPC — Edge-runtime safe).

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cachedSa: ServiceAccount | null = null;

function sa(): ServiceAccount {
  if (cachedSa) return cachedSa;
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not set");
  cachedSa = JSON.parse(raw) as ServiceAccount;
  return cachedSa;
}

function b64url(input: string): string {
  return btoa(input)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function bytesB64url(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i += 20000) {
    bin += String.fromCharCode(...bytes.subarray(i, i + 20000));
  }
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let signingKey: CryptoKey | null = null;

async function getSigningKey(): Promise<CryptoKey> {
  if (signingKey) return signingKey;
  const pem = sa().private_key;
  const derBody = (pem as string)
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(derBody);
  const der = Uint8Array.from(bin, (c) => c.charCodeAt(0));
  signingKey = await crypto.subtle.importKey(
    "pkcs8",
    der.buffer as ArrayBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  return signingKey;
}

async function signJwt(claims: Record<string, unknown>): Promise<string> {
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = b64url(JSON.stringify(claims));
  const input = new TextEncoder().encode(`${header}.${body}`);
  const key = await getSigningKey();
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, input);
  return `${header}.${body}.${bytesB64url(new Uint8Array(sig))}`;
}

const tokenCache: Record<string, { token: string; exp: number }> = {};

async function oauthToken(scope: string): Promise<string> {
  const cached = tokenCache[scope];
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp > now + 60) return cached.token;
  const jwt = await signJwt({
    iss: sa().client_email,
    scope,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${
      encodeURIComponent(jwt)
    }`,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OAuth token failed ${res.status}: ${text.slice(0, 300)}`);
  }
  const data = await res.json();
  const token = data.access_token as string;
  const expiresIn = Number(data.expires_in ?? 3600);
  tokenCache[scope] = { token, exp: now + expiresIn };
  return token;
}

function firestoreBase(): string {
  return `https://firestore.googleapis.com/v1/projects/${sa().project_id}/databases/(default)/documents`;
}

async function firestoreRequest(
  method: string,
  urlPath: string,
  body?: unknown
): Promise<{ ok: boolean; status: number; data: unknown }> {
  const token = await oauthToken("https://www.googleapis.com/auth/datastore");
  const res = await fetch(urlPath.startsWith("http") ? urlPath : `${firestoreBase()}${urlPath}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data: unknown = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {
    data = text;
  }
  return { ok: res.ok, status: res.status, data };
}

export function fieldsToObject(fields: Record<string, unknown> | undefined): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (!fields) return out;
  for (const [key, val] of Object.entries(fields)) {
    const v = val as Record<string, unknown>;
    if ("stringValue" in v) out[key] = v.stringValue;
    else if ("integerValue" in v) out[key] = Number(v.integerValue);
    else if ("doubleValue" in v) out[key] = Number(v.doubleValue);
    else if ("booleanValue" in v) out[key] = v.booleanValue;
    else if ("timestampValue" in v) out[key] = v.timestampValue;
    else if ("nullValue" in v) out[key] = null;
    else if ("arrayValue" in v) {
      out[key] = ((v.arrayValue as Record<string, unknown>)?.values ?? []).map(
        (e) => fieldsToObject({ _: e })["_"]
      );
    } else if ("mapValue" in v) {
      out[key] = fieldsToObject((v.mapValue as Record<string, unknown>)?.fields as Record<string, unknown>);
    }
  }
  return out;
}

function toFieldValue(value: unknown): Record<string, unknown> {
  if (value === null || value === undefined) return { nullValue: "NULL_VALUE" };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map((e) => toFieldValue(e)) } };
  }
  if (typeof value === "object") {
    const fields: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      fields[k] = toFieldValue(v);
    }
    return { mapValue: { fields } };
  }
  return { nullValue: "NULL_VALUE" };
}

export function ts(date?: Date): string {
  return (date ?? new Date()).toISOString();
}

export async function getDoc(path: string): Promise<{ exists: boolean; data: Record<string, unknown> }> {
  const res = await firestoreRequest("GET", `/${path}`);
  if (res.status === 404) return { exists: false, data: {} };
  if (!res.ok) throw new Error(`getDoc ${path} failed ${res.status}`);
  const d = res.data as { fields?: Record<string, unknown> };
  return { exists: true, data: fieldsToObject(d.fields) };
}

/**
 * Writes a full document (create or replace) at documents/{path}.
 * `createIfMissing` first, merge-safe: this call replaces the whole doc
 * like Firestore set(), so it can create the doc too.
 */
export async function setDoc(path: string, obj: Record<string, unknown>): Promise<void> {
  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = toFieldValue(v);
  const name = `${firestoreBase()}/${path}`;
  const res = await firestoreRequest("PATCH", name, {
    fields,
    updateMask: { fieldPaths: Object.keys(fields) },
  });
  if (!res.ok) throw new Error(`setDoc ${path} failed ${res.status}: ${JSON.stringify(res.data).slice(0, 200)}`);
}

export async function createDoc(
  parentPath: string,
  obj: Record<string, unknown>,
  opts?: { documentId?: string }
): Promise<string | null> {
  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = toFieldValue(v);
  const query = opts?.documentId ? `?documentId=${opts.documentId}` : "";
  const res = await firestoreRequest("POST", `/${parentPath}${query}`, { fields });
  if (res.status === 409) return null;
  if (!res.ok) throw new Error(`createDoc ${parentPath} failed ${res.status}: ${JSON.stringify(res.data).slice(0, 200)}`);
  const d = res.data as { name?: string } | null;
  return d?.name ? d.name.split("/").pop() ?? null : null;
}

export async function commitWrites(
  writes: Array<Record<string, unknown>>
): Promise<void> {
  const res = await firestoreRequest("POST", ":commit", { writes });
  if (!res.ok) throw new Error(`commit failed ${res.status}: ${JSON.stringify(res.data).slice(0, 300)}`);
}

export function updateWrite(
  path: string,
  obj: Record<string, unknown>
): Record<string, unknown> {
  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = toFieldValue(v);
  return {
    update: {
      name: `${firestoreBase()}/${path}`,
      fields,
    },
    updateMask: { fieldPaths: Object.keys(fields) },
  };
}

export function incrementWrite(
  path: string,
  fieldPath: string,
  amount: number
): Record<string, unknown> {
  return {
    transform: {
      document: `${firestoreBase()}/${path}`,
      fieldTransforms: [
        {
          fieldPath,
          increment: { integerValue: String(Math.round(amount)) },
        },
      ],
    },
  };
}

export function incrementDoubleWrite(
  path: string,
  fieldPath: string,
  amount: number
): Record<string, unknown> {
  return {
    transform: {
      document: `${firestoreBase()}/${path}`,
      fieldTransforms: [{ fieldPath, increment: { doubleValue: amount } }],
    },
  };
}

export function walletCreditWrite(path: string, amount: number): Record<string, unknown> {
  return {
    transform: {
      document: `${firestoreBase()}/${path}`,
      fieldTransforms: [
        { fieldPath: "balance", increment: { integerValue: String(Math.round(amount)) } },
        { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
      ],
    },
  };
}

export async function runQuery(
  collectionId: string,
  whereEqual: { field: string; value: unknown }
): Promise<Array<{ id: string; data: Record<string, unknown> }>> {
  const res = await firestoreRequest("POST", ":runQuery", {
    structuredQuery: {
      from: [{ collectionId }],
      where: {
        fieldFilter: {
          field: { fieldPath: whereEqual.field },
          op: "EQUAL",
          value: toFieldValue(whereEqual.value),
        },
      },
    },
  });
  if (!res.ok) throw new Error(`runQuery ${collectionId} failed ${res.status}`);
  const rows = res.data as Array<{ document?: { name: string; fields?: Record<string, unknown> } }>;
  const out: Array<{ id: string; data: Record<string, unknown> }> = [];
  for (const row of rows) {
    if (!row.document) continue;
    const id = row.document.name.split("/").pop() ?? "";
    out.push({ id, data: fieldsToObject(row.document.fields) });
  }
  return out;
}

export async function sendFcm(message: {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<string> {
  const token = await oauthToken("https://www.googleapis.com/auth/firebase.messaging");
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa().project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: message.token,
          notification: { title: message.title, body: message.body },
          data: { ...(message.data ?? {}), click_action: "FLUTTER_NOTIFICATION_CLICK" },
          android: { priority: "high" },
        },
      }),
    }
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`FCM send failed ${res.status}: ${text.slice(0, 300)}`);
  }
  const data = await res.json();
  return (data.name as string) ?? "";
}