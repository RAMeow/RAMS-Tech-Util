export const onRequestPost: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {

  const formData = await request.formData();
  const file = formData.get("file");

  if (!(file instanceof File)) {
    return new Response(JSON.stringify({ error: "No file uploaded" }), {
      status: 400,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  // Clean filename
  const safeName = file.name.replace(/[^\w.\- ]+/g, "_");

  // Get uploader IP from Cloudflare
  const ip =
    request.headers.get("CF-Connecting-IP") ||
    request.headers.get("x-forwarded-for") ||
    "unknown";

  // Convert IP to filename-safe format
  const cleanIP = ip.replace(/[.:]/g, "-");

  // Current date (YYYY-MM-DD)
  const date = new Date().toISOString().split("T")[0];

  // Final R2 storage key
  const key = `${cleanIP}_${date}_${safeName}`;

  // Upload to R2
  await env.RAMEOW_BUCKET.put(key, file.stream(), {
    httpMetadata: {
      contentType: file.type || "application/octet-stream",
    },
  });

  return new Response(JSON.stringify({
    ok: true,
    key: key
  }), {
    headers: {
      "Content-Type": "application/json",
    },
  });
};
