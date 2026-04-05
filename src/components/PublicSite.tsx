import React from "react";

type InfoCard = {
  title: string;
  description: string;
};

type SiteConfig = {
  businessName: string;
  phoneDisplay: string;
  phoneHref: string;
  location: string;
  email: string;
  domain: string;
  logoSrc: string;
  reviewQrSrc: string;
};

type PublicSiteProps = {
  siteConfig: SiteConfig;
  residentialServices: InfoCard[];
  businessFocusCards: InfoCard[];
  commonProblems: InfoCard[];
  trustReasons: InfoCard[];
  serviceAreas: string[];
  reviewStats: {
    rating: string;
    reviewLabel: string;
  };
  highlights: string[];
};

function ServiceCard({ title, description }: InfoCard) {
  return (
    <div className="card light">
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

function DarkInfoCard({ title, description }: InfoCard) {
  return (
    <div className="card dark">
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

export default function PublicSite({
  siteConfig,
  residentialServices,
  businessFocusCards,
  commonProblems,
  trustReasons,
  serviceAreas,
  reviewStats,
  highlights,
}: PublicSiteProps) {
  return (
    <>
      <header className="header">
        <div className="container header-inner">
          <div className="header-top">
            <div className="logo-row">
              <img src={siteConfig.logoSrc} alt={siteConfig.businessName} className="logo" />
              <div>
                <span className="brand-name">{siteConfig.businessName}</span>
                <span className="sub-brand">Repair Shop + Business IT Solutions</span>
              </div>
            </div>
            <a href={siteConfig.phoneHref} className="button-small">Call {siteConfig.phoneDisplay}</a>
          </div>

          <nav className="nav">
            <a href="#services">Services</a>
            <a href="#business">Business IT</a>
            <a href="#reviews">Reviews</a>
            <a href="#why-choose-us">Why Choose Us</a>
            <a href="#contact">Contact</a>
          </nav>
        </div>
      </header>

      <section className="hero">
        <div className="container hero-inner">
          <div className="hero-grid">
            <div>
              <div className="badge-row">
                <div className="pill"><span className="dot" />Harlingen, Texas • Serving the Rio Grande Valley</div>
              </div>

              <div className="badge-row">
                <div className="meta-pill">★★★★★ Rated 4.9–5.0</div>
                <div className="meta-pill">Same-Day Service Available</div>
                <div className="meta-pill">Free Basic Diagnostics</div>
              </div>

              <h1 className="hero-title">
                Professional Computer Repair
                <span className="hero-accent">&amp; Business IT Solutions</span>
              </h1>

              <p className="hero-text">
                Fast, dependable support for homes and businesses across Harlingen and the Rio Grande Valley. From virus removal and laptop repair to custom PCs, upgrades, and small business IT, {siteConfig.businessName} delivers practical solutions that keep your technology working.
              </p>

              <div className="hero-buttons">
                <a href={siteConfig.phoneHref} className="button-primary">Call {siteConfig.phoneDisplay}</a>
                <a href="#contact" className="button-ghost">Schedule Service</a>
              </div>

              <div className="hero-links">
                <a href="#services" className="button-mini">Services</a>
                <a href="#business" className="button-mini">Business IT</a>
                <a href="#reviews" className="button-mini">Reviews</a>
              </div>

              <div className="hero-highlights">
                {highlights.map((item) => (
                  <div key={item} className="highlight-card">{item}</div>
                ))}
              </div>
            </div>

            <div>
              <div className="panel">
                <div className="panel-header">
                  <div>
                    <p className="panel-label">Trusted Local Technology Support</p>
                    <h2 className="panel-title">Fast help for common repair issues</h2>
                  </div>
                  <div className="panel-call-box">
                    <div className="panel-call-label">Call or Text</div>
                    <div className="panel-call-num">{siteConfig.phoneDisplay}</div>
                  </div>
                </div>

                <p className="panel-text">
                  Virus removal, broken screens, slow computers, upgrade work, and business IT support handled by an experienced local technician.
                </p>

                <div className="service-list-box">
                  <p className="service-list-title">Popular Requests</p>
                  <div className="service-list">
                    <div className="service-item">Virus &amp; malware cleanup</div>
                    <div className="service-item">Laptop screen replacement</div>
                    <div className="service-item">SSD &amp; memory upgrades</div>
                    <div className="service-item">Small business workstation support</div>
                  </div>
                </div>
              </div>

              <div className="three-stats" style={{ marginTop: 20 }}>
                <div className="stat-card">
                  <div className="stat-big">25+</div>
                  <div className="stat-label">Years Experience</div>
                </div>
                <div className="stat-card">
                  <div className="stat-big">RGV</div>
                  <div className="stat-label">Local Service Area</div>
                </div>
                <div className="stat-card">
                  <div className="stat-big">★★★★★</div>
                  <div className="stat-label">Trusted Reviews</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="emergency">
        <div className="container emergency-inner">
          <div>
            <p className="emergency-title">Emergency &amp; Same-Day Service</p>
            <p className="emergency-text">Some repairs may be available for same-day service depending on parts, workload, and issue type.</p>
          </div>
          <a href={siteConfig.phoneHref} className="button-ghost">Call Now: {siteConfig.phoneDisplay}</a>
        </div>
      </section>

      <section id="services" className="section">
        <div className="container">
          <p className="section-title-small">Services</p>
          <h2 className="section-title">Computer Repair Services</h2>
          <div className="grid4">
            {residentialServices.map((service) => (
              <ServiceCard key={service.title} title={service.title} description={service.description} />
            ))}
          </div>
        </div>
      </section>

      <section id="business" className="section-muted">
        <div className="container">
          <p className="section-title-small">Business IT Support</p>
          <h2 className="section-title">Small Business IT Solutions</h2>
          <p className="section-text">Support for office computers, networks, security, backups, and workstation deployment for local businesses that need dependable technology help.</p>
          <div className="grid3">
            {businessFocusCards.map((card) => (
              <DarkInfoCard key={card.title} title={card.title} description={card.description} />
            ))}
          </div>
        </div>
      </section>

      <section className="section-dark">
        <div className="container">
          <p className="section-title-small">Custom Systems &amp; Upgrades</p>
          <h2 className="section-title">Custom PCs, Performance Builds, and Upgrades</h2>
          <p className="section-text">Need a new custom system or want to improve the performance of an older computer? Get help with gaming PCs, business workstations, SSD upgrades, memory upgrades, and other hardware improvements.</p>
          <div className="grid3">
            <DarkInfoCard title="Custom PC Builds" description="Custom desktops built for reliability, gaming, creative work, or general home and office use." />
            <DarkInfoCard title="Performance Upgrades" description="SSD, RAM, graphics, and component upgrades to improve speed, stability, and overall usability." />
            <DarkInfoCard title="Business Workstations" description="Purpose-built systems for office productivity, accounting, design, and other professional workloads." />
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <p className="section-title-small">Common Computer Problems</p>
          <h2 className="section-title">Problems We Fix Every Day</h2>
          <p className="section-text">Many computer problems start small but quickly become frustrating. If your system is experiencing any of the issues below, professional diagnostics can often restore performance and prevent data loss.</p>
          <div className="grid3">
            {commonProblems.map((problem) => (
              <ServiceCard key={problem.title} title={problem.title} description={problem.description} />
            ))}
          </div>
        </div>
      </section>

      <section id="reviews" className="section-muted">
        <div className="container">
          <div className="reviews-grid">
            <div>
              <p className="section-title-small">Google Reviews</p>
              <h2 className="section-title">Trusted by Local Customers</h2>
              <div className="rating-row">
                <div className="rating-big">{reviewStats.rating}</div>
                <div>
                  <div className="stars">★★★★★</div>
                  <p className="small-text" style={{ marginTop: 4 }}>{reviewStats.reviewLabel}</p>
                </div>
              </div>
              <p className="section-text" style={{ marginTop: 20 }}>
                Read what local customers are saying about {siteConfig.businessName} and see why many clients trust the business for computer repairs, upgrades, and IT support.
              </p>
              <div className="review-actions">
                <a href="https://www.google.com/search?q=RAM%27S+COMPUTER+REPAIR+Harlingen+TX" target="_blank" rel="noreferrer" className="button-primary review-button" aria-label="Read Google reviews for RAM'S COMPUTER REPAIR">
                  <span className="google-badge">G</span>
                  <span>Read Google Reviews</span>
                  <span className="review-stars-inline">★★★★★</span>
                </a>
                <div className="meta-pill">Rated highly by RGV customers</div>
              </div>
            </div>

            <div className="reviews-right">
              <div className="grid2" style={{ marginTop: 0 }}>
                <DarkInfoCard title="Professional Service" description="Customers value clear communication, honest recommendations, and practical solutions for both home and business systems." />
                <DarkInfoCard title="Reliable Repairs" description="From malware cleanup to hardware upgrades, many clients return for dependable repair work and trusted advice." />
                <DarkInfoCard title="Local Reputation" description="Serving Harlingen and the surrounding RGV with personalized support instead of one-size-fits-all service." />
                <DarkInfoCard title="Business-Friendly Support" description="Small business clients benefit from responsive assistance, workstation support, and ongoing technology help." />
              </div>
              <div className="qr-box">
                <div className="qr-label">Scan Reviews</div>
                <img src={siteConfig.reviewQrSrc} alt="Google review QR code" className="qr-image" />
                <p className="small-text" style={{ marginTop: 12 }}>Click the button above to read current Google reviews.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="why-choose-us" className="section">
        <div className="container">
          <p className="section-title-small">Why Choose RAM'S COMPUTER REPAIR</p>
          <h2 className="section-title">Local Service You Can Count On</h2>
          <p className="section-text">Clear communication, practical repair recommendations, and dependable support for both home users and small businesses across the Rio Grande Valley.</p>
          <div className="grid4">
            {trustReasons.map((reason) => (
              <DarkInfoCard key={reason.title} title={reason.title} description={reason.description} />
            ))}
          </div>
        </div>
      </section>

      <section id="service-area" className="section-dark">
        <div className="container">
          <p className="section-title-small">Service Area</p>
          <h2 className="section-title">Serving Harlingen and the Rio Grande Valley</h2>
          <p className="section-text">Computer repair and small business IT support for customers in Harlingen and surrounding RGV communities.</p>

          <div style={{ marginTop: 28, borderRadius: 18, overflow: "hidden", border: "1px solid rgba(255,255,255,.1)" }}>
            <iframe
              title="Harlingen Texas Service Area Map"
              src="https://www.google.com/maps?q=Harlingen%20Texas&output=embed"
              width="100%"
              height="380"
              style={{ border: 0 }}
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
            />
          </div>

          <div className="chips" style={{ marginTop: 22 }}>
            {serviceAreas.map((area) => (
              <span key={area} className="chip">{area}</span>
            ))}
          </div>
        </div>
      </section>

      <section id="contact" className="section" style={{ paddingBottom: 80 }}>
        <div className="container">
          <div className="cta-box">
            <div className="cta-grid">
              <div>
                <p className="section-title-small">Schedule Service</p>
                <h2 className="section-title">Need help with your computer or business IT?</h2>
                <p className="section-text">Call or text today for appointment availability and free basic diagnostics.</p>
              </div>
              <div className="cta-buttons">
                <a href={siteConfig.phoneHref} className="button-ghost">{siteConfig.phoneDisplay}</a>
                <a href={`mailto:${siteConfig.email}`} className="button-ghost">Call or Email for Appointment</a>
              </div>
            </div>
          </div>
        </div>
      </section>

      <a href={siteConfig.phoneHref} className="floating-call">Call Now</a>
    </>
  );
}
