export const onRequestGet: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ env }) => {
  try {
    const listed = await env.RAMEOW_BUCKET.list({
      prefix: "_system/login-attempts/",
    });

    const count = (listed.objects || []).length;

    return new Response(JSON.stringify({ count }), {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    console.error("Login attempts count error:", error);

    return new Response(
      JSON.stringify({
        count: 0,
        error: "Failed to load login attempts count",
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
