import logo from "../assets/logo.png";
import reviewQr from "../assets/review-qr.png";
import React, { useEffect } from "react";
import RAMeowPortal from "./components/RAMeowPortal";
import PublicSite from "./components/PublicSite";
import RAMeowLogin from "./components/RAMeowLogin";
import { useRAMeowFiles } from "./components/useRAMeowFiles";
import RemoteSupportDownloadPage from "./RemoteSupportDownloadPage";

import {
  siteConfig as buildSiteConfig,
  residentialServices,
  businessFocusCards,
  serviceAreas,
  commonProblems,
  trustReasons,
  reviewStats,
  highlights,
} from "./components/siteData";

export default function RamsComputerRepairRefresh() {
  const siteConfig = buildSiteConfig(logo, reviewQr);

  const currentPath =
  typeof window !== "undefined" ? window.location.pathname : "/";
const loginPath = "/RAMeow-login";
const remoteSupportPath = "/remote-support";

const isLoginRoute = currentPath
  .toLowerCase()
  .startsWith(loginPath.toLowerCase());

const isRemoteSupportRoute = currentPath
  .toLowerCase()
  .startsWith(remoteSupportPath.toLowerCase());

const isPortalRoute =
  !isLoginRoute &&
  !isRemoteSupportRoute &&
  currentPath
    .toLowerCase()
    .startsWith(siteConfig.portalPath.toLowerCase());

  useEffect(() => {
    if (isPortalRoute || isLoginRoute) return;

    const handler = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === "r") {
        window.location.href = "/RAMeow-login";
      }
    };

    window.addEventListener("keydown", handler);

    return () => {
      window.removeEventListener("keydown", handler);
    };
  }, [isPortalRoute, isLoginRoute]);

  const localBusinessSchema = {
    "@context": "https://schema.org",
    "@type": "ComputerRepair",
    name: siteConfig.businessName,
    telephone: "+1-956-244-5094",
    email: siteConfig.email,
    address: {
      "@type": "PostalAddress",
      addressLocality: "Harlingen",
      addressRegion: "TX",
      addressCountry: "US",
    },
    areaServed: serviceAreas,
    url: siteConfig.domain,
  };

  const portalCards = [];

  const {
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
  uploadSelectedFile,
  deleteFile,
  renameFile,
  inferPreviewType,
} = useRAMeowFiles(isPortalRoute);

  if (isLoginRoute) {
  return <RAMeowLogin />;
}

if (isRemoteSupportRoute) {
  return <RemoteSupportDownloadPage />;
  }

  return (
    <>
      <style>{`
        * { box-sizing: border-box; }
        body { margin: 0; }
        .page { position: relative; min-height: 100vh; overflow: hidden; background: #020617; color: #fff; font-family: Arial, Helvetica, sans-serif; }
        .bg { position: absolute; inset: 0; pointer-events: none; opacity: .12; }
        .container { max-width: 1200px; margin: 0 auto; padding: 0 24px; position: relative; }
        .header { position: sticky; top: 0; z-index: 50; border-bottom: 1px solid rgba(255,255,255,.1); background: rgba(2,6,23,.92); backdrop-filter: blur(8px); }
        .header-inner { display: flex; flex-direction: column; gap: 14px; padding: 16px 0; }
        .header-top { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; }
        .logo-row { display: flex; align-items: center; gap: 12px; min-width: 0; }
        
        .logo-row:hover {
  opacity: 0.85;
  transform: scale(1.02);
}
        .logo { height: 48px; width: auto; filter: drop-shadow(0 0 12px rgba(34,211,238,.18)); }
        .brand-name { display:block; font-size: 18px; font-weight: 700; letter-spacing: .3px; }
        .sub-brand { display:block; font-size: 11px; text-transform: uppercase; letter-spacing: 3px; color: #67e8f9; }
        .nav { display:flex; flex-wrap:wrap; gap:8px; align-items:center; }
        .nav a, .button-mini { color:#e2e8f0; text-decoration:none; border:1px solid rgba(255,255,255,.12); border-radius:16px; padding:18px 26px; font-size:18px; font-weight:800; background:rgba(255,255,255,.06); transition:all .18s ease; }
        .nav a:hover, .button-mini:hover { background:#22d3ee; color:#020617; border-color:#22d3ee; transform:translateY(-1px); }
        .button-small, .button-primary { display:inline-block; background:#22d3ee; color:#020617; text-decoration:none; border-radius:14px; padding:12px 18px; font-weight:800; box-shadow:0 10px 30px rgba(34,211,238,.25); }
        .button-primary { padding:14px 24px; border-radius:16px; border:0; cursor:pointer; }
        .review-button { display:inline-flex; align-items:center; gap:12px; padding:18px 28px; font-size:18px; font-weight:900; border-radius:18px; }
        .google-badge { display:inline-flex; align-items:center; justify-content:center; width:34px; height:34px; border-radius:999px; background:#fff; color:#2563eb; font-size:22px; font-weight:900; flex:0 0 auto; }
        .review-stars-inline { font-size:18px; color:#fcd34d; letter-spacing:1px; }
        .button-ghost { display:inline-block; text-decoration:none; color:#fff; border:1px solid rgba(255,255,255,.18); border-radius:16px; padding:14px 24px; background: rgba(255,255,255,.04); }
        .hero { position: relative; overflow:hidden; border-bottom:1px solid rgba(255,255,255,.1); background: radial-gradient(circle at top right, rgba(59,130,246,.22), transparent 35%), radial-gradient(circle at bottom left, rgba(14,165,233,.16), transparent 30%), linear-gradient(to bottom, rgba(2,6,23,.08), rgba(2,6,23,.18), rgba(2,6,23,.65)); }
        .hero-inner { padding: 72px 0 88px; }
        .hero-grid, .reviews-grid, .cta-grid { display:grid; gap:32px; align-items:center; }
        .hero-grid { grid-template-columns: 1.15fr .85fr; gap:40px; }
        .reviews-grid { grid-template-columns: .9fr 1.1fr; align-items: start; }
        .cta-grid { grid-template-columns: 1.3fr .7fr; }
        .badge-row, .hero-buttons, .hero-links, .chips, .review-actions { display:flex; flex-wrap:wrap; gap:12px; }
        .pill, .meta-pill, .chip { border-radius:999px; padding:10px 16px; font-size:14px; }
        .pill { border:1px solid rgba(103,232,249,.3); background:rgba(34,211,238,.1); color:#bae6fd; }
        .dot { width:8px; height:8px; border-radius:999px; background:#67e8f9; display:inline-block; margin-right:8px; }
        .meta-pill, .chip { border:1px solid rgba(255,255,255,.1); background:rgba(255,255,255,.04); color:#e2e8f0; }
        .hero-title { font-size: clamp(40px, 7vw, 62px); line-height:1.02; font-weight:900; margin:0 0 20px; }
        .hero-accent { display:block; color:#67e8f9; }
        .hero-text, .section-text, .card p, .panel-text, .small-text, .portal-copy { color:#cbd5e1; line-height:1.7; }
        .hero-text { font-size: clamp(17px, 2.5vw, 20px); max-width:720px; margin:0 0 28px; }
        .hero-highlights, .grid4, .grid3, .grid2, .three-stats, .reviews-right, .portal-shell, .portal-list, .portal-dashboard, .portal-stat-grid { display:grid; gap:16px; }
        .hero-highlights { grid-template-columns: repeat(2, minmax(0,1fr)); max-width:700px; margin-top:24px; }
        .grid4 { grid-template-columns: repeat(4, minmax(0,1fr)); margin-top:28px; }
        .grid3 { grid-template-columns: repeat(3, minmax(0,1fr)); margin-top:28px; }
        .grid2 { grid-template-columns: repeat(2, minmax(0,1fr)); margin-top:24px; }
        .three-stats { grid-template-columns: repeat(3, minmax(0,1fr)); }
        .reviews-right { grid-template-columns: 1fr 240px; align-items:start; gap:24px; }
        .portal-shell { grid-template-columns: .95fr 1.05fr; margin-top:28px; }
        .portal-stat-grid { grid-template-columns: repeat(4, minmax(0,1fr)); gap:12px; }        
        .highlight-card, .card.light, .stat-card, .portal-stat, .portal-nav-card { border:1px solid rgba(255,255,255,.1); background:rgba(255,255,255,.05); border-radius:20px; padding:18px; }
        .card.dark, .panel, .qr-box, .cta-box, .portal-panel { border:1px solid rgba(255,255,255,.1); background:rgba(15,23,42,.82); border-radius:24px; padding:24px; }
        .card h3, .section-title, .panel-title, .portal-title { margin:0; font-weight:800; }
        .card h3 { font-size:20px; }
        .card p { margin:12px 0 0; }
        .section, .section-muted, .section-dark { padding:64px 0; }
        .section-muted { border-top:1px solid rgba(255,255,255,.1); border-bottom:1px solid rgba(255,255,255,.1); background:rgba(255,255,255,.03); }
        .section-dark { border-top:1px solid rgba(255,255,255,.1); border-bottom:1px solid rgba(255,255,255,.1); background:rgba(15,23,42,.5); }
        .section-title-small, .panel-label, .service-list-title, .qr-label, .portal-kicker { font-size:12px; text-transform:uppercase; letter-spacing:3px; color:#67e8f9; margin:0; }
        .section-title { font-size: clamp(28px, 4vw, 40px); margin:10px 0 18px; }
        .panel { box-shadow: 0 20px 50px rgba(8,47,73,.45); }
        .panel-header { display:flex; justify-content:space-between; align-items:flex-start; gap:16px; margin-bottom:20px; }
        .panel-title, .portal-title { font-size: clamp(28px, 4vw, 34px); margin-top:10px; }
        .panel-call-box { border:1px solid rgba(34,211,238,.2); background:rgba(34,211,238,.1); border-radius:16px; padding:10px 14px; text-align:right; }
        .panel-call-label { font-size:11px; text-transform:uppercase; letter-spacing:3px; color:#bae6fd; }
        .panel-call-num { font-size:22px; font-weight:800; margin-top:6px; }
        .service-list-box { border:1px solid rgba(255,255,255,.1); background:rgba(2,6,23,.6); border-radius:18px; padding:18px; margin-top:16px; }
        .service-list { display:grid; gap:12px; margin-top:14px; }
        .service-item { border:1px solid rgba(255,255,255,.1); background:rgba(255,255,255,.04); border-radius:12px; padding:12px 14px; font-size:14px; }
        .stat-big { font-size:34px; font-weight:900; color:#67e8f9; }
        .stat-label { margin-top:8px; font-size:12px; text-transform:uppercase; letter-spacing:2px; color:#94a3b8; }
        .emergency { border-bottom:1px solid rgba(34,211,238,.2); background:rgba(34,211,238,.1); }
        .emergency-inner { display:flex; justify-content:space-between; align-items:center; gap:18px; flex-wrap:wrap; padding:16px 0; }
        .emergency-title { margin:0; font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:3px; color:#67e8f9; }
        .emergency-text { margin:6px 0 0; color:#e2e8f0; }
        .rating-row { display:flex; align-items:center; gap:16px; margin-top:18px; }
        .rating-big { font-size:54px; font-weight:900; }
        .stars { font-size:28px; color:#fcd34d; }
        .qr-box { text-align:center; }
        .qr-image { width:100%; max-width:240px; border-radius:14px; border:1px solid rgba(255,255,255,.1); background:#fff; padding:8px; }
        .portal-note, .portal-file-meta { font-size:13px; color:#94a3b8; line-height:1.6; margin-top:4px; }
        .portal-stat strong { display:block; font-size:22px; color:#67e8f9; }
        .portal-nav-tag { border:1px solid rgba(103,232,249,.25); background:rgba(34,211,238,.08); color:#bae6fd; border-radius:999px; padding:6px 10px; font-size:12px; white-space:nowrap; display:inline-block; }
        .floating-call { position:fixed; right:16px; bottom:16px; z-index:60; background:#22d3ee; color:#020617; text-decoration:none; font-weight:900; border-radius:999px; padding:16px 22px; box-shadow:0 14px 30px rgba(34,211,238,.35); }
        @media (max-width: 1024px) {
          .hero-grid, .reviews-grid, .cta-grid, .portal-shell { grid-template-columns: 1fr; }
          .reviews-right { grid-template-columns: 1fr; }
          .grid4 { grid-template-columns: repeat(2, minmax(0,1fr)); }
          .grid3 { grid-template-columns: repeat(2, minmax(0,1fr)); }
          .portal-stat-grid { grid-template-columns: repeat(2, minmax(0,1fr)); }
          .cta-buttons { align-items: stretch; }
        }
        @media (max-width: 768px) {
          .container { padding: 0 16px; }
          .button-primary, .button-ghost, .button-small, .button-mini { width: 100%; text-align: center; }
          .hero-inner { padding: 48px 0 56px; }
          .hero-highlights, .grid4, .grid3, .grid2, .three-stats, .portal-stat-grid { grid-template-columns: 1fr; }
          .pill, .meta-pill, .chip, .review-actions > * { width: 100%; }
          .review-actions { align-items: stretch; }
          .floating-call { left:16px; right:16px; text-align:center; }
          .nav a { font-size:16px; padding:14px 18px; }
        }
      `}</style>

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(localBusinessSchema) }}
      />

      <div className="page">
        <div className="bg">
          <svg
            width="100%"
            height="100%"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1600 1200"
            preserveAspectRatio="none"
          >
            <defs>
              <pattern
                id="pcbPattern"
                width="260"
                height="220"
                patternUnits="userSpaceOnUse"
              >
                <g
                  stroke="#22d3ee"
                  strokeWidth="1.4"
                  fill="none"
                  strokeLinecap="square"
                >
                  <path d="M10 40 H200" />
                  <path d="M60 90 H240" />
                  <path d="M20 150 H210" />
                  <path d="M60 10 V200" />
                  <path d="M120 0 V140" />
                  <path d="M180 80 V220" />
                  <path d="M20 40 V80 H80 V120 H140" />
                  <path d="M120 140 H180 V180 H240" />
                  <path d="M200 40 V80 H240" />
                  <path d="M80 150 V190 H140" />
                </g>
                <g fill="#67e8f9" opacity="0.85">
                  <circle cx="10" cy="40" r="2.5" />
                  <circle cx="200" cy="40" r="2.5" />
                  <circle cx="60" cy="90" r="2.5" />
                  <circle cx="240" cy="90" r="2.5" />
                  <circle cx="20" cy="150" r="2.5" />
                  <circle cx="210" cy="150" r="2.5" />
                  <circle cx="60" cy="200" r="2.5" />
                  <circle cx="120" cy="140" r="2.5" />
                  <circle cx="180" cy="80" r="2.5" />
                  <circle cx="240" cy="180" r="2.5" />
                  <circle cx="80" cy="120" r="2.5" />
                  <circle cx="140" cy="120" r="2.5" />
                </g>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#pcbPattern)" />
          </svg>
        </div>

        {isPortalRoute ? (
  <RAMeowPortal
  siteConfig={siteConfig}
  portalCards={portalCards}
  files={files}
  uploading={uploading}
  uploadProgress={uploadProgress}
  dragActive={dragActive}
  selectedPreview={selectedPreview}
  searchTerm={searchTerm}
  setSearchTerm={setSearchTerm}
  setDragActive={setDragActive}
  setSelectedPreview={setSelectedPreview}
  fileInputRef={fileInputRef}
  filteredFiles={filteredFiles}
  failedLoginCount={failedLoginCount}
  failedLoginAttempts={failedLoginAttempts}
  selectedFailedLoginKeys={selectedFailedLoginKeys}
  toggleFailedLoginSelection={toggleFailedLoginSelection}
  clearFailedLoginSelection={clearFailedLoginSelection}
  deleteFailedLoginAttempt={deleteFailedLoginAttempt}
  deleteSelectedFailedLoginAttempts={deleteSelectedFailedLoginAttempts}
  loadFailedLoginCount={loadFailedLoginCount}
  loadFailedLoginAttempts={loadFailedLoginAttempts}
  inferPreviewType={inferPreviewType}
  uploadSelectedFile={uploadSelectedFile}
  deleteFile={deleteFile}
  renameFile={renameFile}
/>
) : (
  <PublicSite
    siteConfig={{
      businessName: siteConfig.businessName,
      phoneDisplay: siteConfig.phoneDisplay,
      phoneHref: siteConfig.phoneHref,
      location: siteConfig.location,
      email: siteConfig.email,
      domain: siteConfig.domain,
      logoSrc: siteConfig.logoSrc,
      reviewQrSrc: siteConfig.reviewQrSrc,
    }}
    residentialServices={residentialServices}
    businessFocusCards={businessFocusCards}
    commonProblems={commonProblems}
    trustReasons={trustReasons}
    serviceAreas={serviceAreas}
    reviewStats={reviewStats}
    highlights={highlights}
  />
)}
      </div>
    </>
  );
}
