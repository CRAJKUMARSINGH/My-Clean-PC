import { useState, useEffect, useRef } from "react";

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

const DL = (file: string) => `${BASE}/${file}`;

/* ─── shared icon helpers ─────────────────────────────────────────── */
function DownloadIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
      <polyline points="7 10 12 15 17 10"/>
      <line x1="12" y1="15" x2="12" y2="3"/>
    </svg>
  );
}

/* ─── Navbar ──────────────────────────────────────────────────────── */
function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);
  return (
    <header className={`fixed top-0 inset-x-0 z-50 transition-all duration-500 ${scrolled ? "bg-white/90 backdrop-blur border-b border-gray-100 shadow-sm" : ""}`}>
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#" className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center shadow-sm">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>
            </svg>
          </div>
          <span className="font-semibold text-gray-900 tracking-tight">My Clean PC</span>
        </a>
        <nav className="hidden md:flex items-center gap-8 text-sm text-gray-500">
          <a href="#auto-clean" className="hover:text-gray-900 transition-colors">Auto-Clean</a>
          <a href="#what-it-cleans" className="hover:text-gray-900 transition-colors">What It Cleans</a>
          <a href="#safety" className="hover:text-gray-900 transition-colors">Safety</a>
          <a href="#download" className="hover:text-gray-900 transition-colors">Download</a>
        </nav>
        <a href="#download" className="text-sm font-medium bg-blue-600 text-white px-4 py-2 rounded-full hover:bg-blue-700 transition-colors shadow-sm">
          Download Free
        </a>
      </div>
    </header>
  );
}

/* ─── Terminal scan demo ──────────────────────────────────────────── */
function ScanDemo() {
  const [phase, setPhase] = useState<"idle" | "scanning" | "done">("idle");
  const [progress, setProgress] = useState(0);
  const [line, setLine] = useState("");
  const ref = useRef<ReturnType<typeof setInterval> | null>(null);

  const lines = [
    "Cursor\\Cache…", "Windsurf\\logs…", "Chrome\\Cache…",
    "Edge\\Cache…", "Brave\\Cache…", "Firefox cache2…",
    "%TEMP%\\*…", "C:\\Windows\\Temp…", "$Recycle.Bin…",
    "SoftwareDistribution…", "thumbcache_*.db…", "DNS cache…",
  ];

  const start = () => {
    setProgress(0); setPhase("scanning"); setLine(lines[0]);
    ref.current = setInterval(() => {
      setProgress(p => {
        const next = Math.min(p + 1.6, 100);
        setLine(lines[Math.min(Math.floor((next / 100) * lines.length), lines.length - 1)]);
        if (next >= 100) { clearInterval(ref.current!); setPhase("done"); }
        return next;
      });
    }, 38);
  };

  const reset = () => { clearInterval(ref.current!); setPhase("idle"); setProgress(0); };

  return (
    <div className="w-full max-w-xs bg-[#0d1117] rounded-2xl overflow-hidden shadow-2xl ring-1 ring-white/10 font-mono text-xs">
      {/* window bar */}
      <div className="flex items-center gap-1.5 px-4 py-3 bg-[#161b22] border-b border-white/5">
        <span className="w-2.5 h-2.5 rounded-full bg-red-500/80"/>
        <span className="w-2.5 h-2.5 rounded-full bg-yellow-400/80"/>
        <span className="w-2.5 h-2.5 rounded-full bg-green-400/80"/>
        <span className="ml-2 text-gray-500 text-[10px]">my-clean-pc.bat</span>
      </div>

      <div className="p-5">
        {phase === "idle" && (
          <div className="text-center py-8">
            <div className="w-12 h-12 rounded-full bg-blue-500/15 flex items-center justify-center mx-auto mb-4">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            </div>
            <p className="text-gray-400 mb-5 leading-relaxed text-[11px]">Scans 9 categories — AI IDEs,<br/>browsers, temp files &amp; more</p>
            <button onClick={start} className="bg-blue-600 hover:bg-blue-500 text-white text-[11px] font-semibold px-5 py-2 rounded-lg transition-colors">
              Run Demo
            </button>
          </div>
        )}

        {phase === "scanning" && (
          <div className="py-4">
            <div className="flex items-center gap-2 mb-3">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse"/>
              <span className="text-blue-400 text-[11px]">Scanning…</span>
            </div>
            <p className="text-gray-500 text-[10px] h-3 mb-3 truncate">{line}</p>
            <div className="h-1 rounded-full bg-white/5 mb-1 overflow-hidden">
              <div className="h-full bg-gradient-to-r from-blue-500 to-blue-400 rounded-full transition-all duration-75" style={{ width: `${progress}%` }}/>
            </div>
            <div className="flex justify-between text-[10px] text-gray-600 mt-1">
              <span>Analyzing</span><span>{Math.round(progress)}%</span>
            </div>
          </div>
        )}

        {phase === "done" && (
          <div className="py-1">
            <div className="grid grid-cols-2 gap-2 mb-3">
              {[["AI IDE Caches","9 apps","#a78bfa"],["Browser Data","8 browsers","#60a5fa"],["Temp & Junk","~2.1 GB","#f87171"],["System","5 types","#fb923c"]].map(([l, v, c]) => (
                <div key={l} className="bg-white/5 rounded-lg p-2.5">
                  <p className="text-base font-bold" style={{ color: c }}>{v}</p>
                  <p className="text-gray-500 text-[10px] mt-0.5">{l}</p>
                </div>
              ))}
            </div>
            <div className="bg-green-500/10 border border-green-500/20 rounded-lg px-3 py-2 text-[10px] text-green-400 mb-3">
              ✓ Passwords safe &nbsp;·&nbsp; ✓ Downloads untouched
            </div>
            <button onClick={reset} className="w-full text-[11px] text-gray-500 hover:text-gray-300 transition-colors py-1">
              Reset demo
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

/* ─── Hero ────────────────────────────────────────────────────────── */
function Hero() {
  return (
    <section className="relative min-h-screen flex items-center pt-16 overflow-hidden">
      {/* background */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-50 via-white to-blue-50"/>
      <div className="absolute top-0 right-0 w-[600px] h-[600px] rounded-full bg-blue-100/40 blur-3xl -translate-y-1/3 translate-x-1/3 pointer-events-none"/>
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] rounded-full bg-slate-100/60 blur-3xl translate-y-1/3 -translate-x-1/3 pointer-events-none"/>

      <div className="relative max-w-6xl mx-auto px-6 py-24 grid md:grid-cols-2 gap-16 items-center w-full">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-medium text-blue-700 bg-blue-50 border border-blue-100 px-3 py-1.5 rounded-full mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"/>
            Free · Windows 10 &amp; 11 · No install needed
          </div>

          <h1 className="text-[3.25rem] font-extrabold text-gray-950 leading-[1.1] tracking-tight mb-6">
            One script.<br/>
            <span className="bg-gradient-to-r from-blue-600 to-blue-400 bg-clip-text text-transparent">Nine categories</span><br/>
            of junk—gone.
          </h1>

          <p className="text-lg text-gray-500 leading-relaxed mb-3 max-w-md">
            My Clean PC is a free Windows batch script that silently wipes AI IDE caches, browser history, temp files, prefetch, DNS, and more.
          </p>
          <p className="text-sm text-gray-400 italic mb-10">Designed with love for Priyanka ❤️</p>

          <div className="flex flex-wrap gap-3">
            <a href={DL("my-clean-pc.bat")} download="my-clean-pc.bat"
              className="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-full transition-colors shadow-lg shadow-blue-200 text-sm">
              <DownloadIcon size={15}/> Download .bat
            </a>
            <a href={DL("my-clean-pc.ps1")} download="my-clean-pc.ps1"
              className="inline-flex items-center gap-2 bg-white hover:bg-gray-50 text-gray-700 font-semibold px-6 py-3 rounded-full border border-gray-200 transition-colors text-sm shadow-sm">
              <DownloadIcon size={15}/> Download .ps1
            </a>
            <a href="#auto-clean"
              className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-semibold px-6 py-3 text-sm transition-colors">
              Set up auto-clean →
            </a>
          </div>
        </div>

        <div className="flex justify-center md:justify-end">
          <ScanDemo />
        </div>
      </div>
    </section>
  );
}

/* ─── Auto-Clean ──────────────────────────────────────────────────── */
type Schedule = { id: string; icon: string; label: string; sub: string; detail: string; bat: string; ps1: string; highlight: boolean };

const SCHEDULES: Schedule[] = [
  { id: "30min", icon: "⚡", label: "Every 30 Minutes", sub: "For heavy AI IDE users", detail: "Ideal if you run Cursor, Windsurf, or similar tools all day — caches build fast.", bat: "schedule-30min.bat", ps1: "schedule-30min.ps1", highlight: false },
  { id: "1week", icon: "📅", label: "Every Week",        sub: "Monday at 9:00 AM",    detail: "Our recommended setting. Keeps your PC clean without ever getting in the way.", bat: "schedule-1week.bat",  ps1: "schedule-1week.ps1",  highlight: true  },
  { id: "15day", icon: "🌙", label: "Every 15 Days",     sub: "At 9:00 AM",            detail: "A gentle schedule for light use. Cleans twice a month, completely silently.",   bat: "schedule-15days.bat", ps1: "schedule-15days.ps1", highlight: false },
];

function PsHelp() {
  const [open, setOpen] = useState(false);
  return (
    <div className="border border-gray-200 rounded-2xl overflow-hidden">
      <button onClick={() => setOpen(o => !o)} className="w-full flex items-center justify-between px-5 py-4 bg-white hover:bg-gray-50 transition-colors text-left">
        <span className="flex items-center gap-2.5 text-sm font-semibold text-gray-700">
          <span className="text-base">❓</span>
          How to run .ps1 files &nbsp;·&nbsp; <span className="text-blue-600">.ps1 फ़ाइल कैसे चलाएं</span>
        </span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`text-gray-400 transition-transform ${open ? "rotate-180" : ""}`}><polyline points="6 9 12 15 18 9"/></svg>
      </button>

      {open && (
        <div className="grid md:grid-cols-2 gap-0 divide-y md:divide-y-0 md:divide-x divide-gray-100 bg-gray-50/50 border-t border-gray-100">
          {/* English */}
          <div className="p-6">
            <p className="text-[11px] font-semibold text-blue-600 uppercase tracking-widest mb-4">English</p>
            <p className="text-sm text-gray-500 mb-5">Windows blocks .ps1 scripts by default. Pick any method below:</p>
            <ol className="space-y-4">
              {[
                { n: "1", title: "Right-click → Run with PowerShell", body: 'Right-click the .ps1 file → "Run with PowerShell". If asked about execution policy, press Y then Enter.' },
                { n: "2", title: "From an Admin PowerShell window", body: null, code: "PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1" },
                { n: "3", title: "One-time unlock (recommended)", body: "Paste in an Admin PowerShell window, press Y → Enter. After this, all .ps1 files run normally.", code: "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" },
              ].map(s => (
                <li key={s.n} className="flex gap-3">
                  <span className="w-5 h-5 rounded-full bg-blue-100 text-blue-700 text-[10px] font-bold flex items-center justify-center flex-shrink-0 mt-0.5">{s.n}</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-800 mb-1">{s.title}</p>
                    {s.body && <p className="text-xs text-gray-500">{s.body}</p>}
                    {s.code && <code className="block mt-1.5 bg-gray-900 text-green-400 text-[11px] px-3 py-2 rounded-lg font-mono">{s.code}</code>}
                    {s.body && s.code && <p className="text-xs text-gray-500 mt-1.5">{s.body}</p>}
                  </div>
                </li>
              ))}
            </ol>
          </div>

          {/* Hindi */}
          <div className="p-6">
            <p className="text-[11px] font-semibold text-blue-600 uppercase tracking-widest mb-4">हिंदी</p>
            <p className="text-sm text-gray-500 mb-5">Windows डिफ़ॉल्ट रूप से .ps1 स्क्रिप्ट ब्लॉक करता है। नीचे कोई भी तरीका चुनें:</p>
            <ol className="space-y-4">
              {[
                { n: "१", title: "राइट-क्लिक → Run with PowerShell", body: '.ps1 फ़ाइल पर राइट-क्लिक करें → "Run with PowerShell" चुनें। अगर execution policy पूछे तो Y दबाएं फिर Enter।' },
                { n: "२", title: "Admin PowerShell में टाइप करें", body: null, code: "PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1" },
                { n: "३", title: "एक बार की सेटिंग (सबसे आसान)", body: "Admin PowerShell में यह कमांड चलाएं, Y → Enter दबाएं। इसके बाद सभी .ps1 फ़ाइलें सामान्य रूप से चलेंगी।", code: "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" },
              ].map(s => (
                <li key={s.n} className="flex gap-3">
                  <span className="w-5 h-5 rounded-full bg-blue-100 text-blue-700 text-[10px] font-bold flex items-center justify-center flex-shrink-0 mt-0.5">{s.n}</span>
                  <div>
                    <p className="text-sm font-semibold text-gray-800 mb-1">{s.title}</p>
                    {s.body && <p className="text-xs text-gray-500">{s.body}</p>}
                    {s.code && <code className="block mt-1.5 bg-gray-900 text-green-400 text-[11px] px-3 py-2 rounded-lg font-mono">{s.code}</code>}
                    {s.body && s.code && <p className="text-xs text-gray-500 mt-1.5">{s.body}</p>}
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      )}
    </div>
  );
}

function AutoClean() {
  return (
    <section id="auto-clean" className="py-28 px-6 bg-white">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-600 uppercase tracking-widest mb-3">Set &amp; Forget</p>
          <h2 className="text-4xl font-extrabold text-gray-950 tracking-tight mb-4">Automatic Cleaning</h2>
          <p className="text-lg text-gray-400 max-w-lg mx-auto">
            Pick a frequency. Download the cleaner + its silent installer. Right-click → Run as administrator. Done forever.
          </p>
        </div>

        {/* step 1 */}
        <div className="mb-10">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3">Step 1 — Download the cleaner</p>
          <a href={DL("my-clean-pc.bat")} download="my-clean-pc.bat"
            className="flex items-center gap-4 border border-gray-200 rounded-2xl px-5 py-4 hover:border-blue-300 hover:bg-blue-50/50 transition-all group bg-white shadow-sm">
            <div className="w-10 h-10 rounded-xl bg-gray-100 group-hover:bg-blue-100 transition-colors flex items-center justify-center text-lg">🦇</div>
            <div className="flex-1">
              <p className="font-semibold text-gray-900 text-sm">my-clean-pc.bat</p>
              <p className="text-xs text-gray-400">The cleaning script — cleans all 9 categories silently and exits</p>
            </div>
            <span className="flex items-center gap-1.5 text-xs font-semibold text-blue-600 opacity-0 group-hover:opacity-100 transition-opacity">
              <DownloadIcon size={13}/> Download
            </span>
          </a>
        </div>

        {/* step 2 */}
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3">Step 2 — Choose frequency &amp; download its silent installer</p>
        <div className="grid md:grid-cols-3 gap-4 mb-6">
          {SCHEDULES.map(s => (
            <div key={s.id} className={`rounded-2xl p-5 border transition-all ${s.highlight ? "border-blue-200 bg-blue-50/60 shadow-md shadow-blue-100/60" : "border-gray-200 bg-white shadow-sm"}`}>
              {s.highlight && <p className="text-[10px] font-bold text-blue-600 uppercase tracking-widest mb-2">★ Recommended</p>}
              <span className="text-2xl mb-3 block">{s.icon}</span>
              <h3 className="font-bold text-gray-900 mb-0.5 text-sm">{s.label}</h3>
              <p className="text-[11px] text-gray-400 mb-2">{s.sub}</p>
              <p className="text-xs text-gray-500 leading-relaxed mb-4">{s.detail}</p>
              <div className="flex gap-2">
                <a href={DL(s.bat)} download={s.bat}
                  className="flex-1 flex items-center justify-center gap-1 bg-blue-600 hover:bg-blue-700 text-white text-[11px] font-bold py-2 rounded-xl transition-colors">
                  <DownloadIcon size={11}/>.bat
                </a>
                <a href={DL(s.ps1)} download={s.ps1}
                  className="flex-1 flex items-center justify-center gap-1 bg-gray-800 hover:bg-gray-900 text-white text-[11px] font-bold py-2 rounded-xl transition-colors">
                  <DownloadIcon size={11}/>.ps1
                </a>
              </div>
            </div>
          ))}
        </div>

        <div className="flex gap-3 bg-amber-50 border border-amber-200/80 rounded-2xl px-5 py-4 mb-4">
          <span className="text-amber-400 text-base mt-0.5">⚠</span>
          <p className="text-xs text-amber-700"><strong>Keep both files in the same folder.</strong> The installer copies my-clean-pc.bat to %LOCALAPPDATA%\MyCleanPC\ automatically. Run it once — cleaning happens forever after.</p>
        </div>

        <PsHelp />
      </div>
    </section>
  );
}

/* ─── What It Cleans ──────────────────────────────────────────────── */
const CATEGORIES = [
  { icon: "🤖", title: "AI IDE Caches", count: "9 apps",    items: ["Cursor", "Windsurf", "Kiro", "Trae AI", "Warp", "Devin", "Qoder", "Antigravity", "Genspark"],     desc: "Cache, logs, and temp data from AI coding tools — can reach several GB over weeks." },
  { icon: "🌐", title: "Browser Data",  count: "8 browsers", items: ["Chrome", "Edge", "Brave", "Vivaldi", "Opera", "Firefox", "Yandex", "Genspark Browser"],          desc: "Cache, cookies, history, and sessions. Passwords are always skipped." },
  { icon: "🗂️", title: "Temp Files",    count: "2 folders", items: ["%TEMP%", "C:\\Windows\\Temp"],                                                                    desc: "Leftover files from installers, updates, and app crashes." },
  { icon: "⚡", title: "Prefetch",      count: "2 paths",   items: ["C:\\Windows\\Prefetch", "Recent Activity"],                                                       desc: "Stale prefetch and recent file shortcuts from Explorer." },
  { icon: "🗑️", title: "Recycle Bin",  count: "All drives", items: ["$Recycle.Bin on every drive"],                                                                   desc: "Empties the Recycle Bin across all connected drives." },
  { icon: "🔄", title: "Update Cache",  count: "2 paths",   items: ["SoftwareDistribution\\Download", "DataStore\\Logs"],                                             desc: "Already-installed Windows update files taking up space." },
  { icon: "🖼️", title: "Thumbnail Cache", count: "Explorer", items: ["thumbcache_*.db", "iconcache_*.db"],                                                            desc: "Stale Explorer thumbnail databases — rebuilt fresh automatically." },
  { icon: "📋", title: "Event Logs",   count: "4 logs",     items: ["Application", "System", "Security", "Setup"],                                                    desc: "Windows event logs that grow and slow down Event Viewer." },
  { icon: "🌍", title: "DNS Cache",    count: "System-wide", items: ["ipconfig /flushdns"],                                                                            desc: "Flushes the DNS resolver — fixes stale or broken domain lookups." },
];

function WhatItCleans() {
  return (
    <section id="what-it-cleans" className="py-28 px-6 bg-slate-50">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-600 uppercase tracking-widest mb-3">Fully transparent</p>
          <h2 className="text-4xl font-extrabold text-gray-950 tracking-tight mb-4">What It Actually Cleans</h2>
          <p className="text-lg text-gray-400 max-w-lg mx-auto">Every folder and file the script touches — nothing hidden, nothing extra.</p>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {CATEGORIES.map(c => (
            <div key={c.title} className="bg-white rounded-2xl border border-gray-100 p-5 hover:border-blue-100 hover:shadow-md transition-all group">
              <div className="flex items-start justify-between mb-3">
                <span className="text-2xl">{c.icon}</span>
                <span className="text-[10px] font-semibold text-gray-400 bg-gray-50 border border-gray-100 px-2 py-0.5 rounded-full">{c.count}</span>
              </div>
              <h3 className="font-bold text-gray-900 text-sm mb-1">{c.title}</h3>
              <p className="text-xs text-gray-400 leading-relaxed mb-3">{c.desc}</p>
              <ul className="space-y-0.5">
                {c.items.map(i => (
                  <li key={i} className="flex items-center gap-1.5 text-[11px] text-gray-500">
                    <span className="text-gray-300">›</span>
                    <span className="font-mono">{i}</span>
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

/* ─── Safety ──────────────────────────────────────────────────────── */
function Safety() {
  const never = [
    { icon: "🔑", title: "Saved Passwords",       body: "Login Data files (Chrome, Edge, Brave, Vivaldi, Opera, Yandex) are explicitly skipped in every loop." },
    { icon: "📁", title: "Downloads Folder",       body: "%USERPROFILE%\\Downloads is never read, listed, or modified." },
    { icon: "🗝️", title: "Firefox key4.db",       body: "Firefox stores passwords in key4.db — it is hardcoded to be skipped every time." },
    { icon: "🖼️", title: "Personal Files",         body: "The script only targets known cache/temp directories — photos, docs, and videos are never touched." },
  ];
  return (
    <section id="safety" className="py-28 px-6 bg-white">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-green-600 uppercase tracking-widest mb-3">Hardcoded exclusions</p>
          <h2 className="text-4xl font-extrabold text-gray-950 tracking-tight mb-4">What It Will <span className="text-green-600">Never</span> Touch</h2>
          <p className="text-lg text-gray-400">These aren't settings — they're hardcoded exclusions in the script itself.</p>
        </div>
        <div className="grid sm:grid-cols-2 gap-4 mb-8">
          {never.map(n => (
            <div key={n.title} className="flex gap-4 p-5 rounded-2xl border border-gray-100 bg-white shadow-sm hover:border-green-100 transition-colors">
              <span className="text-2xl mt-0.5">{n.icon}</span>
              <div>
                <p className="font-semibold text-gray-900 text-sm mb-1">{n.title}</p>
                <p className="text-xs text-gray-500 leading-relaxed">{n.body}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="bg-green-50 border border-green-100 rounded-2xl p-6 text-center">
          <p className="font-semibold text-green-800 mb-1">100% Open source batch scripts</p>
          <p className="text-sm text-green-700">Open any file in Notepad before running — every line is readable plain text. No executables, no network calls, no telemetry.</p>
        </div>
      </div>
    </section>
  );
}

/* ─── Download ────────────────────────────────────────────────────── */
const ALL_FILES = [
  { icon: "🦇", label: "Cleaner",          sub: "Run once silently",          file: "my-clean-pc.bat",        ext: ".bat", theme: "blue"  },
  { icon: "⚙️", label: "Cleaner PS",       sub: "Colour-coded output",        file: "my-clean-pc.ps1",        ext: ".ps1", theme: "slate" },
  { icon: "⚡", label: "Schedule 30 min",  sub: "Silent installer",           file: "schedule-30min.bat",     ext: ".bat", theme: "blue"  },
  { icon: "⚡", label: "Schedule 30 min",  sub: "Silent installer (PS)",      file: "schedule-30min.ps1",     ext: ".ps1", theme: "slate" },
  { icon: "📅", label: "Schedule Weekly",  sub: "Silent installer",           file: "schedule-1week.bat",     ext: ".bat", theme: "blue"  },
  { icon: "📅", label: "Schedule Weekly",  sub: "Silent installer (PS)",      file: "schedule-1week.ps1",     ext: ".ps1", theme: "slate" },
  { icon: "🌙", label: "Schedule 15 Days", sub: "Silent installer",           file: "schedule-15days.bat",    ext: ".bat", theme: "blue"  },
  { icon: "🌙", label: "Schedule 15 Days", sub: "Silent installer (PS)",      file: "schedule-15days.ps1",    ext: ".ps1", theme: "slate" },
  { icon: "🗑️", label: "Uninstall",        sub: "Remove task + files",        file: "uninstall.bat",          ext: ".bat", theme: "red"   },
  { icon: "🗑️", label: "Uninstall PS",     sub: "Remove task + files (PS)",   file: "uninstall.ps1",          ext: ".ps1", theme: "red"   },
];

function Download() {
  return (
    <section id="download" className="py-28 px-6 bg-gray-950">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-400 uppercase tracking-widest mb-3">All files</p>
          <h2 className="text-4xl font-extrabold text-white tracking-tight mb-4">Download</h2>
          <p className="text-gray-400 text-lg max-w-md mx-auto">Every script available as .bat and .ps1. All run silently — no prompts, no menus.</p>
        </div>

        <div className="grid sm:grid-cols-2 gap-3">
          {ALL_FILES.map(f => (
            <a key={f.file} href={DL(f.file)} download={f.file}
              className="flex items-center gap-3.5 bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 rounded-2xl px-4 py-3.5 transition-all group">
              <span className="text-xl">{f.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-white">{f.label}
                  <span className={`ml-2 text-[10px] font-bold px-1.5 py-0.5 rounded ${f.theme === "blue" ? "bg-blue-600/30 text-blue-300" : f.theme === "red" ? "bg-red-600/30 text-red-300" : "bg-slate-600/40 text-slate-300"}`}>
                    {f.ext}
                  </span>
                </p>
                <p className="text-[11px] text-gray-500 truncate">{f.sub} — {f.file}</p>
              </div>
              <DownloadIcon size={14} />
            </a>
          ))}
        </div>

        <div className="mt-8 bg-white/5 border border-white/10 rounded-2xl p-5">
          <p className="text-gray-400 text-xs font-mono leading-relaxed">
            <span className="text-gray-600"># PowerShell — run with bypass:</span><br/>
            PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1<br/><br/>
            <span className="text-gray-600"># Check your scheduled task:</span><br/>
            schtasks /query /tn "MyCleanPC"
          </p>
        </div>
      </div>
    </section>
  );
}

/* ─── Footer ──────────────────────────────────────────────────────── */
function Footer() {
  return (
    <footer className="bg-gray-950 border-t border-white/5 py-10 px-6">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-gray-600">
        <div className="flex items-center gap-2.5">
          <div className="w-6 h-6 rounded-md bg-blue-600 flex items-center justify-center">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
          </div>
          <span className="text-white font-medium">My Clean PC</span>
          <span className="text-gray-700">·</span>
          <span className="text-gray-600 text-xs">Designed for Priyanka ❤️</span>
        </div>
        <p>© {new Date().getFullYear()} My Clean PC · Free &amp; Open Source</p>
        <div className="flex gap-6">
          <a href="#auto-clean" className="hover:text-gray-400 transition-colors">Auto-Clean</a>
          <a href="#what-it-cleans" className="hover:text-gray-400 transition-colors">What It Cleans</a>
          <a href="#safety" className="hover:text-gray-400 transition-colors">Safety</a>
        </div>
      </div>
    </footer>
  );
}

/* ─── Floating Download Button ────────────────────────────────────── */
function FloatingDownload() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const hero = document.querySelector("#hero-end");
    if (!hero) return;
    const observer = new IntersectionObserver(
      ([entry]) => setVisible(!entry.isIntersecting),
      { threshold: 0 }
    );
    observer.observe(hero);
    return () => observer.disconnect();
  }, []);

  return (
    <div className={`fixed bottom-6 right-6 z-50 flex flex-col items-end gap-2 transition-all duration-300 ${visible ? "opacity-100 translate-y-0 pointer-events-auto" : "opacity-0 translate-y-4 pointer-events-none"}`}>
      <div className="flex gap-2">
        <a
          href={DL("my-clean-pc.ps1")}
          download="my-clean-pc.ps1"
          className="flex items-center gap-2 bg-gray-800 hover:bg-gray-900 text-white text-xs font-semibold px-4 py-2.5 rounded-full shadow-lg transition-colors"
        >
          <DownloadIcon size={12} /> .ps1
        </a>
        <a
          href={DL("my-clean-pc.bat")}
          download="my-clean-pc.bat"
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold px-5 py-2.5 rounded-full shadow-xl shadow-blue-500/30 transition-colors"
        >
          <DownloadIcon size={13} /> Download .bat
        </a>
      </div>
      <p className="text-[10px] text-gray-400 text-right pr-1">Free · No install needed</p>
    </div>
  );
}

/* ─── App ─────────────────────────────────────────────────────────── */
export default function App() {
  return (
    <div className="font-sans antialiased">
      <Navbar />
      <Hero />
      <div id="hero-end" aria-hidden="true" />
      <AutoClean />
      <WhatItCleans />
      <Safety />
      <Download />
      <Footer />
      <FloatingDownload />
    </div>
  );
}
