export const onRequestGet: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ env }) => {
  try {
    const listed = await env.RAMEOW_BUCKET.list({
      prefix: "_system/login-attempts/",
    });

    const objects = [...(listed.objects || [])]
      .sort((a, b) => {
        const aTime = a.uploaded ? new Date(a.uploaded).getTime() : 0;
        const bTime = b.uploaded ? new Date(b.uploaded).getTime() : 0;
        return bTime - aTime;
      })
      .slice(0, 10);

    const attempts = await Promise.all(
      objects.map(async (object) => {
        try {
          const file = await env.RAMEOW_BUCKET.get(object.key);
          if (!file) return null;

          const text = await file.text();
          const parsed = JSON.parse(text);

          return {
            key: object.key,
            timestamp: parsed.timestamp || object.uploaded?.toISOString() || "",
            ip: parsed.ip || "unknown",
            userAgent: parsed.userAgent || "unknown",
            path: parsed.path || "",
          };
        } catch (error) {
          console.error("Failed reading login attempt file:", object.key, error);
          return null;
        }
      })
    );

    return new Response(
      JSON.stringify({
        attempts: attempts.filter(Boolean),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-store",
        },
      }
    );
  } catch (error) {
    console.error("Login attempts viewer error:", error);

    return new Response(
      JSON.stringify({
        attempts: [],
        error: "Failed to load login attempts",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-store",
        },
      }
    );
  }
};
