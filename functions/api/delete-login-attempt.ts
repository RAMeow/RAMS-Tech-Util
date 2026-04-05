export const onRequestPost: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {
  try {
    const body = await request.json().catch(() => null);

    const singleKey =
      typeof body?.key === "string" ? body.key.trim() : "";

    const multiKeys = Array.isArray(body?.keys)
      ? body.keys.filter((key: unknown): key is string => typeof key === "string")
      : [];

    const keys =
      multiKeys.length > 0
        ? multiKeys.map((key) => key.trim()).filter(Boolean)
        : singleKey
          ? [singleKey]
          : [];

    if (keys.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing key or keys" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const invalidKey = keys.find(
      (key) => !key.startsWith("_system/login-attempts/")
    );

    if (invalidKey) {
      return new Response(
        JSON.stringify({ error: "Invalid login attempt key" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    await Promise.all(keys.map((key) => env.RAMEOW_BUCKET.delete(key)));

    return new Response(
      JSON.stringify({
        ok: true,
        deleted: keys.length,
        keys,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Delete login attempt error:", error);

    return new Response(
      JSON.stringify({ error: "Failed to delete login attempt(s)" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
};
