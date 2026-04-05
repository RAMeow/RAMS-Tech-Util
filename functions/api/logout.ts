export const onRequestPost: PagesFunction = async () => {
  return new Response(
    JSON.stringify({ ok: true }),
    {
      headers: {
        "Content-Type": "application/json",
        "Set-Cookie": [
          "rameow_session=",
          "Path=/",
          "HttpOnly",
          "Secure",
          "SameSite=Strict",
          "Max-Age=0",
        ].join("; "),
      },
    }
  );
};
