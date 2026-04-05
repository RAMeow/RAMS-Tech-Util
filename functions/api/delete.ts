export const onRequestPost: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {
  const body = await request.json().catch(() => null);
  const key = body?.key;

  if (!key || typeof key !== "string") {
    return new Response(JSON.stringify({ error: "Missing file key" }), {
      status: 400,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  await env.RAMEOW_BUCKET.delete(key);

  return new Response(JSON.stringify({ ok: true, key }), {
    headers: {
      "Content-Type": "application/json",
    },
  });
};
