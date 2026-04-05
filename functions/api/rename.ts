export const onRequestPost: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {
  try {
    const body = await request.json().catch(() => null);

    const oldKey = typeof body?.oldKey === "string" ? body.oldKey.trim() : "";
    const newKey = typeof body?.newKey === "string" ? body.newKey.trim() : "";

    if (!oldKey || !newKey) {
      return new Response(
        JSON.stringify({ error: "Missing oldKey or newKey" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    if (oldKey === newKey) {
      return new Response(
        JSON.stringify({ ok: true, oldKey, newKey, unchanged: true }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // basic filename safety checks
    if (
      newKey.includes("..") ||
      newKey.includes("\\") ||
      newKey.startsWith("/") ||
      newKey.endsWith("/")
    ) {
      return new Response(
        JSON.stringify({ error: "Invalid new filename" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const sourceObject = await env.RAMEOW_BUCKET.get(oldKey);

    if (!sourceObject) {
      return new Response(
        JSON.stringify({ error: "Original file not found" }),
        {
          status: 404,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const existingTarget = await env.RAMEOW_BUCKET.get(newKey);

    if (existingTarget) {
      return new Response(
        JSON.stringify({ error: "A file with that name already exists" }),
        {
          status: 409,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    await env.RAMEOW_BUCKET.put(newKey, sourceObject.body, {
      httpMetadata: sourceObject.httpMetadata,
      customMetadata: sourceObject.customMetadata,
    });

    await env.RAMEOW_BUCKET.delete(oldKey);

    return new Response(
      JSON.stringify({ ok: true, oldKey, newKey }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Rename error:", error);

    return new Response(
      JSON.stringify({ error: "Rename failed" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
};
