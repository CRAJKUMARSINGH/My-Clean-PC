import { useState, useEffect, useRef } from "react";

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);
  return (
    <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? "bg-white/95 backdrop-blur-sm shadow-sm" : "bg-transparent"}`}>
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          </div>
          <span className="font-bold text-lg text-gray-900">My Clean PC</span>
        </div>
        <div className="hidden md:flex items-center gap-8">
          <a href="#what-it-cleans" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">What It Cleans</a>
          <a href="#safety" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Safety</a>
          <a href="#download" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Download</a>
        </div>
        <a href="#download" className="bg-blue-600 text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
          Free Download
        </a>
      </div>
    </nav>
  );
}

function ScanDemo() {
  const [phase, setPhase] = useState<"idle"|"scanning"|"done">("idle");
  const [progress, setProgress] = useState(0);
  const [currentItem, setCurrentItem] = useState("");
  const ref = useRef<ReturnType<typeof setInterval>|null>(null);

  const items = [
    "Cursor cache…", "Windsurf logs…", "Chrome cache…",
    "Edge history…", "Brave cookies…", "Firefox cache…",
    "%TEMP% files…", "Windows Prefetch…", "Recycle Bin…",
    "Windows Update cache…", "Thumbnail cache…", "DNS cache…",
  ];

  const start = () => {
    setProgress(0); setPhase("scanning"); setCurrentItem(items[0]);
    let i = 0;
    ref.current = setInterval(() => {
      setProgress(p => {
        const next = p + 1.4;
        const idx = Math.floor((next / 100) * items.length);
        setCurrentItem(items[Math.min(idx, items.length - 1)]);
        if (next >= 100) {
          clearInterval(ref.current!);
          setPhase("done");
          return 100;
        }
        return next;
      });
    }, 35);
  };

  const reset = () => { clearInterval(ref.current!); setPhase("idle"); setProgress(0); };

  const results = [
    { label: "AI IDE Caches", value: "9 apps", color: "text-violet-400" },
    { label: "Browser Data", value: "8 browsers", color: "text-blue-400" },
    { label: "Temp & Junk", value: "~2.1 GB", color: "text-red-400" },
    { label: "System Caches", value: "5 types", color: "text-orange-400" },
  ];

  return (
    <div className="bg-gray-900 rounded-2xl p-5 shadow-2xl w-full max-w-sm mx-auto font-mono text-sm">
      <div className="flex items-center gap-1.5 mb-4">
        <div className="w-3 h-3 rounded-full bg-red-500"/>
        <div className="w-3 h-3 rounded-full bg-yellow-500"/>
        <div className="w-3 h-3 rounded-full bg-green-500"/>
        <span className="ml-2 text-xs text-gray-500">my-clean-pc.bat</span>
      </div>

      {phase === "idle" && (
        <div className="text-center py-6">
          <div className="w-14 h-14 bg-blue-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          </div>
          <p className="text-gray-400 mb-5 text-xs leading-relaxed">
            Scans AI IDE caches, browsers,<br/>temp files, prefetch, DNS &amp; more
          </p>
          <button onClick={start} className="bg-blue-600 text-white text-xs font-bold px-6 py-2.5 rounded-lg hover:bg-blue-500 transition-colors">
            Run Scan Demo
          </button>
        </div>
      )}

      {phase === "scanning" && (
        <div className="py-3">
          <div className="flex items-center gap-2 mb-3">
            <span className="w-2 h-2 rounded-full bg-blue-400 animate-pulse"/>
            <span className="text-blue-400 text-xs">Scanning…</span>
          </div>
          <div className="text-gray-500 text-xs mb-3 h-4">{currentItem}</div>
          <div className="w-full bg-gray-800 rounded-full h-1.5 mb-1">
            <div className="bg-blue-500 h-1.5 rounded-full transition-all duration-75" style={{width:`${progress}%`}}/>
          </div>
          <div className="flex justify-between text-xs text-gray-600 mt-1">
            <span>Analyzing system</span><span>{Math.round(progress)}%</span>
          </div>
        </div>
      )}

      {phase === "done" && (
        <div className="py-1">
          <div className="flex items-center gap-2 mb-3">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#f87171" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span className="text-red-400 text-xs font-bold">Junk Found — Ready to Clean</span>
          </div>
          <div className="grid grid-cols-2 gap-2 mb-4">
            {results.map(r => (
              <div key={r.label} className="bg-gray-800 rounded-lg p-2.5">
                <p className={`text-base font-bold ${r.color}`}>{r.value}</p>
                <p className="text-gray-500 text-xs mt-0.5">{r.label}</p>
              </div>
            ))}
          </div>
          <div className="bg-green-900/40 border border-green-700/50 rounded-lg p-2.5 mb-3 text-xs text-green-400">
            ✓ Passwords never touched &nbsp;·&nbsp; ✓ Downloads safe
          </div>
          <button onClick={reset} className="w-full bg-gray-700 text-gray-300 text-xs py-2 rounded-lg hover:bg-gray-600 transition-colors">
            Reset Demo
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
              <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"/>
              Free Windows Batch &amp; PowerShell Cleaner
            </div>
            <h1 className="text-5xl font-extrabold text-gray-900 leading-tight mb-5">
              One script.<br/>
              <span className="text-blue-600">Nine categories</span><br/>
              of junk gone.
            </h1>
            <p className="text-lg text-gray-500 mb-4 leading-relaxed">
              My Clean PC is a lightweight Windows batch script that wipes AI IDE caches, browser history, temp files, prefetch, DNS, and more — without ever touching your passwords or downloads.
            </p>
            <p className="text-sm text-gray-400 mb-8 italic">Designed for Priyanka ❤️</p>
            <div className="flex flex-wrap gap-3">
              <a href={`${BASE}/my-clean-pc.bat`} download className="bg-blue-600 text-white font-semibold px-7 py-3.5 rounded-xl hover:bg-blue-700 transition-colors shadow-lg shadow-blue-200 flex items-center gap-2">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Download .bat
              </a>
              <a href={`${BASE}/my-clean-pc.ps1`} download className="bg-white text-gray-700 font-semibold px-7 py-3.5 rounded-xl hover:bg-gray-50 border border-gray-200 transition-colors flex items-center gap-2">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Download .ps1
              </a>
            </div>
            <p className="text-xs text-gray-400 mt-4">Windows 10 &amp; 11 · No install · No account · Open source batch script</p>
          </div>
          <div className="flex justify-center">
            <ScanDemo />
          </div>
        </div>
      </div>
    </section>
  );
}

const categories = [
  {
    icon: "🤖",
    color: "bg-violet-50 border-violet-100",
    iconBg: "bg-violet-100 text-violet-700",
    title: "AI IDE App Caches",
    count: "9 apps",
    items: ["Cursor", "Windsurf", "Kiro", "Trae AI", "Warp", "Devin", "Qoder", "Antigravity", "Genspark"],
    desc: "Removes cache, logs, and temp data left behind by AI coding tools — often several GB over time.",
  },
  {
    icon: "🌐",
    color: "bg-blue-50 border-blue-100",
    iconBg: "bg-blue-100 text-blue-700",
    title: "Browser Cache & History",
    count: "8 browsers",
    items: ["Chrome", "Edge", "Brave", "Vivaldi", "Opera", "Firefox", "Yandex", "Genspark Browser"],
    desc: "Clears cache, cookies, history, session data, and local storage. Passwords are always skipped.",
  },
  {
    icon: "🗂️",
    color: "bg-orange-50 border-orange-100",
    iconBg: "bg-orange-100 text-orange-700",
    title: "Temp Files",
    count: "2 locations",
    items: ["%TEMP% (user temp folder)", "C:\\Windows\\Temp (system temp)"],
    desc: "Deletes temporary files left by installers, apps, and Windows itself.",
  },
  {
    icon: "⚡",
    color: "bg-yellow-50 border-yellow-100",
    iconBg: "bg-yellow-100 text-yellow-700",
    title: "Windows Prefetch",
    count: "2 locations",
    items: ["C:\\Windows\\Prefetch (*.pf files)", "Recent Activity & File History"],
    desc: "Removes prefetch files and recent file/folder shortcuts from Explorer.",
  },
  {
    icon: "🗑️",
    color: "bg-red-50 border-red-100",
    iconBg: "bg-red-100 text-red-700",
    title: "Recycle Bin",
    count: "All drives",
    items: ["Empties $Recycle.Bin on all drives"],
    desc: "Permanently deletes files sitting in the Recycle Bin across every drive.",
  },
  {
    icon: "🔄",
    color: "bg-green-50 border-green-100",
    iconBg: "bg-green-100 text-green-700",
    title: "Windows Update Cache",
    count: "2 locations",
    items: ["SoftwareDistribution\\Download", "SoftwareDistribution\\DataStore\\Logs"],
    desc: "Frees space taken by downloaded but already-installed Windows update files.",
  },
  {
    icon: "🖼️",
    color: "bg-pink-50 border-pink-100",
    iconBg: "bg-pink-100 text-pink-700",
    title: "Thumbnail & Icon Cache",
    count: "Explorer cache",
    items: ["thumbcache_*.db", "iconcache_*.db"],
    desc: "Clears stale thumbnail and icon databases so Explorer rebuilds them fresh.",
  },
  {
    icon: "📋",
    color: "bg-slate-50 border-slate-100",
    iconBg: "bg-slate-100 text-slate-700",
    title: "Windows Event Logs",
    count: "4 logs",
    items: ["Application log", "System log", "Security log", "Setup log"],
    desc: "Wipes event log files that accumulate and slow down Event Viewer.",
  },
  {
    icon: "🌍",
    color: "bg-teal-50 border-teal-100",
    iconBg: "bg-teal-100 text-teal-700",
    title: "DNS Cache",
    count: "System-wide",
    items: ["ipconfig /flushdns"],
    desc: "Flushes the DNS resolver cache to fix stale or broken domain lookups.",
  },
];

function WhatItCleans() {
  return (
    <section id="what-it-cleans" className="py-24 px-6 bg-white">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">What It Actually Cleans</h2>
          <p className="text-gray-500 text-lg max-w-xl mx-auto">
            Nine categories, fully transparent. Every path the script touches is listed below.
          </p>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {categories.map((c) => (
            <div key={c.title} className={`rounded-2xl border p-5 ${c.color}`}>
              <div className="flex items-start justify-between mb-3">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg ${c.iconBg}`}>
                  {c.icon}
                </div>
                <span className="text-xs font-semibold text-gray-400 bg-white/80 px-2 py-1 rounded-full">{c.count}</span>
              </div>
              <h3 className="font-bold text-gray-900 mb-1.5">{c.title}</h3>
              <p className="text-gray-500 text-xs leading-relaxed mb-3">{c.desc}</p>
              <ul className="space-y-1">
                {c.items.map((item) => (
                  <li key={item} className="flex items-center gap-1.5 text-xs text-gray-600">
                    <span className="text-gray-400">›</span>
                    <span className="font-mono">{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Safety() {
  const neverTouched = [
    { icon: "🔑", label: "Login Data / Saved Passwords", detail: "Chrome, Edge, Brave, Vivaldi, Opera, Yandex — Login Data files are always skipped" },
    { icon: "📁", label: "Downloads Folder", detail: "Your %USERPROFILE%\\Downloads is never read or modified" },
    { icon: "🗝️", label: "Firefox Master Password (key4.db)", detail: "key4.db — where Firefox stores your passwords — is explicitly skipped" },
    { icon: "📸", label: "Photos, Documents, Videos", detail: "The script only targets known cache/temp directories, not your personal files" },
  ];

  return (
    <section id="safety" className="py-24 px-6 bg-slate-50">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">What It Will <span className="text-green-600">Never</span> Touch</h2>
          <p className="text-gray-500 text-lg">Safety isn't a checkbox — every exclusion is hardcoded into the script.</p>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          {neverTouched.map((item) => (
            <div key={item.label} className="bg-white border border-green-100 rounded-2xl p-5 flex gap-4">
              <div className="text-2xl mt-0.5">{item.icon}</div>
              <div>
                <p className="font-bold text-gray-900 mb-1">{item.label}</p>
                <p className="text-gray-500 text-sm leading-relaxed">{item.detail}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="mt-8 bg-green-50 border border-green-200 rounded-2xl p-6 text-center">
          <p className="text-green-800 font-semibold mb-1">100% Open Source</p>
          <p className="text-green-700 text-sm">The scripts are plain text — open them in Notepad before running and read every line yourself. No hidden code, no executables, no network calls.</p>
        </div>
      </div>
    </section>
  );
}

function HowToRun() {
  const steps = [
    { num: "01", title: "Download the script", desc: "Grab the .bat (double-click) or .ps1 (PowerShell) version below." },
    { num: "02", title: "Run as Administrator", desc: "Right-click the file → \"Run as administrator\" so it can clear system temp folders." },
    { num: "03", title: "Watch it clean", desc: "A terminal window shows each category as it runs. Takes under 2 minutes." },
  ];
  return (
    <section className="py-24 px-6 bg-white">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">How to Run It</h2>
          <p className="text-gray-500 text-lg">No installation. No account. No internet connection needed.</p>
        </div>
        <div className="grid md:grid-cols-3 gap-8">
          {steps.map((s) => (
            <div key={s.num} className="text-center">
              <div className="inline-flex w-16 h-16 bg-blue-600 text-white rounded-2xl items-center justify-center font-mono font-bold text-lg mb-5 shadow-lg shadow-blue-200">
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

function Download() {
  return (
    <section id="download" className="py-24 px-6 bg-gradient-to-br from-blue-600 to-blue-700">
      <div className="max-w-2xl mx-auto text-center">
        <h2 className="text-4xl font-extrabold text-white mb-4">Download My Clean PC</h2>
        <p className="text-blue-100 text-lg mb-10">
          Pick the version that suits you. Both scripts do exactly the same cleaning.
        </p>
        <div className="grid sm:grid-cols-2 gap-4 mb-10">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
            <div className="text-3xl mb-3">🦇</div>
            <h3 className="text-white font-bold text-lg mb-1">Batch Script (.bat)</h3>
            <p className="text-blue-100 text-sm mb-5">Easiest — just double-click and run as admin. Works on every Windows PC.</p>
            <a
              href={`${BASE}/my-clean-pc.bat`}
              download="my-clean-pc.bat"
              className="inline-flex items-center gap-2 bg-white text-blue-700 font-bold px-6 py-3 rounded-xl hover:bg-blue-50 transition-colors w-full justify-center"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download .bat
            </a>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
            <div className="text-3xl mb-3">⚙️</div>
            <h3 className="text-white font-bold text-lg mb-1">PowerShell Script (.ps1)</h3>
            <p className="text-blue-100 text-sm mb-5">More detailed output with colour-coded progress. Requires PowerShell execution policy bypass.</p>
            <a
              href={`${BASE}/my-clean-pc.ps1`}
              download="my-clean-pc.ps1"
              className="inline-flex items-center gap-2 bg-white text-blue-700 font-bold px-6 py-3 rounded-xl hover:bg-blue-50 transition-colors w-full justify-center"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download .ps1
            </a>
          </div>
        </div>
        <div className="bg-white/10 rounded-xl p-4 text-left">
          <p className="text-blue-100 text-xs font-mono leading-relaxed">
            <span className="text-blue-300"># To run PowerShell script:</span><br/>
            PowerShell -ExecutionPolicy Bypass -File my-clean-pc.ps1
          </p>
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
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          </div>
          <span className="font-bold text-white">My Clean PC</span>
          <span className="text-gray-600 text-xs ml-2">Designed for Priyanka ❤️</span>
        </div>
        <p className="text-sm">© {new Date().getFullYear()} My Clean PC · Free Windows Cleaner</p>
        <div className="flex gap-5 text-sm">
          <a href="#what-it-cleans" className="hover:text-white transition-colors">What It Cleans</a>
          <a href="#safety" className="hover:text-white transition-colors">Safety</a>
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
      <WhatItCleans />
      <Safety />
      <HowToRun />
      <Download />
      <Footer />
    </div>
  );
}
