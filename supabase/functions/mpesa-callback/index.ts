import {
  commitWrites,
  createDoc,
  getDoc,
  runQuery,
  setDoc,
  ts,
  updateWrite,
  walletCreditWrite,
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

function mpesaEnv(): "production" | "sandbox" {
  return (Deno.env.get("MPESA_ENV") ?? "sandbox") === "production"
    ? "production"
    : "sandbox";
}

function baseUrl(): string {
  return mpesaEnv() === "production"
    ? "https://api.safaricom.co.ke"
    : "https://sandbox.safaricom.co.ke";
}

async function safaricomToken(): Promise<string> {
  const key = Deno.env.get("MPESA_CONSUMER_KEY") ?? "";
  const secret = Deno.env.get("MPESA_CONSUMER_SECRET") ?? "";
  const creds = btoa(`${key}:${secret}`);
  const res = await fetch(
    `${baseUrl()}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${creds}` } }
  );
  if (!res.ok) throw new Error(`Safaricom auth failed ${res.status}`);
  const data = await res.json();
  return data.access_token as string;
}

function currentTimestamp(): string {
  const now = new Date();
  return [
    now.getFullYear(),
    String(now.getMonth() + 1).padStart(2, "0"),
    String(now.getDate()).padStart(2, "0"),
    String(now.getHours()).padStart(2, "0"),
    String(now.getMinutes()).padStart(2, "0"),
    String(now.getSeconds()).padStart(2, "0"),
  ].join("");
}

async function stkQuery(checkoutId: string): Promise<{
  resultCode: number;
  receipt?: string;
  amount?: number;
  phone?: string;
}> {
  const shortcode = Deno.env.get("MPESA_SHORTCODE") ?? "174379";
  const passkey = Deno.env.get("MPESA_PASSKEY") ?? "sandbox";
  const timestamp = currentTimestamp();
  const password = btoa(`${shortcode}${passkey}${timestamp}`);
  const token = await safaricomToken();
  const res = await fetch(`${baseUrl()}/mpesa/stkpushquery/v1/query`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      CheckoutRequestID: checkoutId,
    }),
  });
  if (!res.ok) throw new Error(`STK query failed ${res.status}`);
  const data = await res.json();
  const items = (data.CallbackMetadata?.Item ?? []) as Array<{ Name: string; Value?: unknown }>;
  const pickup = (name: string) => items.find((i) => i.Name === name)?.Value;
  return {
    resultCode: Number(data.ResultCode ?? 1),
    receipt: pickup("MpesaReceiptNumber") as string | undefined,
    amount: Number(pickup("Amount") ?? NaN),
    phone: pickup("PhoneNumber") as string | undefined,
  };
}

interface CallbackMeta {
  checkoutId: string;
  resultCode: number;
  resultDesc: string;
  receipt?: string;
  amount?: number;
  phone?: string;
}

function parseCallback(body: Record<string, unknown>): CallbackMeta | null {
  const stk = (body?.Body as Record<string, unknown> | undefined)?.stkCallback as
    | Record<string, unknown>
    | undefined;
  if (!stk) return null;
  const meta = (stk.CallbackMetadata as Record<string, unknown> | undefined)?.Item as
    | Array<Record<string, unknown>>
    | undefined;
  const pickup = (name: string) => meta?.find((i) => i.Name === name)?.Value;
  return {
    checkoutId: (stk.CheckoutRequestID as string) ?? "",
    resultCode: Number(stk.ResultCode ?? 1),
    resultDesc: (stk.ResultDesc as string) ?? "",
    receipt: pickup("MpesaReceiptNumber") as string | undefined,
    amount: Number(pickup("Amount") ?? NaN),
    phone: pickup("PhoneNumber") as string | undefined,
  };
}

async function settle(checkoutId: string, cb: CallbackMeta): Promise<{ status: string; receipt?: string }> {
  const now = ts();
  const reqSnap = await getDoc(`mpesa_requests/${checkoutId}`);
  if (!reqSnap.exists) throw new Error(`Unknown checkout request: ${checkoutId}`);
  const req = reqSnap.data;
  if (req.status === "completed") {
    return { status: "completed", receipt: req.receipt as string | undefined };
  }

  const expected = Number(req.amount ?? 0);
  const received = cb.amount ?? 0;
  if (expected > 0 && received > 0 && Math.abs(received - expected) > 0.01) {
    await setDoc(`mpesa_requests/${checkoutId}`, {
      ...req,
      status: "mismatch",
      resultDesc: `Amount mismatch expected ${expected} got ${received}`,
      updatedAt: now,
    });
    return { status: "mismatch" };
  }

  const receipt = (cb.receipt ?? `MPS${Date.now()}`).trim();
  const intent = (req.intent ?? "rent") as string;
  const propertyId = (req.propertyId ?? "") as string;
  const unitId = (req.unitId ?? "") as string;
  const tenantUid = (req.tenantUid ?? "") as string;
  const amount = received > 0 ? received : Number(req.amount ?? 0);

  if (intent === "topup" || intent === "wallet_deposit") {
    await ensureWalletDoc(`wallets/${tenantUid}`);
    await commitWrites([
      updateWrite(`mpesa_requests/${checkoutId}`, {
        checkoutRequestId: checkoutId,
        tenantUid,
        propertyId,
        unitId,
        amount,
        intent,
        status: "completed",
        receipt,
        resultCode: 0,
        amountPaid: amount,
        source: "wallet-topup",
        createdAt: req.createdAt ?? now,
        paidAt: now,
        updatedAt: now,
      }),
      walletCreditWrite(`wallets/${tenantUid}`, amount),
    ]);
    await createDoc("wallet_transactions", {
      userId: tenantUid,
      amount,
      type: "credit",
      source: "topup",
      referenceId: receipt,
      description: "Wallet top-up via M-Pesa",
      createdAt: now,
    }).catch(() => {});
    await createDoc("audit_logs", {
      actorId: "system:mpesa-callback",
      action: "wallet_topup",
      targetType: "wallet",
      targetId: tenantUid,
      metadata: { checkoutId, amount, receipt, phone: cb.phone ?? "" },
      createdAt: now,
    }).catch(() => {});
    return { status: "completed", receipt };
  }

  await createDoc("payments", {
    paymentId: receipt,
    tenantId: tenantUid,
    propertyId,
    unitId,
    amount,
    type: intent === "premium"
      ? "subscription"
      : intent === "wallet_deposit"
      ? "deposit"
      : "rent",
    method: "mpesa",
    reference: receipt,
    status: "completed",
    paidAt: now,
    notes: `Settled server-side via mpesa-callback (${checkoutId})`,
  }, { documentId: receipt }).catch(() => {});

  const writes: Array<Record<string, unknown>> = [];
  writes.push(updateWrite(`mpesa_requests/${checkoutId}`, {
    checkoutRequestId: checkoutId,
    tenantUid,
    propertyId,
    unitId,
    amount,
    intent,
    status: "completed",
    receipt,
    resultCode: 0,
    amountPaid: amount,
    createdAt: req.createdAt ?? now,
    paidAt: now,
    updatedAt: now,
  }));

  if (intent === "wallet_deposit") {
    const walletPath = `wallets/${tenantUid}`;
    const walletSnap = await getDoc(walletPath);
    if (!walletSnap.exists) {
      await setDoc(walletPath, {
        userId: tenantUid,
        balance: 0,
        totalCredited: 0,
        totalDebited: 0,
      });
    }
    writes.push(walletCreditWrite(walletPath, amount));
    await createDoc("wallet_transactions", {
      userId: tenantUid,
      amount,
      type: "credit",
      source: "deposit",
      referenceId: receipt,
      description: "Wallet deposit settled by server",
      createdAt: now,
    }).catch(() => {});
  } else if (unitId) {
    const invoicesSnap = await getInvoicesForUnit(unitId);
    let remaining = amount;
    const unpaid = invoicesSnap
      .filter((i) => Number(i.data.amountPaid ?? 0) < Number(i.data.amount ?? 0))
      .sort((a, b) => new Date(a.data.periodStart as string).getTime() - new Date(b.data.periodStart as string).getTime());
    for (const inv of unpaid) {
      if (remaining <= 0) break;
      const due = Number(inv.data.amount ?? 0);
      const paidSoFar = Number(inv.data.amountPaid ?? 0);
      const take = Math.min(Math.max(0, due - paidSoFar), remaining);
      if (take <= 0) continue;
      const newPaid = paidSoFar + take;
      const fullyPaid = newPaid >= due;
      const patch: Record<string, unknown> = {
        invoiceId: inv.id,
        tenantId: inv.data.tenantId ?? "",
        propertyId: inv.data.propertyId ?? "",
        unitId,
        periodStart: inv.data.periodStart ?? now,
        periodKey: inv.data.periodKey ?? "",
        amount: due,
        amountPaid: newPaid,
        status: fullyPaid ? "paid" : "unpaid",
      };
      if (fullyPaid) patch.paidAt = now;
      writes.push(updateWrite(`rent_invoices/${inv.id}`, patch));
      remaining -= take;
    }
  }

  if (propertyId) {
    const propSnap = await getDoc(`properties/${propertyId}`);
    const ownerId = propSnap.data?.ownerId as string | undefined;
    if (ownerId) {
      await ensureWalletDoc(`wallets/${ownerId}`);
      writes.push(walletCreditWrite(`wallets/${ownerId}`, amount));
      await createDoc("wallet_transactions", {
        userId: ownerId,
        amount,
        type: "credit",
        source: intent === "premium" ? "subscription" : "rent",
        referenceId: receipt,
        description: `${intent === "premium" ? "Subscription" : "Rent"} payment settled by server`,
        createdAt: now,
      }).catch(() => {});
    }
  }

  await commitWrites(writes);

  await createDoc("audit_logs", {
    actorId: "system:mpesa-callback",
    action: intent === "wallet_deposit"
      ? "wallet_deposit"
      : intent === "premium"
      ? "subscription_paid"
      : "rent_paid",
    targetType: "payment",
    targetId: receipt,
    metadata: {
      checkoutId,
      amount,
      phone: cb.phone ?? "",
      tenantUid,
    },
    createdAt: now,
  }).catch(() => {});

  return { status: "completed", receipt };
}

async function getInvoicesForUnit(unitId: string): Promise<
  Array<{ id: string; data: Record<string, unknown> }>
> {
  return runQuery("rent_invoices", { field: "unitId", value: unitId });
}

async function ensureWalletDoc(path: string): Promise<void> {
  const snap = await getDoc(path);
  if (snap.exists) return;
  const uid = path.split("/").pop() ?? "";
  const now = ts();
  await setDoc(path, {
    userId: uid,
    balance: 0,
    totalCredited: 0,
    totalDebited: 0,
    currency: "KES",
    createdAt: now,
    updatedAt: now,
  });
}

function b64urlBytes(input: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < input.length; i += 20000) {
    bin += String.fromCharCode(...input.subarray(i, i + 20000));
  }
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function securityCredential(password: string, certPem: string): Promise<string> {
  const body = certPem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "spki",
    der.buffer as ArrayBuffer,
    { name: "RSA-OAEP", hash: "SHA-256" },
    false,
    ["encrypt"]
  );
  const enc = await crypto.subtle.encrypt(
    { name: "RSA-OAEP" },
    key,
    new TextEncoder().encode(password)
  );
  return b64urlBytes(new Uint8Array(enc));
}

async function b2cRequest(amount: number, phone: string, remarks: string): Promise<{
  responseCode: string;
  description: string;
  originatorConversationId?: string;
}> {
  const initiator = Deno.env.get("MPESA_B2C_INITIATOR") ?? "";
  const password = Deno.env.get("MPESA_B2C_PASSWORD") ?? "";
  const cert = Deno.env.get("MPESA_B2C_CERT") ?? "";
  if (!initiator || !password || !cert) {
    throw new Error("MPESA_B2C configuration missing on server");
  }
  const token = await safaricomToken();
  const res = await fetch(`${baseUrl()}/mpesa/b2c/v1/paymentrequest`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      InitiatorName: initiator,
      SecurityCredential: await securityCredential(password, cert),
      CommandID: "BusinessPayment",
      Amount: Math.round(amount),
      PartyA: Deno.env.get("MPESA_SHORTCODE") ?? "174379",
      PartyB: phone,
      Remarks: remarks.slice(0, 100),
      QueueTimeOutURL: Deno.env.get("MPESA_B2C_QUEUE_URL") ?? "https://example.com/callback",
      ResultURL: Deno.env.get("MPESA_B2C_RESULT_URL") ?? "https://example.com/callback",
      Occasion: "",
    }),
  });
  const data = await res.json();
  return {
    responseCode: String(data.ResponseCode ?? "1"),
    description: String(data.ResponseDescription ?? "B2C request failed"),
    originatorConversationId: data.OriginatorConversationID as string | undefined,
  };
}

async function handleB2C(body: Record<string, unknown>) {
  const txnId = (body.txnId ?? "") as string;
  if (!txnId) return json({ ok: false, reason: "txnId required" }, 400);
  const txnSnap = await getDoc(`wallet_transactions/${txnId}`).catch(() => null);
  if (!txnSnap?.exists) {
    return json({ ok: false, reason: "wallet_transaction not found" }, 404);
  }
  const txn = txnSnap.data;
  if (txn.status !== "pending") {
    return json({ ok: false, reason: `status is ${txn.status} not pending` });
  }
  const phone = String((txn.phone ?? txn.mpesaPhone ?? "")).trim();
  if (!phone) return json({ ok: false, reason: "no M-Pesa phone stored on the request" });

  const wSnap = await getDoc(`wallets/${txn.userId}`);
  const balance = Number(wSnap.data?.balance ?? 0);
  const amount = Number(txn.amount ?? 0);
  if (balance < amount) {
    return json({ ok: false, reason: "insufficient wallet balance" });
  }

  await setDoc(`wallet_transactions/${txnId}`, {
    ...txn,
    status: "processing",
    updatedAt: ts(),
  }).catch(() => {});

  try {
    const r = await b2cRequest(amount, phone, `Wallet withdrawal ${txnId.slice(0, 8)}`);
    if (r.responseCode !== "0") {
      await setDoc(`wallet_transactions/${txnId}`, {
        ...txn,
        status: "failed",
        failureReason: r.description,
        updatedAt: ts(),
      }).catch(() => {});
      return json({ ok: false, reason: `B2C rejected: ${r.description}` });
    }
    await commitWrites([
      walletCreditWrite(`wallets/${txn.userId}`, -amount),
      updateWrite(`wallet_transactions/${txnId}`, {
        id: txnId,
        userId: txn.userId,
        type: txn.type ?? "debit",
        source: txn.source ?? "withdrawal",
        amount,
        balanceAfter: Math.max(0, balance - amount),
        status: "completed",
        referenceId: txn.referenceId,
        description: txn.description ?? "Wallet withdrawal to M-Pesa",
        phone,
        createdAt: txn.createdAt ?? ts(),
        originatorConversationId: r.originatorConversationId,
        failureReason: null,
        processedAt: ts(),
        updatedAt: ts(),
      }),
    ]);
    await createDoc("audit_logs", {
      actorId: "system:mpesa-callback",
      action: "withdrawal_paid_out",
      targetType: "wallet_transaction",
      targetId: txnId,
      metadata: {
        userId: txn.userId,
        amount,
        phone,
        originatorConversationId: r.originatorConversationId,
      },
      createdAt: ts(),
    }).catch(() => {});
    return json({ ok: true, status: "completed", originatorConversationId: r.originatorConversationId });
  } catch (e) {
    await setDoc(`wallet_transactions/${txnId}`, {
      ...txn,
      status: "failed",
      failureReason: String(e),
      updatedAt: ts(),
    }).catch(() => {});
    return json({ ok: false, reason: String(e) });
  }
}

async function handleCallback(body: Record<string, unknown>) {
  const cb = parseCallback(body);
  if (!cb) return json({ ResultCode: 1, ResultDesc: "Invalid callback body" }, 400);
  if (cb.resultCode !== 0) {
    const reqSnap = await getDoc(`mpesa_requests/${cb.checkoutId}`).catch(() => null);
    if (reqSnap?.exists) {
      await setDoc(`mpesa_requests/${cb.checkoutId}`, {
        ...reqSnap.data,
        status: "failed",
        resultCode: cb.resultCode,
        resultDesc: cb.resultDesc,
        updatedAt: ts(),
      }).catch(() => {});
    }
    return json({ ResultCode: 0, ResultDesc: "Success" });
  }
  try {
    await settle(cb.checkoutId, cb);
  } catch (e) {
    return json({ ResultCode: 1, ResultDesc: `Settlement failed: ${e}` });
  }
  return json({ ResultCode: 0, ResultDesc: "Success" });
}

async function handleVerify(body: Record<string, unknown>) {
  const checkoutId = (body.checkoutId ?? body.checkoutRequestId ?? "") as string;
  if (!checkoutId) return json({ ok: false, reason: "checkoutId required" }, 400);
  try {
    const q = await stkQuery(checkoutId);
    if (q.resultCode !== 0) {
      return json({ ok: false, status: "not_paid", reason: `STK ResultCode ${q.resultCode}` });
    }
    const outcome = await settle(checkoutId, {
      checkoutId,
      resultCode: 0,
      resultDesc: "verified via STK query",
      receipt: q.receipt,
      amount: q.amount,
      phone: q.phone,
    });
    return json({ ok: true, ...outcome });
  } catch (e) {
    return json({ ok: false, reason: String(e) }, 500);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const body = await req.json() as Record<string, unknown>;
    if (body?.action === "b2c") return await handleB2C(body);
    const stk = (body?.Body as Record<string, unknown> | undefined)?.stkCallback;
    if (stk) return await handleCallback(body);
    return await handleVerify(body);
  } catch (e) {
    return json({ ok: false, reason: String(e) }, 400);
  }
});