export const onRequestGet: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ env }) => {
  try {
    const listed = await env.RAMEOW_BUCKET.list();

    const files = (listed.objects || [])
      .filter((object) => !object.key.startsWith("_system/"))
      .map((object) => ({
        key: object.key,
        size: object.size ?? 0,
        uploaded: object.uploaded ? object.uploaded.toISOString() : "",
      }))
      .sort((a, b) => {
        const aTime = a.uploaded ? new Date(a.uploaded).getTime() : 0;
        const bTime = b.uploaded ? new Date(b.uploaded).getTime() : 0;
        return bTime - aTime;
      });

    return new Response(JSON.stringify({ files }), {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    console.error("Files list error:", error);

    return new Response(
      JSON.stringify({
        files: [],
        error: "Failed to load files",
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
