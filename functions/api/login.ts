export const onRequestPost: PagesFunction<{
  RAMEOW_PORTAL_PASSWORD: string;
  RAMEOW_SESSION_TOKEN: string;
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {
  try {
    const ip =
      request.headers.get("CF-Connecting-IP") ||
      request.headers.get("x-forwarded-for") ||
      "unknown";

    const userAgent = request.headers.get("user-agent") || "unknown";
    const now = new Date();

    const listed = await env.RAMEOW_BUCKET.list({
      prefix: "_system/login-attempts/",
    });

    const recentAttempts = await Promise.all(
      (listed.objects || []).map(async (object) => {
        try {
          const file = await env.RAMEOW_BUCKET.get(object.key);
          if (!file) return null;

          const text = await file.text();
          const parsed = JSON.parse(text);

          if (parsed.ip !== ip) return null;
          if (parsed.type !== "failed-login") return null;

          const timestamp = parsed.timestamp ? new Date(parsed.timestamp) : null;
          if (!timestamp || Number.isNaN(timestamp.getTime())) return null;

          return {
            key: object.key,
            timestamp,
          };
        } catch (error) {
          console.error("Failed reading login attempt file:", object.key, error);
          return null;
        }
      })
    );

    const failedAttemptsInWindow = recentAttempts.filter((attempt) => {
      if (!attempt) return false;
      const ageMs = now.getTime() - attempt.timestamp.getTime();
      return ageMs <= 3 * 60 * 1000;
    });

    if (failedAttemptsInWindow.length >= 5) {
      return new Response(
        JSON.stringify({
          error: "Too many failed login attempts. Please wait 1 minute(s) and try again.",
        }),
        {
          status: 429,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const body = await request.json().catch(() => null);
    const password = typeof body?.password === "string" ? body.password : "";

    if (!password) {
      return new Response(
        JSON.stringify({ error: "Missing password" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    if (password !== env.RAMEOW_PORTAL_PASSWORD) {
      const day = now.toISOString().split("T")[0];
      const timestamp = now.toISOString().replace(/[:.]/g, "-");
      const logKey = `_system/login-attempts/${day}/${timestamp}-${Math.random()
        .toString(36)
        .slice(2, 10)}.json`;

      const logBody = {
        type: "failed-login",
        ip,
        userAgent,
        path: new URL(request.url).pathname,
        timestamp: now.toISOString(),
      };

      try {
        await env.RAMEOW_BUCKET.put(logKey, JSON.stringify(logBody, null, 2), {
          httpMetadata: {
            contentType: "application/json",
          },
        });
      } catch (logError) {
        console.error("Failed login log write error:", logError);
      }

      return new Response(
        JSON.stringify({ error: "Invalid password" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: {
        "Content-Type": "application/json",
        "Set-Cookie": [
          `rameow_session=${encodeURIComponent(env.RAMEOW_SESSION_TOKEN)}`,
          "Path=/",
          "HttpOnly",
          "Secure",
          "SameSite=Strict",
          "Max-Age=86400",
        ].join("; "),
      },
    });
  } catch (error) {
    console.error("Login error:", error);

    return new Response(
      JSON.stringify({ error: "Login failed" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
};
