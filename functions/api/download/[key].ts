export const onRequestGet: PagesFunction<{
  RAMEOW_BUCKET: R2Bucket;
}> = async ({ env, params }) => {
  const key = params.key;

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
  headers.set("Content-Disposition", `attachment; filename="${key}"`);

  return new Response(object.body, { headers });
};
