const PUBLIC_PATHS = [
  "/",
  "/RAMeow-login",
];

const PUBLIC_API_PATHS = [
  "/api/login",
];

function normalizePath(pathname: string) {
  return pathname.toLowerCase();
}

function isPublicPath(pathname: string) {
  const normalized = normalizePath(pathname);
  return PUBLIC_PATHS.some((path) => path.toLowerCase() === normalized);
}

function isPublicApiPath(pathname: string) {
  const normalized = normalizePath(pathname);
  return PUBLIC_API_PATHS.some((path) => path.toLowerCase() === normalized);
}

function getCookieValue(cookieHeader: string | null, name: string) {
  if (!cookieHeader) return null;

  const cookies = cookieHeader.split(";").map((part) => part.trim());
  const match = cookies.find((cookie) => cookie.startsWith(`${name}=`));
  return match ? decodeURIComponent(match.split("=").slice(1).join("=")) : null;
}

export const onRequest: PagesFunction<{
  RAMEOW_PORTAL_PASSWORD: string;
  RAMEOW_SESSION_TOKEN: string;
}> = async (context) => {
  const { request, env, next } = context;
  const url = new URL(request.url);
  const { pathname } = url;
  const lowerPath = normalizePath(pathname);

  if (lowerPath === "/rameow-login" && pathname !== "/RAMeow-login") {
    return Response.redirect(`${url.origin}/RAMeow-login`, 301);
  }

  if (lowerPath === "/rameow" && pathname !== "/RAMeow") {
    return Response.redirect(`${url.origin}/RAMeow`, 301);
  }

  const isPortalRoute = lowerPath.startsWith("/rameow");
  const isApiRoute = lowerPath.startsWith("/api/");

  if (
    isPublicPath(pathname) ||
    isPublicApiPath(pathname) ||
    (!isPortalRoute && !isApiRoute)
  ) {
    return next();
  }

  const cookieHeader = request.headers.get("Cookie");
  const sessionCookie = getCookieValue(cookieHeader, "rameow_session");

  if (sessionCookie && sessionCookie === env.RAMEOW_SESSION_TOKEN) {
    return next();
  }

  if (isApiRoute) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      {
        status: 401,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
  }

  return Response.redirect(`${url.origin}/RAMeow-login`, 302);
};
