// SaltyGlass validator for Cloudflare Workers + KV.
// Bind a KV namespace named SALTY_KEYS.
//
// Example KV key: SALTY-ACCESS
// Example value:
// {
//   "enabled": true,
//   "expiresAt": "2026-12-31T23:59:59Z",
//   "bindingId": null,
//   "role": "beta",
//   "updateChannel": "beta",
//   "featureFlags": {
//     "newWorldTools": true,
//     "experimentalVisuals": false
//   }
// }

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return json({ valid: false, message: "POST required" }, 405);
    }

    if (!env.SALTY_KEYS) {
      return json(
        { valid: false, message: "SALTY_KEYS KV binding is not configured" },
        500
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ valid: false, message: "Invalid JSON" }, 400);
    }

    const key = String(body.key || "").trim();
    if (!key) {
      return json({ valid: false, message: "Missing key" }, 400);
    }

    const record = await env.SALTY_KEYS.get(key, { type: "json" });

    if (!record || record.enabled !== true) {
      return json({ valid: false, message: "Invalid key" }, 401);
    }

    const expiryMs = Date.parse(String(record.expiresAt || ""));

    if (!Number.isFinite(expiryMs) || Date.now() >= expiryMs) {
      return json(
        {
          valid: false,
          message: "Key expired",
          expiresAt: record.expiresAt || null,
        },
        401
      );
    }

    const binding = body.binding || {};
    const bindingId = String(
      binding.custom ||
      binding.installId ||
      binding.sessionId ||
      ""
    );

    if (!bindingId) {
      return json({ valid: false, message: "Missing client binding" }, 400);
    }

    if (record.bindingId && record.bindingId !== bindingId) {
      return json(
        {
          valid: false,
          message: "Key is bound to another client",
        },
        403
      );
    }

    const suppliedSession = String(body.sessionToken || "");

    if (
      record.sessionToken &&
      suppliedSession &&
      suppliedSession !== record.sessionToken
    ) {
      return json(
        {
          valid: false,
          message: "Session token mismatch",
        },
        403
      );
    }

    const sessionToken = suppliedSession || crypto.randomUUID();

    const nextRecord = {
      ...record,
      bindingId,
      sessionToken,
      lastUserId: binding.userId || null,
      lastPlaceId: binding.placeId || null,
      lastSeenAt: new Date().toISOString(),
    };

    const ttlSeconds = Math.max(
      60,
      Math.floor((expiryMs - Date.now()) / 1000)
    );

    await env.SALTY_KEYS.put(
      key,
      JSON.stringify(nextRecord),
      { expirationTtl: ttlSeconds }
    );

    return json({
      valid: true,
      message: "Access granted",
      expiresAt: record.expiresAt,
      sessionToken,
      role: record.role || "user",
      updateChannel: record.updateChannel || "stable",
      featureFlags: record.featureFlags || {},
    });
  },
};
