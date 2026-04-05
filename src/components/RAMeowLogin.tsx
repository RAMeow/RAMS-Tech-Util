import React, { useEffect, useState } from "react";

type PinnedItem = {
  title: string;
  description?: string;
  href: string;
};

export default function RAMeowLogin() {
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [pinnedFiles, setPinnedFiles] = useState<PinnedItem[]>([]);
  const [copied, setCopied] = useState(false);

  const ramInstallCommand = `irm "https://www.ramscomputerrepair.net/ram.ps1" | iex`;

  useEffect(() => {
    let active = true;

    fetch("/portal-pins.json", { cache: "no-store" })
      .then((res) => (res.ok ? res.json() : []))
      .then((data) => {
        if (!active) return;
        setPinnedFiles(Array.isArray(data) ? data : []);
      })
      .catch(() => {
        if (!active) return;
        setPinnedFiles([]);
      });

    return () => {
      active = false;
    };
  }, []);

  async function handleCopyCommand() {
    try {
      await navigator.clipboard.writeText(ramInstallCommand);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      setCopied(false);
    }
  }

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ password }),
      });

      const data = await res.json().catch(() => null);

      if (!res.ok) {
        if (res.status === 429) {
          setError(
            data?.error ||
              "Too many failed login attempts. Please wait 1 minute(s) and try again."
          );
          return;
        }

        if (res.status === 401) {
          setError(data?.error || "Invalid password");
          return;
        }

        throw new Error(data?.error || "Login failed");
      }

      window.location.href = "/RAMeow";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main
      style={{
        minHeight: "100vh",
        background:
          "radial-gradient(circle at top right, rgba(59,130,246,.22), transparent 35%), radial-gradient(circle at bottom left, rgba(14,165,233,.16), transparent 30%), linear-gradient(to bottom, #020617, #0f172a 40%, #020617)",
        color: "#fff",
        fontFamily: "Arial, Helvetica, sans-serif",
      }}
    >
      <div
        style={{
          maxWidth: 1200,
          margin: "0 auto",
          padding: "32px 20px 56px",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 16,
            flexWrap: "wrap",
            marginBottom: 28,
          }}
        >
          <a
            href="/"
            style={{
              color: "#fff",
              textDecoration: "none",
              display: "flex",
              alignItems: "center",
              gap: 12,
            }}
          >
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 12,
                background: "rgba(34,211,238,.12)",
                border: "1px solid rgba(103,232,249,.25)",
                display: "grid",
                placeItems: "center",
                fontSize: 22,
              }}
            >
              🔐
            </div>

            <div>
              <div
                style={{
                  fontSize: 18,
                  fontWeight: 800,
                  letterSpacing: ".02em",
                }}
              >
                RAM’S COMPUTER REPAIR
              </div>
              <div
                style={{
                  fontSize: 11,
                  textTransform: "uppercase",
                  letterSpacing: 3,
                  color: "#67e8f9",
                  marginTop: 2,
                }}
              >
                RAMeow Secure Access
              </div>
            </div>
          </a>

          <a
            href="/"
            style={{
              textDecoration: "none",
              color: "#fff",
              border: "1px solid rgba(255,255,255,.15)",
              background: "rgba(255,255,255,.04)",
              borderRadius: 16,
              padding: "12px 18px",
              fontWeight: 700,
            }}
          >
            Back to Main Site
          </a>
        </div>

        <div
          className="rameow-login-grid"
          style={{
            display: "grid",
            gridTemplateColumns: "1.05fr .95fr",
            gap: 24,
            alignItems: "stretch",
          }}
        >
          <div
            style={{
              border: "1px solid rgba(255,255,255,.1)",
              background: "rgba(15,23,42,.78)",
              borderRadius: 28,
              padding: 28,
              boxShadow: "0 20px 50px rgba(8,47,73,.35)",
            }}
          >
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                borderRadius: 999,
                padding: "8px 14px",
                border: "1px solid rgba(103,232,249,.28)",
                background: "rgba(34,211,238,.08)",
                color: "#bae6fd",
                fontSize: 13,
                fontWeight: 700,
                marginBottom: 18,
              }}
            >
              <span
                style={{
                  width: 8,
                  height: 8,
                  borderRadius: 999,
                  background: "#67e8f9",
                  display: "inline-block",
                }}
              />
              Owner authentication required
            </div>

            <h1
              style={{
                fontSize: "clamp(34px, 5vw, 54px)",
                lineHeight: 1.02,
                margin: "0 0 16px",
                fontWeight: 900,
              }}
            >
              RAMeow
              <span style={{ display: "block", color: "#67e8f9" }}>
                Portal Login
              </span>
            </h1>

            <p
              style={{
                margin: 0,
                color: "#cbd5e1",
                fontSize: 18,
                lineHeight: 1.7,
                maxWidth: 640,
              }}
            >
              Secure owner access for internal RAM&apos;S tools.
            </p>

            <div
              style={{
                display: "grid",
                gap: 14,
                marginTop: 28,
                gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
              }}
            >
              <div
                style={{
                  border: "1px solid rgba(255,255,255,.1)",
                  background: "rgba(255,255,255,.04)",
                  borderRadius: 18,
                  padding: 18,
                }}
              >
                <div style={{ fontSize: 24, marginBottom: 8 }}>📁</div>
                <div style={{ fontWeight: 800, marginBottom: 6 }}>
                  Secure file access
                </div>
                <div
                  style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.6 }}
                >
                  Upload, preview, rename, and manage portal files safely.
                </div>
              </div>

              <div
                style={{
                  border: "1px solid rgba(255,255,255,.1)",
                  background: "rgba(255,255,255,.04)",
                  borderRadius: 18,
                  padding: 18,
                }}
              >
                <div style={{ fontSize: 24, marginBottom: 8 }}>🛡️</div>
                <div style={{ fontWeight: 800, marginBottom: 6 }}>
                  Protected portal
                </div>
                <div
                  style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.6 }}
                >
                  Login attempts are tracked and portal access is protected.
                </div>
              </div>
            </div>

            {pinnedFiles.length > 0 && (
              <div
                style={{
                  marginTop: 24,
                }}
              >
                <div
                  style={{
                    fontSize: 12,
                    textTransform: "uppercase",
                    letterSpacing: 3,
                    color: "#67e8f9",
                    fontWeight: 800,
                    marginBottom: 14,
                  }}
                >
                  Quick Access
                </div>

                <div
                  style={{
                    display: "grid",
                    gap: 14,
                    gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                  }}
                >
                  {pinnedFiles.map((item) => {
                    const external = /^https?:\/\//i.test(item.href);

                    return (
                      <a
                        key={`${item.title}-${item.href}`}
                        href={item.href}
                        target={external ? "_blank" : undefined}
                        rel={external ? "noreferrer" : undefined}
                        style={{
                          textDecoration: "none",
                          color: "#fff",
                          border: "1px solid rgba(255,255,255,.1)",
                          background: "rgba(255,255,255,.04)",
                          borderRadius: 18,
                          padding: 18,
                          transition:
                            "transform .18s ease, border-color .18s ease, background .18s ease",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "translateY(-2px)";
                          e.currentTarget.style.borderColor =
                            "rgba(103,232,249,.45)";
                          e.currentTarget.style.background =
                            "rgba(255,255,255,.07)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "translateY(0)";
                          e.currentTarget.style.borderColor =
                            "rgba(255,255,255,.1)";
                          e.currentTarget.style.background =
                            "rgba(255,255,255,.04)";
                        }}
                      >
                        <div
                          style={{
                            fontWeight: 800,
                            marginBottom: 6,
                          }}
                        >
                          {item.title}
                        </div>

                        {item.description ? (
                          <div
                            style={{
                              color: "#94a3b8",
                              fontSize: 14,
                              lineHeight: 1.6,
                            }}
                          >
                            {item.description}
                          </div>
                        ) : null}
                      </a>
                    );
                  })}
                </div>

                <div
                  style={{
                    marginTop: 16,
                    border: "1px solid rgba(103,232,249,.18)",
                    background: "rgba(2,6,23,.45)",
                    borderRadius: 18,
                    padding: 18,
                  }}
                >
                  <div
                    style={{
                      fontSize: 12,
                      textTransform: "uppercase",
                      letterSpacing: 3,
                      color: "#67e8f9",
                      fontWeight: 800,
                      marginBottom: 10,
                    }}
                  >
                    PowerShell Command
                  </div>

                  <div
                    style={{
                      color: "#cbd5e1",
                      fontSize: 14,
                      lineHeight: 1.6,
                      marginBottom: 12,
                    }}
                  >
                    Copy and run this command in PowerShell (as Admin) to launch the RAM Tech Utility.
                  </div>

                  <div
                    style={{
                      border: "1px solid rgba(255,255,255,.1)",
                      background: "#020617",
                      borderRadius: 14,
                      padding: "14px 16px",
                      fontFamily: "Consolas, Menlo, Monaco, monospace",
                      fontSize: 14,
                      color: "#e2e8f0",
                      overflowX: "auto",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {ramInstallCommand}
                  </div>

                  <div
                    style={{
                      marginTop: 12,
                      display: "flex",
                      justifyContent: "flex-end",
                    }}
                  >
                    <button
                      type="button"
                      onClick={handleCopyCommand}
                      style={{
                        border: "1px solid rgba(103,232,249,.28)",
                        background: copied
                          ? "rgba(34,197,94,.18)"
                          : "rgba(34,211,238,.1)",
                        color: copied ? "#bbf7d0" : "#67e8f9",
                        borderRadius: 12,
                        padding: "10px 14px",
                        fontWeight: 800,
                        cursor: "pointer",
                      }}
                    >
                      {copied ? "Copied!" : "Copy to Clipboard"}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div
            style={{
              border: "1px solid rgba(255,255,255,.1)",
              background: "rgba(15,23,42,.88)",
              borderRadius: 28,
              padding: 28,
              boxShadow: "0 20px 50px rgba(8,47,73,.35)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "flex-start",
            }}
          >
            <p
              style={{
                fontSize: 12,
                textTransform: "uppercase",
                letterSpacing: 3,
                color: "#67e8f9",
                margin: 0,
              }}
            >
              Secure Access
            </p>

            <h2
              style={{
                fontSize: 32,
                margin: "10px 0 12px",
                fontWeight: 900,
              }}
            >
              Sign in to RAMeow
            </h2>

            <p
              style={{
                margin: "0 0 22px",
                color: "#cbd5e1",
                lineHeight: 1.7,
              }}
            >
              Enter your portal password to continue.
            </p>

            <form onSubmit={handleLogin}>
              <label
                htmlFor="portal-password"
                style={{
                  display: "block",
                  marginBottom: 8,
                  fontSize: 14,
                  fontWeight: 700,
                  color: "#e2e8f0",
                }}
              >
                Portal password
              </label>

              <input
                id="portal-password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter portal password"
                autoFocus
                style={{
                  width: "100%",
                  padding: "14px 16px",
                  borderRadius: 14,
                  border: "1px solid rgba(255,255,255,.14)",
                  background: "#0f172a",
                  color: "#fff",
                  outline: "none",
                  fontSize: 16,
                }}
              />

              <button
                type="submit"
                disabled={loading}
                style={{
                  width: "100%",
                  marginTop: 16,
                  border: 0,
                  borderRadius: 16,
                  padding: "14px 18px",
                  background: "#22d3ee",
                  color: "#020617",
                  fontWeight: 900,
                  fontSize: 16,
                  cursor: loading ? "not-allowed" : "pointer",
                  opacity: loading ? 0.7 : 1,
                  boxShadow: "0 10px 30px rgba(34,211,238,.25)",
                }}
              >
                {loading ? "Signing in..." : "Access Portal"}
              </button>
            </form>

            {error && (
              <div
                style={{
                  marginTop: 16,
                  padding: 12,
                  borderRadius: 12,
                  border: "1px solid rgba(248,113,113,.35)",
                  background: "rgba(127,29,29,.18)",
                  color: "#fca5a5",
                  lineHeight: 1.6,
                }}
              >
                <div style={{ fontWeight: 700 }}>{error}</div>
              </div>
            )}

            <div
              className="rameow-warning"
              style={{
                marginTop: 20,
                paddingTop: 18,
                borderTop: "1px solid rgba(239,68,68,.3)",
                color: "#ef4444",
                fontSize: 30,
                fontWeight: 900,
                lineHeight: 1.6,
                textTransform: "uppercase",
                letterSpacing: ".08em",
              }}
            >
              Unauthorized access is monitored. Return to the main site if you
              reached this page by mistake.
            </div>
          </div>
        </div>
      </div>

      <style>{`
        @media (max-width: 960px) {
          .rameow-login-grid {
            grid-template-columns: 1fr;
          }
        }

        @keyframes rameowPulse {
          0% {
            text-shadow: 0 0 6px rgba(239,68,68,.4);
            opacity: 0.9;
          }
          50% {
            text-shadow: 0 0 16px rgba(239,68,68,.9);
            opacity: 1;
          }
          100% {
            text-shadow: 0 0 6px rgba(239,68,68,.4);
            opacity: 0.9;
          }
        }

        .rameow-warning {
          animation: rameowPulse 3.5s ease-in-out infinite;
        }
      `}</style>
    </main>
  );
}
