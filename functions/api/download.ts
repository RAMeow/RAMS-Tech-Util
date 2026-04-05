export const onRequestGet: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ request, env }) => {
  try {
    const url = new URL(request.url);
    const key = url.searchParams.get("key");

    if (!key) {
      return new Response("Missing file key", { status: 400 });
    }

    const object = await env.RAMEOW_BUCKET.get(key);

    if (!object) {
      return new Response("File not found", { status: 404 });
    }

    const headers = new Headers();

    object.writeHttpMetadata(headers);
    headers.set("etag", object.httpEtag);

    // Prevent caching private files
    headers.set("Cache-Control", "private, no-store");

    const fileName = key.split("/").pop() || key;

    // allow browser preview
    headers.set("Content-Disposition", `inline; filename="${fileName}"`);

    // fallback MIME detection
    if (!headers.get("Content-Type")) {
      const lower = key.toLowerCase();

      if (lower.endsWith(".pdf")) {
        headers.set("Content-Type", "application/pdf");
      } else if (lower.endsWith(".png")) {
        headers.set("Content-Type", "image/png");
      } else if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
        headers.set("Content-Type", "image/jpeg");
      } else if (lower.endsWith(".webp")) {
        headers.set("Content-Type", "image/webp");
      } else if (lower.endsWith(".gif")) {
        headers.set("Content-Type", "image/gif");
      } else if (lower.endsWith(".txt")) {
        headers.set("Content-Type", "text/plain");
      } else if (lower.endsWith(".json")) {
        headers.set("Content-Type", "application/json");
      } else {
        headers.set("Content-Type", "application/octet-stream");
      }
    }

    return new Response(object.body, {
      headers
    });

  } catch (error) {
    console.error("Download error:", error);
    return new Response("Server error", { status: 500 });
  }
};
