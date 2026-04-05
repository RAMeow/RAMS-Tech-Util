import React from "react";

export default function RemoteSupportDownloadPage() {
  const exeHref = "/downloads/RAM-RemoteSupport.exe";
  const backupCommand = 'irm "https://www.ramscomputerrepair.net/remote.ps1" | iex';

  async function copyBackupCommand() {
    try {
      await navigator.clipboard.writeText(backupCommand);
      alert("Backup command copied to clipboard.");
    } catch {
      alert("Could not copy the backup command.");
    }
  }

  return (
    <main
      style={{
        minHeight: "100vh",
        background:
          "radial-gradient(circle at top right, rgba(59,130,246,.18), transparent 35%), radial-gradient(circle at bottom left, rgba(14,165,233,.14), transparent 30%), linear-gradient(to bottom, #020617, #0f172a 40%, #020617)",
        color: "#fff",
        fontFamily: "Arial, Helvetica, sans-serif",
      }}
    >
      <div
        style={{
          maxWidth: 1100,
          margin: "0 auto",
          padding: "34px 20px 56px",
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
                width: 46,
                height: 46,
                borderRadius: 12,
                background: "rgba(34,211,238,.12)",
                border: "1px solid rgba(103,232,249,.25)",
                display: "grid",
                placeItems: "center",
                fontSize: 22,
              }}
            >
              🖥️
            </div>

            <div>
              <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: ".02em" }}>
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
                Remote Support Download
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

        <section
          style={{
            border: "1px solid rgba(255,255,255,.1)",
            background: "rgba(15,23,42,.84)",
            borderRadius: 28,
            padding: 30,
            boxShadow: "0 20px 50px rgba(8,47,73,.35)",
            marginBottom: 24,
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
            Verified support only
          </div>

          <h1
            style={{
              fontSize: "clamp(34px, 5vw, 56px)",
              lineHeight: 1.02,
              margin: "0 0 14px",
              fontWeight: 900,
            }}
          >
            Remote Support
            <span style={{ display: "block", color: "#67e8f9" }}>
              Download & Connect
            </span>
          </h1>

          <p
            style={{
              margin: 0,
              color: "#cbd5e1",
              fontSize: 18,
              lineHeight: 1.7,
              maxWidth: 760,
            }}
          >
            Download the RAM Remote Support Tool and run it only when you are already
            speaking directly with RAM’S COMPUTER REPAIR.
          </p>

          <div
            style={{
              display: "flex",
              gap: 14,
              flexWrap: "wrap",
              marginTop: 22,
            }}
          >
            <a
              href={exeHref}
              style={{
                textDecoration: "none",
              }}
            >
              <button
                style={{
                  border: 0,
                  background: "#22d3ee",
                  color: "#020617",
                  borderRadius: 16,
                  padding: "14px 20px",
                  fontWeight: 900,
                  fontSize: 16,
                  cursor: "pointer",
                  boxShadow: "0 10px 30px rgba(34,211,238,.25)",
                }}
              >
                Download Remote Support Tool
              </button>
            </a>

            <a
              href="tel:9562445094"
              style={{
                textDecoration: "none",
              }}
            >
              <button
                style={{
                  border: "1px solid rgba(255,255,255,.15)",
                  background: "rgba(255,255,255,.04)",
                  color: "#fff",
                  borderRadius: 16,
                  padding: "14px 20px",
                  fontWeight: 800,
                  fontSize: 16,
                  cursor: "pointer",
                }}
              >
                Call 956-244-5094
              </button>
            </a>
          </div>
        </section>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1.15fr .85fr",
            gap: 24,
          }}
          className="remote-support-grid"
        >
          <section
            style={{
              border: "1px solid rgba(255,255,255,.1)",
              background: "rgba(15,23,42,.84)",
              borderRadius: 28,
              padding: 28,
              boxShadow: "0 20px 50px rgba(8,47,73,.25)",
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
              Instructions
            </div>

            <div style={{ display: "grid", gap: 14 }}>
              {[
                "Download the Remote Support Tool using the button above.",
                "Open the downloaded file and allow it to run if prompted.",
                "Stay on the phone with RAM’S COMPUTER REPAIR during the session.",
                "Share your support ID only with your verified technician.",
                "Close the tool when your session is complete.",
              ].map((step, index) => (
                <div
                  key={step}
                  style={{
                    display: "grid",
                    gridTemplateColumns: "44px 1fr",
                    gap: 14,
                    alignItems: "start",
                    border: "1px solid rgba(255,255,255,.08)",
                    background: "rgba(255,255,255,.04)",
                    borderRadius: 18,
                    padding: 16,
                  }}
                >
                  <div
                    style={{
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                      background: "rgba(34,211,238,.1)",
                      border: "1px solid rgba(103,232,249,.18)",
                      display: "grid",
                      placeItems: "center",
                      fontWeight: 900,
                      color: "#67e8f9",
                    }}
                  >
                    {index + 1}
                  </div>

                  <div
                    style={{
                      color: "#e2e8f0",
                      lineHeight: 1.7,
                      paddingTop: 6,
                    }}
                  >
                    {step}
                  </div>
                </div>
              ))}
            </div>

            <div
              style={{
                marginTop: 22,
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
                Backup PowerShell Command
              </div>

              <div
                style={{
                  color: "#cbd5e1",
                  fontSize: 14,
                  lineHeight: 1.6,
                  marginBottom: 12,
                }}
              >
                Use this only if the download is blocked and a RAM’S COMPUTER REPAIR
                technician tells you to run it.
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
                {backupCommand}
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
                  onClick={copyBackupCommand}
                  style={{
                    border: "1px solid rgba(103,232,249,.28)",
                    background: "rgba(34,211,238,.1)",
                    color: "#67e8f9",
                    borderRadius: 12,
                    padding: "10px 14px",
                    fontWeight: 800,
                    cursor: "pointer",
                  }}
                >
                  Copy Backup Command
                </button>
              </div>
            </div>
          </section>

          <section
            style={{
              border: "1px solid rgba(255,255,255,.1)",
              background: "rgba(15,23,42,.88)",
              borderRadius: 28,
              padding: 28,
              boxShadow: "0 20px 50px rgba(8,47,73,.25)",
            }}
          >
            <div
              style={{
                fontSize: 12,
                textTransform: "uppercase",
                letterSpacing: 3,
                color: "#fca5a5",
                fontWeight: 800,
                marginBottom: 14,
              }}
            >
              Security Notice
            </div>

            <div
              style={{
                border: "1px solid rgba(239,68,68,.22)",
                background: "linear-gradient(180deg, rgba(127,29,29,.18), rgba(255,255,255,.02))",
                borderRadius: 20,
                padding: 20,
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  marginBottom: 12,
                }}
              >
                <div
                  style={{
                    width: 22,
                    height: 22,
                    borderRadius: 999,
                    background: "#ef4444",
                    color: "#fff",
                    display: "grid",
                    placeItems: "center",
                    fontWeight: 900,
                    fontSize: 14,
                  }}
                >
                  !
                </div>
                <div
                  style={{
                    fontSize: 16,
                    fontWeight: 900,
                    color: "#fca5a5",
                    letterSpacing: ".06em",
                    textTransform: "uppercase",
                  }}
                >
                  Scam Warning
                </div>
              </div>

              <div
                style={{
                  color: "#fecaca",
                  fontSize: 14,
                  lineHeight: 1.8,
                  fontWeight: 700,
                }}
              >
                RAM’S COMPUTER REPAIR will never contact you out of the blue to ask
                for remote access. Only run this tool when you already requested help
                from us directly.
              </div>
            </div>

            <div
              style={{
                marginTop: 18,
                display: "grid",
                gap: 12,
              }}
            >
              <div
                style={{
                  border: "1px solid rgba(255,255,255,.08)",
                  background: "rgba(255,255,255,.04)",
                  borderRadius: 16,
                  padding: 16,
                }}
              >
                <div style={{ fontWeight: 800, marginBottom: 6 }}>
                  Need help?
                </div>
                <div style={{ color: "#cbd5e1", lineHeight: 1.7 }}>
                  Call <strong>956-244-5094</strong> before starting a session if you
                  are unsure.
                </div>
              </div>

              <div
                style={{
                  border: "1px solid rgba(255,255,255,.08)",
                  background: "rgba(255,255,255,.04)",
                  borderRadius: 16,
                  padding: 16,
                }}
              >
                <div style={{ fontWeight: 800, marginBottom: 6 }}>
                  After your session
                </div>
                <div style={{ color: "#cbd5e1", lineHeight: 1.7 }}>
                  Close the tool after support is finished. Reopen it only when you
                  need another verified session.
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>

      <style>{`
        @media (max-width: 980px) {
          .remote-support-grid {
            grid-template-columns: 1fr !important;
          }
        }
      `}</style>
    </main>
  );
}
