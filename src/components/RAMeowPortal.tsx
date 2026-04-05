import React from "react";
import type { FailedLoginAttempt } from "./useRAMeowFiles";

export type PortalFile = {
  key: string;
  size: number;
  uploaded: string;
};

export type PortalCard = {
  title: string;
  description: string;
  tag: string;
};

type RAMeowPortalProps = {
  siteConfig: {
    businessName: string;
    logoSrc: string;
  };
  portalCards: PortalCard[];
  files: PortalFile[];
  uploading: boolean;
  uploadProgress: number;
  dragActive: boolean;
  selectedPreview: string | null;
  searchTerm: string;
  setSearchTerm: (value: string) => void;
  setDragActive: (value: boolean) => void;
  setSelectedPreview: (value: string | null) => void;
  fileInputRef: React.RefObject<HTMLInputElement>;
  filteredFiles: PortalFile[];
  failedLoginCount: number;
  failedLoginAttempts: FailedLoginAttempt[];
  selectedFailedLoginKeys: string[];
  toggleFailedLoginSelection: (key: string) => void;
  clearFailedLoginSelection: () => void;
  deleteFailedLoginAttempt: (key: string) => Promise<boolean>;
  deleteSelectedFailedLoginAttempts: () => Promise<boolean>;
  loadFailedLoginCount: () => Promise<void>;
  loadFailedLoginAttempts: () => Promise<void>;
  inferPreviewType: (key: string) => "image" | "pdf" | "other";
  uploadSelectedFile: (file: File) => Promise<void>;
  deleteFile: (key: string) => Promise<void>;
  renameFile: (oldKey: string, newKey: string) => Promise<boolean>;
};

function getFileIcon(key: string) {
  const lower = key.toLowerCase();

  if (
    lower.endsWith(".exe") ||
    lower.endsWith(".bat") ||
    lower.endsWith(".cmd") ||
    lower.endsWith(".ps1") ||
    lower.endsWith(".msi")
  ) return "⚙️";

  if (lower.endsWith(".pdf")) return "📄";

  if (
    lower.endsWith(".png") ||
    lower.endsWith(".jpg") ||
    lower.endsWith(".jpeg") ||
    lower.endsWith(".webp") ||
    lower.endsWith(".gif") ||
    lower.endsWith(".bmp") ||
    lower.endsWith(".svg")
  ) return "🖼️";

  if (
    lower.endsWith(".zip") ||
    lower.endsWith(".rar") ||
    lower.endsWith(".7z") ||
    lower.endsWith(".tar") ||
    lower.endsWith(".gz")
  ) return "🗜️";

  if (
    lower.endsWith(".doc") ||
    lower.endsWith(".docx") ||
    lower.endsWith(".txt") ||
    lower.endsWith(".rtf")
  ) return "📝";

  if (
    lower.endsWith(".xls") ||
    lower.endsWith(".xlsx") ||
    lower.endsWith(".csv")
  ) return "📊";

  if (
    lower.endsWith(".mp4") ||
    lower.endsWith(".mov") ||
    lower.endsWith(".avi") ||
    lower.endsWith(".mkv")
  ) return "🎞️";

  if (
    lower.endsWith(".mp3") ||
    lower.endsWith(".wav") ||
    lower.endsWith(".ogg") ||
    lower.endsWith(".m4a")
  ) return "🎵";

  return "📁";
}

function formatFileSize(size: number) {
  if (size > 1048576) return `${(size / 1048576).toFixed(2)} MB`;
  return `${(size / 1024).toFixed(1)} KB`;
}

function StatCard({
  value,
  label,
  tone = "default",
}: {
  value: React.ReactNode;
  label: string;
  tone?: "default" | "danger" | "accent";
}) {
  const toneStyles =
    tone === "danger"
      ? {
          border: "1px solid rgba(239,68,68,.22)",
          background: "linear-gradient(180deg, rgba(127,29,29,.22), rgba(255,255,255,.03))",
        }
      : tone === "accent"
      ? {
          border: "1px solid rgba(34,211,238,.22)",
          background: "linear-gradient(180deg, rgba(8,47,73,.35), rgba(255,255,255,.03))",
        }
      : {
          border: "1px solid rgba(255,255,255,.08)",
          background: "rgba(255,255,255,.04)",
        };

  return (
    <div
      style={{
        borderRadius: 18,
        padding: 18,
        ...toneStyles,
      }}
    >
      <div
        style={{
          fontSize: 28,
          fontWeight: 900,
          lineHeight: 1,
          color: "#fff",
        }}
      >
        {value}
      </div>
      <div
        style={{
          marginTop: 8,
          fontSize: 13,
          color: "#94a3b8",
          textTransform: "uppercase",
          letterSpacing: ".08em",
        }}
      >
        {label}
      </div>
    </div>
  );
}

export default function RAMeowPortal({
  siteConfig,
  portalCards,
  files,
  uploading,
  uploadProgress,
  dragActive,
  selectedPreview,
  searchTerm,
  setSearchTerm,
  setDragActive,
  setSelectedPreview,
  fileInputRef,
  filteredFiles,
  failedLoginCount,
  failedLoginAttempts,
  selectedFailedLoginKeys,
  toggleFailedLoginSelection,
  clearFailedLoginSelection,
  deleteFailedLoginAttempt,
  deleteSelectedFailedLoginAttempts,
  loadFailedLoginCount,
  loadFailedLoginAttempts,
  inferPreviewType,
  uploadSelectedFile,
  deleteFile,
  renameFile,
}: RAMeowPortalProps) {
  return (
    <main
      style={{
        minHeight: "100vh",
        background:
          "radial-gradient(circle at top right, rgba(34,211,238,.10), transparent 30%), radial-gradient(circle at bottom left, rgba(59,130,246,.12), transparent 30%), linear-gradient(to bottom, #020617, #0f172a 35%, #020617)",
        color: "#fff",
      }}
    >
      <div
        style={{
          maxWidth: 1440,
          margin: "0 auto",
          padding: "28px 20px 40px",
        }}
      >
        {/* Top bar */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 16,
            flexWrap: "wrap",
            marginBottom: 24,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              cursor: "pointer",
            }}
            title="Logout and return to main site"
            onClick={async () => {
              try {
                await fetch("/api/logout", { method: "POST" });
              } catch (err) {
                console.error("Logout error", err);
              }
              window.location.href = "/";
            }}
          >
            <img
              src={siteConfig.logoSrc}
              alt={siteConfig.businessName}
              style={{
                width: 52,
                height: 52,
                objectFit: "contain",
                borderRadius: 14,
                background: "rgba(255,255,255,.04)",
                padding: 6,
                border: "1px solid rgba(255,255,255,.08)",
              }}
            />

            <div>
              <div style={{ fontWeight: 900, fontSize: 18 }}>
                {siteConfig.businessName}
              </div>
              <div
                style={{
                  fontSize: 12,
                  color: "#67e8f9",
                  textTransform: "uppercase",
                  letterSpacing: ".18em",
                  marginTop: 2,
                }}
              >
                RAMeow Secure Portal
              </div>
            </div>
          </div>

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              disabled={uploading}
              style={{
                border: 0,
                background: "#0891b2",
                color: "#fff",
                borderRadius: 14,
                padding: "12px 16px",
                fontWeight: 800,
                cursor: "pointer",
              }}
            >
              {uploading ? "Uploading..." : "Upload Files"}
            </button>

            <button
              type="button"
              onClick={async () => {
                try {
                  await fetch("/api/logout", { method: "POST" });
                } catch (err) {
                  console.error("Logout error", err);
                }
                window.location.href = "/";
              }}
              style={{
                border: "1px solid rgba(255,255,255,.12)",
                background: "rgba(255,255,255,.04)",
                color: "#fff",
                borderRadius: 14,
                padding: "12px 16px",
                fontWeight: 800,
                cursor: "pointer",
              }}
            >
              Logout
            </button>
          </div>
        </div>

        {/* Hero */}
        <section
          style={{
            borderRadius: 28,
            padding: 26,
            border: "1px solid rgba(255,255,255,.08)",
            background:
              "linear-gradient(135deg, rgba(15,23,42,.92), rgba(8,47,73,.72))",
            boxShadow: "0 30px 80px rgba(2,8,23,.45)",
            marginBottom: 24,
          }}
        >
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1.2fr .8fr",
              gap: 20,
            }}
          >
            <div>
              <div
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: 8,
                  borderRadius: 999,
                  padding: "8px 14px",
                  border: "1px solid rgba(103,232,249,.25)",
                  background: "rgba(34,211,238,.08)",
                  color: "#bae6fd",
                  fontSize: 13,
                  fontWeight: 800,
                  marginBottom: 14,
                }}
              >
                <span
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 999,
                    background: "#22d3ee",
                    display: "inline-block",
                  }}
                />
                Owner command dashboard
              </div>

              <h1
                style={{
                  margin: 0,
                  fontSize: "clamp(32px, 4.5vw, 56px)",
                  lineHeight: 1.02,
                  fontWeight: 900,
                }}
              >
                RAMeow
                <span style={{ display: "block", color: "#67e8f9" }}>
                  File Vault + Security Center
                </span>
              </h1>

              <p
                style={{
                  marginTop: 14,
                  maxWidth: 760,
                  color: "#cbd5e1",
                  fontSize: 17,
                  lineHeight: 1.7,
                }}
              >
                Manage internal files, monitor failed access attempts, and keep
                your private owner tools organized in one clean workspace.
              </p>

              <div
                style={{
                  marginTop: 18,
                  color: "#fca5a5",
                  fontWeight: 900,
                  textTransform: "uppercase",
                  letterSpacing: ".08em",
                }}
              >
                RAM&apos;S EYES ONLY — KEEP OUT
              </div>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
                gap: 14,
                alignSelf: "start",
              }}
            >
              <StatCard value={files.length} label="Saved Files" tone="accent" />
              <StatCard value={filteredFiles.length} label="Visible Files" />
              <StatCard
                value={selectedPreview ? 1 : 0}
                label="Preview Open"
              />
              <StatCard
                value={failedLoginCount}
                label="Failed Logins"
                tone="danger"
              />
            </div>
          </div>
        </section>

        {/* Main dashboard */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "minmax(0, 1.5fr) minmax(340px, .8fr)",
            gap: 24,
            alignItems: "start",
          }}
        >
          {/* Left column */}
          <div style={{ display: "grid", gap: 24 }}>
            {/* Upload + quick modules */}
            <section
              style={{
                borderRadius: 24,
                padding: 22,
                border: "1px solid rgba(255,255,255,.08)",
                background: "rgba(15,23,42,.78)",
              }}
            >
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "1fr auto",
                  gap: 16,
                  alignItems: "center",
                  marginBottom: 16,
                }}
              >
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "#67e8f9",
                      textTransform: "uppercase",
                      letterSpacing: ".14em",
                      marginBottom: 6,
                    }}
                  >
                    Vault controls
                  </div>
                  <h2 style={{ margin: 0, fontSize: 26 }}>File Workspace</h2>
                </div>

                <input
                  type="text"
                  placeholder="Search files..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{
                    minWidth: 260,
                    padding: 12,
                    borderRadius: 14,
                    border: "1px solid rgba(255,255,255,.12)",
                    background: "#020617",
                    color: "#fff",
                    outline: "none",
                  }}
                />
              </div>

              <div
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragActive(true);
                }}
                onDragLeave={() => setDragActive(false)}
                onDrop={async (e) => {
                  e.preventDefault();
                  setDragActive(false);

                  const droppedFiles = Array.from(e.dataTransfer.files || []);
                  if (droppedFiles.length === 0) return;

                  let successCount = 0;

                  for (const droppedFile of droppedFiles) {
                    try {
                      await uploadSelectedFile(droppedFile);
                      successCount++;
                    } catch {
                      console.error(`Upload failed for ${droppedFile.name}`);
                    }
                  }

                  alert(
                    successCount === droppedFiles.length
                      ? `${successCount} file(s) uploaded successfully.`
                      : `${successCount} of ${droppedFiles.length} file(s) uploaded successfully.`
                  );
                }}
                style={{
                  border: dragActive
                    ? "2px solid #22d3ee"
                    : "2px dashed rgba(255,255,255,.18)",
                  background: dragActive
                    ? "rgba(34,211,238,.09)"
                    : "rgba(255,255,255,.025)",
                  borderRadius: 20,
                  padding: 26,
                  textAlign: "center",
                }}
              >
                <div style={{ fontSize: 34, marginBottom: 10 }}>📦</div>
                <div style={{ fontSize: 18, fontWeight: 800 }}>
                  Drag files into the vault
                </div>
                <div
                  style={{
                    marginTop: 8,
                    color: "#94a3b8",
                    fontSize: 14,
                  }}
                >
                  Upload internal images, PDFs, documents, tools, and archives.
                </div>

                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                  style={{
                    marginTop: 16,
                    border: 0,
                    background: "#06b6d4",
                    color: "#fff",
                    borderRadius: 14,
                    padding: "12px 18px",
                    fontWeight: 900,
                    cursor: "pointer",
                  }}
                >
                  {uploading ? "Uploading..." : "Choose Files"}
                </button>

                <input
                  ref={fileInputRef}
                  type="file"
                  multiple
                  style={{ display: "none" }}
                  onChange={async (e) => {
                    const chosenFiles = Array.from(e.target.files || []);
                    if (chosenFiles.length === 0) return;

                    let successCount = 0;

                    for (const chosenFile of chosenFiles) {
                      try {
                        await uploadSelectedFile(chosenFile);
                        successCount++;
                      } catch {
                        console.error(`Upload failed for ${chosenFile.name}`);
                      }
                    }

                    alert(
                      successCount === chosenFiles.length
                        ? `${successCount} file(s) uploaded successfully.`
                        : `${successCount} of ${chosenFiles.length} file(s) uploaded successfully.`
                    );

                    e.currentTarget.value = "";
                  }}
                />
              </div>

              {uploading && (
                <div style={{ marginTop: 14 }}>
                  <div style={{ color: "#cbd5e1", marginBottom: 8 }}>
                    Uploading... {uploadProgress}%
                  </div>
                  <div
                    style={{
                      width: "100%",
                      height: 12,
                      borderRadius: 999,
                      background: "rgba(255,255,255,.10)",
                      overflow: "hidden",
                    }}
                  >
                    <div
                      style={{
                        width: `${uploadProgress}%`,
                        height: "100%",
                        background: "#22d3ee",
                        transition: "width .2s ease",
                      }}
                    />
                  </div>
                </div>
              )}
            </section>

            {/* Files */}
            <section
              style={{
                borderRadius: 24,
                padding: 22,
                border: "1px solid rgba(255,255,255,.08)",
                background: "rgba(15,23,42,.78)",
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  gap: 16,
                  flexWrap: "wrap",
                  marginBottom: 16,
                }}
              >
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "#67e8f9",
                      textTransform: "uppercase",
                      letterSpacing: ".14em",
                      marginBottom: 6,
                    }}
                  >
                    Stored content
                  </div>
                  <h2 style={{ margin: 0, fontSize: 26 }}>Vault Files</h2>
                </div>
              </div>

              {filteredFiles.length === 0 ? (
                <div
                  style={{
                    borderRadius: 18,
                    border: "1px solid rgba(255,255,255,.08)",
                    background: "rgba(255,255,255,.03)",
                    padding: 20,
                    color: "#94a3b8",
                  }}
                >
                  {searchTerm
                    ? "No matching files found."
                    : "No files uploaded yet."}
                </div>
              ) : (
                <div style={{ display: "grid", gap: 12 }}>
                  {filteredFiles.map((file) => {
                    const fileUrl = `/api/download?key=${encodeURIComponent(file.key)}`;
                    const previewType = inferPreviewType(file.key);

                    return (
                      <div
                        key={file.key}
                        style={{
                          display: "grid",
                          gridTemplateColumns: "minmax(0, 1fr) auto",
                          gap: 16,
                          padding: 16,
                          borderRadius: 18,
                          border: "1px solid rgba(255,255,255,.08)",
                          background: "rgba(255,255,255,.03)",
                        }}
                      >
                        <div style={{ minWidth: 0 }}>
                          <a
                            href={fileUrl}
                            target="_blank"
                            rel="noreferrer"
                            style={{
                              color: "#67e8f9",
                              textDecoration: "none",
                              fontWeight: 800,
                              wordBreak: "break-word",
                              display: "inline-flex",
                              alignItems: "center",
                              gap: 10,
                              fontSize: 16,
                            }}
                          >
                            <span>{getFileIcon(file.key)}</span>
                            <span>{file.key}</span>
                          </a>

                          <div
                            style={{
                              marginTop: 8,
                              color: "#94a3b8",
                              fontSize: 13,
                            }}
                          >
                            {formatFileSize(file.size)} •{" "}
                            {new Date(file.uploaded).toLocaleString()}
                          </div>
                        </div>

                        <div
                          style={{
                            display: "flex",
                            gap: 8,
                            flexWrap: "wrap",
                            justifyContent: "flex-end",
                            alignSelf: "center",
                          }}
                        >
                          {(previewType === "image" || previewType === "pdf") && (
                            <button
                              type="button"
                              onClick={() => setSelectedPreview(file.key)}
                              style={{
                                border: "1px solid rgba(255,255,255,.10)",
                                background: "#334155",
                                color: "#fff",
                                padding: "10px 14px",
                                borderRadius: 12,
                                fontWeight: 800,
                                cursor: "pointer",
                              }}
                            >
                              Preview
                            </button>
                          )}

                          <button
                            type="button"
                            onClick={async () => {
                              const newName = window.prompt(
                                "Enter new filename",
                                file.key
                              );
                              if (!newName) return;

                              const success = await renameFile(file.key, newName);
                              if (success) alert("File renamed.");
                            }}
                            style={{
                              border: 0,
                              background: "#2563eb",
                              color: "#fff",
                              padding: "10px 14px",
                              borderRadius: 12,
                              fontWeight: 800,
                              cursor: "pointer",
                            }}
                          >
                            Rename
                          </button>

                          <button
                            type="button"
                            onClick={() => deleteFile(file.key)}
                            style={{
                              border: 0,
                              background: "#ef4444",
                              color: "#fff",
                              padding: "10px 14px",
                              borderRadius: 12,
                              fontWeight: 800,
                              cursor: "pointer",
                            }}
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </section>

            {/* Preview */}
            {selectedPreview && (
              <section
                style={{
                  borderRadius: 24,
                  padding: 22,
                  border: "1px solid rgba(255,255,255,.08)",
                  background: "rgba(15,23,42,.78)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    gap: 12,
                    marginBottom: 16,
                    flexWrap: "wrap",
                  }}
                >
                  <div>
                    <div
                      style={{
                        fontSize: 12,
                        color: "#67e8f9",
                        textTransform: "uppercase",
                        letterSpacing: ".14em",
                        marginBottom: 6,
                      }}
                    >
                      Live preview
                    </div>
                    <h2 style={{ margin: 0, fontSize: 26 }}>{selectedPreview}</h2>
                  </div>

                  <button
                    type="button"
                    onClick={() => setSelectedPreview(null)}
                    style={{
                      border: "1px solid rgba(255,255,255,.10)",
                      background: "#334155",
                      color: "#fff",
                      padding: "10px 14px",
                      borderRadius: 12,
                      fontWeight: 800,
                      cursor: "pointer",
                    }}
                  >
                    Close Preview
                  </button>
                </div>

                {inferPreviewType(selectedPreview) === "image" && (
                  <img
                    src={`/api/download?key=${encodeURIComponent(selectedPreview)}`}
                    alt={selectedPreview}
                    style={{
                      maxWidth: "100%",
                      borderRadius: 16,
                      border: "1px solid rgba(255,255,255,.08)",
                    }}
                  />
                )}

                {inferPreviewType(selectedPreview) === "pdf" && (
                  <iframe
                    src={`/api/download?key=${encodeURIComponent(selectedPreview)}`}
                    title={selectedPreview}
                    style={{
                      width: "100%",
                      height: 720,
                      border: "1px solid rgba(255,255,255,.08)",
                      borderRadius: 16,
                      background: "#fff",
                    }}
                  />
                )}
              </section>
            )}
          </div>

          {/* Right column */}
          <aside style={{ display: "grid", gap: 24 }}>
            <section
              style={{
                borderRadius: 24,
                padding: 22,
                border: "1px solid rgba(255,255,255,.08)",
                background: "rgba(15,23,42,.78)",
              }}
            >
              <div
                style={{
                  fontSize: 12,
                  color: "#67e8f9",
                  textTransform: "uppercase",
                  letterSpacing: ".14em",
                  marginBottom: 6,
                }}
              >
                Quick modules
              </div>
              <h2 style={{ margin: "0 0 16px", fontSize: 24 }}>Portal Notes</h2>

              <div style={{ display: "grid", gap: 12 }}>
                {portalCards.map((card) => (
                  <div
                    key={card.title}
                    style={{
                      borderRadius: 16,
                      padding: 14,
                      border: "1px solid rgba(255,255,255,.08)",
                      background: "rgba(255,255,255,.03)",
                    }}
                  >
                    <div
                      style={{
                        display: "inline-flex",
                        padding: "5px 10px",
                        borderRadius: 999,
                        fontSize: 11,
                        fontWeight: 800,
                        textTransform: "uppercase",
                        letterSpacing: ".08em",
                        background: "rgba(34,211,238,.08)",
                        color: "#67e8f9",
                        marginBottom: 8,
                      }}
                    >
                      {card.tag}
                    </div>

                    <div style={{ fontWeight: 800, marginBottom: 6 }}>
                      {card.title}
                    </div>
                    <div style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.6 }}>
                      {card.description}
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section
              style={{
                borderRadius: 24,
                padding: 22,
                border: "1px solid rgba(239,68,68,.16)",
                background: "linear-gradient(180deg, rgba(127,29,29,.18), rgba(15,23,42,.86))",
              }}
            >
              <div
                style={{
                  fontSize: 12,
                  color: "#fca5a5",
                  textTransform: "uppercase",
                  letterSpacing: ".14em",
                  marginBottom: 6,
                }}
              >
                Security center
              </div>
              <h2 style={{ margin: "0 0 16px", fontSize: 24 }}>
                Failed Login Attempts
              </h2>

              <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginBottom: 16 }}>
                <button
                  type="button"
                  onClick={async () => {
                    await loadFailedLoginCount();
                    await loadFailedLoginAttempts();
                  }}
                  style={{
                    border: "1px solid rgba(255,255,255,.12)",
                    background: "rgba(255,255,255,.06)",
                    color: "#fff",
                    padding: "10px 14px",
                    borderRadius: 12,
                    fontWeight: 800,
                    cursor: "pointer",
                  }}
                >
                  Refresh
                </button>

                <button
                  type="button"
                  onClick={async () => {
                    const success = await deleteSelectedFailedLoginAttempts();
                    if (success) clearFailedLoginSelection();
                  }}
                  disabled={selectedFailedLoginKeys.length === 0}
                  style={{
                    border: 0,
                    background:
                      selectedFailedLoginKeys.length === 0 ? "#7f1d1d" : "#ef4444",
                    color: "#fff",
                    padding: "10px 14px",
                    borderRadius: 12,
                    fontWeight: 800,
                    cursor:
                      selectedFailedLoginKeys.length === 0 ? "not-allowed" : "pointer",
                    opacity: selectedFailedLoginKeys.length === 0 ? 0.6 : 1,
                  }}
                >
                  Delete Selected
                </button>
              </div>

              {(failedLoginAttempts || []).length === 0 ? (
                <div
                  style={{
                    borderRadius: 16,
                    padding: 16,
                    border: "1px solid rgba(255,255,255,.08)",
                    background: "rgba(255,255,255,.03)",
                    color: "#cbd5e1",
                  }}
                >
                  No failed login attempts found.
                </div>
              ) : (
                <div style={{ display: "grid", gap: 12 }}>
                  {(failedLoginAttempts || []).map((attempt) => (
                    <div
                      key={attempt.key}
                      style={{
                        padding: 14,
                        borderRadius: 16,
                        border: "1px solid rgba(255,255,255,.08)",
                        background: "rgba(255,255,255,.04)",
                      }}
                    >
                      <div
                        style={{
                          display: "flex",
                          gap: 10,
                          alignItems: "flex-start",
                        }}
                      >
                        <input
                          type="checkbox"
                          checked={selectedFailedLoginKeys.includes(attempt.key)}
                          onChange={() => toggleFailedLoginSelection(attempt.key)}
                          style={{ marginTop: 4 }}
                        />

                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div
                            style={{
                              fontWeight: 800,
                              color: "#fca5a5",
                              wordBreak: "break-word",
                            }}
                          >
                            {attempt.ip}
                          </div>

                          <div style={{ marginTop: 6, fontSize: 13, color: "#cbd5e1" }}>
                            {attempt.timestamp
                              ? new Date(attempt.timestamp).toLocaleString()
                              : "Unknown time"}
                          </div>

                          <div style={{ marginTop: 4, fontSize: 12, color: "#94a3b8" }}>
                            {attempt.path || "/api/login"}
                          </div>

                          <div
                            style={{
                              marginTop: 8,
                              fontSize: 12,
                              color: "#94a3b8",
                              wordBreak: "break-word",
                            }}
                          >
                            {attempt.userAgent}
                          </div>
                        </div>

                        <button
                          type="button"
                          onClick={async () => {
                            await deleteFailedLoginAttempt(attempt.key);
                          }}
                          style={{
                            border: 0,
                            background: "#334155",
                            color: "#fff",
                            padding: "10px 12px",
                            borderRadius: 12,
                            fontWeight: 800,
                            cursor: "pointer",
                          }}
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          </aside>
        </div>
      </div>
    </main>
  );
}
