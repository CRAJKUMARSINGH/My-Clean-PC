import { useState, useEffect, useRef } from "react";

function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? "bg-white/95 backdrop-blur-sm shadow-sm" : "bg-transparent"
      }`}
    >
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <rect x="2" y="3" width="20" height="14" rx="2" />
              <path d="M8 21h8M12 17v4" />
            </svg>
          </div>
          <span className="font-bold text-lg text-gray-900">My Clean PC</span>
        </div>
        <div className="hidden md:flex items-center gap-8">
          <a href="#features" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Features</a>
          <a href="#how-it-works" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">How It Works</a>
          <a href="#download" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Download</a>
        </div>
        <a
          href="#download"
          className="bg-blue-600 text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Free Download
        </a>
      </div>
    </nav>
  );
}

function ScanAnimation() {
  const [progress, setProgress] = useState(0);
  const [scanning, setScanning] = useState(false);
  const [done, setDone] = useState(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const startScan = () => {
    setProgress(0);
    setDone(false);
    setScanning(true);
  };

  useEffect(() => {
    if (!scanning) return;
    intervalRef.current = setInterval(() => {
      setProgress((p) => {
        if (p >= 100) {
          clearInterval(intervalRef.current!);
          setScanning(false);
          setDone(true);
          return 100;
        }
        return p + 2;
      });
    }, 40);
    return () => clearInterval(intervalRef.current!);
  }, [scanning]);

  const issues = [
    { label: "Junk Files", value: "2.4 GB", color: "text-red-500" },
    { label: "Registry Errors", value: "147", color: "text-orange-500" },
    { label: "Startup Items", value: "23", color: "text-yellow-600" },
    { label: "Privacy Traces", value: "891", color: "text-purple-500" },
  ];

  return (
    <div className="bg-gray-900 rounded-2xl p-6 shadow-2xl w-full max-w-sm mx-auto">
      <div className="flex items-center gap-2 mb-5">
        <div className="w-3 h-3 rounded-full bg-red-500" />
        <div className="w-3 h-3 rounded-full bg-yellow-500" />
        <div className="w-3 h-3 rounded-full bg-green-500" />
        <span className="ml-2 text-xs text-gray-400 font-mono">my-clean-pc.exe</span>
      </div>

      {!scanning && !done && (
        <div className="text-center py-6">
          <div className="w-16 h-16 bg-blue-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="1.5">
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.35-4.35" />
            </svg>
          </div>
          <p className="text-gray-300 text-sm mb-4">Ready to scan your PC</p>
          <button
            onClick={startScan}
            className="bg-blue-600 text-white text-sm font-semibold px-6 py-2.5 rounded-lg hover:bg-blue-500 transition-colors"
          >
            Start Scan
          </button>
        </div>
      )}

      {scanning && (
        <div className="py-4">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
            <span className="text-blue-400 text-sm font-mono">Scanning system...</span>
          </div>
          <div className="w-full bg-gray-800 rounded-full h-2 mb-2">
            <div
              className="bg-blue-500 h-2 rounded-full transition-all duration-75"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="flex justify-between text-xs text-gray-500 font-mono">
            <span>Analyzing registry & files</span>
            <span>{progress}%</span>
          </div>
        </div>
      )}

      {done && (
        <div className="py-2">
          <div className="flex items-center gap-2 mb-4">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span className="text-red-400 text-sm font-semibold">Issues Found</span>
          </div>
          <div className="grid grid-cols-2 gap-2 mb-4">
            {issues.map((issue) => (
              <div key={issue.label} className="bg-gray-800 rounded-lg p-3">
                <p className={`text-lg font-bold font-mono ${issue.color}`}>{issue.value}</p>
                <p className="text-xs text-gray-400 mt-0.5">{issue.label}</p>
              </div>
            ))}
          </div>
          <button
            onClick={startScan}
            className="w-full bg-blue-600 text-white text-sm font-semibold py-2.5 rounded-lg hover:bg-blue-500 transition-colors"
          >
            Clean All
          </button>
        </div>
      )}
    </div>
  );
}

function Hero() {
  return (
    <section className="pt-24 pb-20 px-6 bg-gradient-to-br from-slate-50 via-blue-50 to-white min-h-screen flex items-center">
      <div className="max-w-6xl mx-auto w-full">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div>
            <div className="inline-flex items-center gap-2 bg-blue-100 text-blue-700 text-xs font-semibold px-3 py-1.5 rounded-full mb-6">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse" />
              Free & Trusted by 2M+ Users
            </div>
            <h1 className="text-5xl font-extrabold text-gray-900 leading-tight mb-5">
              Make Your PC{" "}
              <span className="text-blue-600">Faster &amp; Cleaner</span>{" "}
              in Minutes
            </h1>
            <p className="text-lg text-gray-500 mb-8 leading-relaxed">
              Remove junk files, fix registry errors, block privacy threats, and
              speed up startup — all with one free tool built for Windows.
            </p>
            <div className="flex flex-wrap gap-3">
              <a
                href="#download"
                className="bg-blue-600 text-white font-semibold px-7 py-3.5 rounded-xl hover:bg-blue-700 transition-colors shadow-lg shadow-blue-200"
              >
                Download Free — Windows
              </a>
              <a
                href="#how-it-works"
                className="bg-white text-gray-700 font-semibold px-7 py-3.5 rounded-xl hover:bg-gray-50 border border-gray-200 transition-colors"
              >
                See How It Works
              </a>
            </div>
            <p className="text-xs text-gray-400 mt-4">
              No ads. No bloatware. 100% free. Windows 10 &amp; 11.
            </p>
          </div>
          <div className="flex justify-center">
            <ScanAnimation />
          </div>
        </div>
      </div>
    </section>
  );
}

const features = [
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="3 6 5 6 21 6" />
        <path d="M19 6l-1 14H6L5 6" />
        <path d="M10 11v6M14 11v6" />
        <path d="M9 6V4h6v2" />
      </svg>
    ),
    color: "bg-red-100 text-red-600",
    title: "Junk File Cleaner",
    desc: "Remove gigabytes of temp files, browser cache, and leftover installers that slow your system down.",
  },
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </svg>
    ),
    color: "bg-blue-100 text-blue-600",
    title: "Registry Fix",
    desc: "Scan and repair broken, corrupt, or obsolete registry entries that cause crashes and slowdowns.",
  },
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
      </svg>
    ),
    color: "bg-yellow-100 text-yellow-600",
    title: "Startup Optimizer",
    desc: "Disable unnecessary startup programs to cut boot time and free up RAM from the moment Windows loads.",
  },
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
        <circle cx="12" cy="12" r="3" />
        <line x1="1" y1="1" x2="23" y2="23" />
      </svg>
    ),
    color: "bg-purple-100 text-purple-600",
    title: "Privacy Cleaner",
    desc: "Erase browsing history, cookies, saved passwords, and traces that put your privacy at risk.",
  },
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="2" y="3" width="20" height="14" rx="2" />
        <path d="M8 21h8M12 17v4" />
      </svg>
    ),
    color: "bg-green-100 text-green-600",
    title: "Disk Analyzer",
    desc: "Visualize what's eating your disk space with a clear breakdown by file type and folder.",
  },
  {
    icon: (
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
      </svg>
    ),
    color: "bg-orange-100 text-orange-600",
    title: "Real-Time Monitor",
    desc: "Watch CPU, RAM, and disk activity in real time to catch performance issues as they happen.",
  },
];

function Features() {
  return (
    <section id="features" className="py-24 px-6 bg-white">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">
            Everything Your PC Needs
          </h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto">
            Six powerful tools in one lightweight app — no technical knowledge required.
          </p>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((f) => (
            <div
              key={f.title}
              className="p-6 rounded-2xl border border-gray-100 hover:border-blue-100 hover:shadow-md transition-all group"
            >
              <div className={`w-11 h-11 rounded-xl flex items-center justify-center mb-4 ${f.color}`}>
                {f.icon}
              </div>
              <h3 className="font-bold text-gray-900 mb-2">{f.title}</h3>
              <p className="text-gray-500 text-sm leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

const steps = [
  {
    num: "01",
    title: "Download & Install",
    desc: "Grab the free installer — under 10 MB, no bundled extras, no account needed.",
  },
  {
    num: "02",
    title: "Run a Full Scan",
    desc: "Hit Scan and let My Clean PC analyze your system in under 2 minutes.",
  },
  {
    num: "03",
    title: "Review & Clean",
    desc: "See exactly what was found, choose what to remove, and clean with one click.",
  },
];

function HowItWorks() {
  return (
    <section id="how-it-works" className="py-24 px-6 bg-slate-50">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">
            Up and Running in 3 Steps
          </h2>
          <p className="text-gray-500 text-lg">
            No configuration. No learning curve. Just a faster PC.
          </p>
        </div>
        <div className="grid md:grid-cols-3 gap-8">
          {steps.map((s, i) => (
            <div key={s.num} className="relative text-center">
              {i < steps.length - 1 && (
                <div className="hidden md:block absolute top-8 left-1/2 w-full h-px bg-blue-100" />
              )}
              <div className="relative inline-flex w-16 h-16 bg-blue-600 text-white rounded-2xl items-center justify-center font-mono font-bold text-lg mb-5 shadow-lg shadow-blue-200">
                {s.num}
              </div>
              <h3 className="font-bold text-gray-900 text-lg mb-2">{s.title}</h3>
              <p className="text-gray-500 text-sm leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

const stats = [
  { value: "2M+", label: "Active Users" },
  { value: "4.8★", label: "Average Rating" },
  { value: "50GB+", label: "Junk Removed Daily" },
  { value: "100%", label: "Free Forever" },
];

function Stats() {
  return (
    <section className="py-16 px-6 bg-blue-600">
      <div className="max-w-5xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
        {stats.map((s) => (
          <div key={s.label}>
            <p className="text-4xl font-extrabold text-white mb-1">{s.value}</p>
            <p className="text-blue-200 text-sm">{s.label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function Download() {
  return (
    <section id="download" className="py-24 px-6 bg-white">
      <div className="max-w-2xl mx-auto text-center">
        <div className="inline-flex w-20 h-20 bg-blue-100 rounded-3xl items-center justify-center mb-6">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4" />
            <polyline points="7 10 12 15 17 10" />
            <line x1="12" y1="15" x2="12" y2="3" />
          </svg>
        </div>
        <h2 className="text-4xl font-extrabold text-gray-900 mb-4">
          Download My Clean PC Free
        </h2>
        <p className="text-gray-500 text-lg mb-8">
          Compatible with Windows 10 and Windows 11. No registration. No credit card.
        </p>
        <a
          href="#download"
          className="inline-block bg-blue-600 text-white font-bold text-lg px-10 py-4 rounded-2xl hover:bg-blue-700 transition-colors shadow-xl shadow-blue-200 mb-6"
        >
          Download Free — Windows
        </a>
        <div className="flex items-center justify-center gap-6 text-sm text-gray-400">
          <span className="flex items-center gap-1.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12" /></svg>
            No ads or bloatware
          </span>
          <span className="flex items-center gap-1.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12" /></svg>
            Under 10 MB install
          </span>
          <span className="flex items-center gap-1.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12" /></svg>
            Instant setup
          </span>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-400 py-10 px-6">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 bg-blue-600 rounded-lg flex items-center justify-center">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <rect x="2" y="3" width="20" height="14" rx="2" />
              <path d="M8 21h8M12 17v4" />
            </svg>
          </div>
          <span className="font-bold text-white">My Clean PC</span>
        </div>
        <p className="text-sm">© {new Date().getFullYear()} My Clean PC. All rights reserved.</p>
        <div className="flex gap-5 text-sm">
          <a href="#" className="hover:text-white transition-colors">Privacy</a>
          <a href="#" className="hover:text-white transition-colors">Terms</a>
          <a href="#" className="hover:text-white transition-colors">Contact</a>
        </div>
      </div>
    </footer>
  );
}

export default function App() {
  return (
    <div className="font-sans">
      <Navbar />
      <Hero />
      <Features />
      <HowItWorks />
      <Stats />
      <Download />
      <Footer />
    </div>
  );
}
