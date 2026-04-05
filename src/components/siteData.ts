export type InfoCard = {
  title: string;
  description: string;
};

export type SiteConfig = {
  businessName: string;
  phoneDisplay: string;
  phoneHref: string;
  location: string;
  email: string;
  domain: string;
  logoSrc: string;
  reviewQrSrc: string;
  socialTitle: string;
  socialDescription: string;
  portalPath: string;
};

export const siteConfig = (logoSrc: string, reviewQrSrc: string): SiteConfig => ({
  businessName: "RAM'S COMPUTER REPAIR",
  phoneDisplay: "956-244-5094",
  phoneHref: "tel:9562445094",
  location: "Harlingen, Texas",
  email: "Ram@RamsComputerRepair.Net",
  domain: "https://www.ramscomputerrepair.net",
  logoSrc,
  reviewQrSrc,
  socialTitle: "RAM'S COMPUTER REPAIR | Computer Repair & Business IT Solutions",
  socialDescription:
    "Professional computer repair, virus removal, upgrades, laptop repair, custom PCs, and small business IT support in Harlingen and the Rio Grande Valley.",
  portalPath: "/RAMeow",
});

export const residentialServices: InfoCard[] = [
  {
    title: "Virus & Malware Removal",
    description:
      "Professional removal of viruses, spyware, ransomware, browser hijackers, and other malicious software that slow down your system or compromise your personal data.",
  },
  {
    title: "Laptop & Desktop Repair",
    description:
      "Diagnosis and repair of common hardware and software problems including overheating systems, power issues, boot failures, and failing components.",
  },
  {
    title: "Data Recovery",
    description:
      "Recovery of lost documents, photos, and important files from damaged drives, corrupted systems, or accidental deletion whenever possible.",
  },
  {
    title: "Hardware Upgrades (SSD / RAM)",
    description:
      "Upgrade older systems with solid-state drives and additional memory to dramatically improve boot times, responsiveness, and overall performance.",
  },
  {
    title: "Windows Troubleshooting",
    description:
      "Fix Windows errors, update problems, driver conflicts, startup failures, and other operating system issues that prevent your computer from running properly.",
  },
  {
    title: "Laptop Screen Replacement",
    description:
      "Replacement of cracked, flickering, dim, or completely black laptop displays using compatible high-quality replacement screens.",
  },
  {
    title: "System Tune-Ups & Optimization",
    description:
      "Comprehensive cleanup and optimization to remove unnecessary software, correct configuration problems, and restore fast system performance.",
  },
  {
    title: "Custom PC Builds",
    description:
      "Design and assembly of custom desktop systems tailored for reliability, performance, gaming, creative work, or everyday computing.",
  },
  {
    title: "Gaming & Performance PC Builds",
    description:
      "High-performance systems built for modern games, streaming, and demanding applications using trusted components and proper cooling.",
  },
  {
    title: "Security Hardening & Protection",
    description:
      "Strengthen system security with proper configuration, malware protection, safe browsing practices, and protection against common threats.",
  },
  {
    title: "Premium Antivirus Installation",
    description:
      "Installation and configuration of trusted antivirus and endpoint protection solutions to help prevent malware infections and security threats.",
  },
];

export const businessFocusCards: InfoCard[] = [
  {
    title: "Managed Support",
    description:
      "Reliable help for daily technical issues, workstation problems, and routine maintenance for small offices.",
  },
  {
    title: "Network & Security",
    description:
      "Support for routers, wireless networking, endpoint protection, backups, and basic office security needs.",
  },
  {
    title: "Upgrades & Deployment",
    description:
      "New computer setup, workstation replacement, software configuration, and hardware upgrades for growing businesses.",
  },
];

export const serviceAreas: string[] = [
  "Harlingen",
  "San Benito",
  "Brownsville",
  "McAllen",
  "Rio Grande Valley",
];

export const commonProblems: InfoCard[] = [
  {
    title: "Computer Running Slow",
    description:
      "Slow startup, lagging programs, or freezing systems are often caused by malware, failing drives, or outdated hardware.",
  },
  {
    title: "Virus & Malware Infections",
    description:
      "Popups, browser redirects, and suspicious activity are common signs of malware infections that require professional removal.",
  },
  {
    title: "Laptop Screen Damage",
    description:
      "Cracked displays, flickering screens, or black displays can often be repaired with professional screen replacement.",
  },
  {
    title: "Computer Won't Start",
    description:
      "Boot failures, power issues, and operating system errors are common problems that can often be repaired without replacing the entire system.",
  },
  {
    title: "Data Recovery",
    description:
      "Lost documents, photos, or important files may still be recoverable from failing or damaged storage devices.",
  },
  {
    title: "Upgrade & Performance Issues",
    description:
      "Older systems can often be dramatically improved with SSD upgrades, memory increases, and system optimization.",
  },
];

export const trustReasons: InfoCard[] = [
  {
    title: "25+ Years of Experience",
    description:
      "Decades of hands-on repair and IT support experience serving residential and business customers across the Rio Grande Valley.",
  },
  {
    title: "Free Basic Diagnostics",
    description:
      "Straightforward troubleshooting to identify common issues and recommend practical repair options before major work begins.",
  },
  {
    title: "Local & Dependable",
    description:
      "Local service means clearer communication, faster response, and support from a real technician who understands the needs of RGV customers.",
  },
  {
    title: "Business & Residential Support",
    description:
      "From home computers to office workstations and small business networks, service is tailored to the system and the client.",
  },
];

export const reviewStats = {
  rating: "4.9–5.0",
  reviewLabel: "Highly Rated by Local Customers",
};

export const highlights: string[] = [
  "25+ Years Experience",
  "Free Basic Diagnostics",
  "Same-Day Service Available",
  "Residential & Business Support",
];
