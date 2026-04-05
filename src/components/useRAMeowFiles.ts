import { useEffect, useRef, useState } from "react";

export type PortalFile = {
  key: string;
  size: number;
  uploaded: string;
};

export type FailedLoginAttempt = {
  key: string;
  timestamp: string;
  ip: string;
  userAgent: string;
  path: string;
};

export function useRAMeowFiles(isPortalRoute: boolean) {
  const [files, setFiles] = useState<PortalFile[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [dragActive, setDragActive] = useState(false);
  const [selectedPreview, setSelectedPreview] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [failedLoginCount, setFailedLoginCount] = useState(0);
  const [failedLoginAttempts, setFailedLoginAttempts] = useState<FailedLoginAttempt[]>([]);
  const [selectedFailedLoginKeys, setSelectedFailedLoginKeys] = useState<string[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function loadFiles() {
    try {
      const res = await fetch("/api/files", {
        method: "GET",
        cache: "no-store",
      });

      if (!res.ok) {
        throw new Error(`Failed to load files: ${res.status}`);
      }

      const data = await res.json();
      setFiles(Array.isArray(data.files) ? data.files : []);
    } catch (error) {
      console.error("Failed loading files:", error);
      setFiles([]);
    }
  }

async function loadFailedLoginCount() {
  try {
    const res = await fetch("/api/login-attempts-count", {
      method: "GET",
      cache: "no-store",
    });

    if (!res.ok) {
      throw new Error(`Failed to load login attempts count: ${res.status}`);
    }

    const data = await res.json();
    setFailedLoginCount(typeof data.count === "number" ? data.count : 0);
  } catch (error) {
    console.error("Failed loading login attempt count:", error);
    setFailedLoginCount(0);
  }
}

async function loadFailedLoginAttempts() {
  try {
    const res = await fetch("/api/login-attempts", {
      method: "GET",
      cache: "no-store",
    });

    if (!res.ok) {
      throw new Error(`Failed to load login attempts: ${res.status}`);
    }

    const data = await res.json();
    setFailedLoginAttempts(Array.isArray(data.attempts) ? data.attempts : []);
  } catch (error) {
    console.error("Failed loading login attempts:", error);
    setFailedLoginAttempts([]);
  }
}

function toggleFailedLoginSelection(key: string) {
  setSelectedFailedLoginKeys((current) =>
    current.includes(key)
      ? current.filter((item) => item !== key)
      : [...current, key]
  );
}

function clearFailedLoginSelection() {
  setSelectedFailedLoginKeys([]);
}

async function deleteFailedLoginAttempt(key: string) {
  const confirmed = window.confirm("Delete this failed login attempt?");
  if (!confirmed) return false;

  try {
    const res = await fetch("/api/delete-login-attempt", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ key }),
    });

    const data = await res.json().catch(() => null);

    if (!res.ok) {
      throw new Error(data?.error || `Delete failed: ${res.status}`);
    }

    await loadFailedLoginCount();
    await loadFailedLoginAttempts();

    setSelectedFailedLoginKeys((current) =>
      current.filter((item) => item !== key)
    );

    return true;
  } catch (error) {
    console.error("Failed deleting login attempt:", error);
    alert(error instanceof Error ? error.message : "Delete failed.");
    return false;
  }
}

async function deleteSelectedFailedLoginAttempts() {
  if (selectedFailedLoginKeys.length === 0) return false;

  const confirmed = window.confirm(
    `Delete ${selectedFailedLoginKeys.length} selected failed login attempt(s)?`
  );
  if (!confirmed) return false;

  try {
    const res = await fetch("/api/delete-login-attempt", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        keys: selectedFailedLoginKeys,
      }),
    });

    const data = await res.json().catch(() => null);

    if (!res.ok) {
      throw new Error(data?.error || `Delete failed: ${res.status}`);
    }

    clearFailedLoginSelection();
    await loadFailedLoginCount();
    await loadFailedLoginAttempts();

    return true;
  } catch (error) {
    console.error("Failed deleting selected login attempts:", error);
    alert(error instanceof Error ? error.message : "Delete failed.");
    return false;
  }
}

async function uploadSelectedFile(file: File) {
    const formData = new FormData();
    formData.append("file", file);

    setUploading(true);
    setUploadProgress(0);

    const xhr = new XMLHttpRequest();

    const uploadPromise = new Promise<void>((resolve, reject) => {
      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          setUploadProgress(Math.round((event.loaded / event.total) * 100));
        }
      };

      xhr.onload = async () => {
        setUploading(false);

        if (xhr.status >= 200 && xhr.status < 300) {
          setUploadProgress(100);
          await loadFiles();
          resolve();
        } else {
          reject(new Error(`Upload failed: ${xhr.status}`));
        }
      };

      xhr.onerror = () => {
        setUploading(false);
        reject(new Error("Upload failed due to network error"));
      };
    });

    xhr.open("POST", "/api/upload");
    xhr.send(formData);

    return uploadPromise;
  }

  async function deleteFile(key: string) {
    const confirmed = window.confirm(`Delete "${key}"?`);
    if (!confirmed) return;

    try {
      const res = await fetch("/api/delete", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ key }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => null);
        throw new Error(data?.error || `Delete failed: ${res.status}`);
      }

      if (selectedPreview === key) {
        setSelectedPreview(null);
      }

      await loadFiles();
    } catch (error) {
      console.error("Delete failed:", error);
      alert(error instanceof Error ? error.message : "Delete failed.");
    }
  }

  async function renameFile(oldKey: string, newKey: string) {
    const trimmedNewKey = newKey.trim();

    if (!trimmedNewKey) {
      alert("Please enter a new filename.");
      return false;
    }

    if (trimmedNewKey === oldKey) {
      return true;
    }

    try {
      const res = await fetch("/api/rename", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          oldKey,
          newKey: trimmedNewKey,
        }),
      });

      const data = await res.json().catch(() => null);

      if (!res.ok) {
        throw new Error(data?.error || `Rename failed: ${res.status}`);
      }

      if (selectedPreview === oldKey) {
        setSelectedPreview(trimmedNewKey);
      }

      await loadFiles();
      return true;
    } catch (error) {
      console.error("Rename failed:", error);
      alert(error instanceof Error ? error.message : "Rename failed.");
      return false;
    }
  }

  function inferPreviewType(key: string): "image" | "pdf" | "other" {
    const lower = key.toLowerCase();

    if (
      lower.endsWith(".png") ||
      lower.endsWith(".jpg") ||
      lower.endsWith(".jpeg") ||
      lower.endsWith(".webp") ||
      lower.endsWith(".gif") ||
      lower.endsWith(".bmp") ||
      lower.endsWith(".svg")
    ) {
      return "image";
    }

    if (lower.endsWith(".pdf")) {
      return "pdf";
    }

    return "other";
  }

  const filteredFiles = files.filter((file) => {
    const fileName = file.key.split("/").pop()?.toLowerCase() || file.key.toLowerCase();
    return fileName.includes(searchTerm.toLowerCase());
  });

useEffect(() => {
  if (isPortalRoute) {
    loadFiles();
    loadFailedLoginCount();
    loadFailedLoginAttempts();
  }
}, [isPortalRoute]);

  return {
  files,
  uploading,
  uploadProgress,
  dragActive,
  selectedPreview,
  searchTerm,
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
  setDragActive,
  setSelectedPreview,
  setSearchTerm,
  loadFiles,
  uploadSelectedFile,
  deleteFile,
  renameFile,
  inferPreviewType,
};
}
