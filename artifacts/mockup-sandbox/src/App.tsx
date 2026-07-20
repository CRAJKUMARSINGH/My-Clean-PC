import { useState, useEffect, useRef, createContext, useContext } from "react";

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");
const DL = (file: string) => `${BASE}/${file}`;

/* ─── Dark mode context ───────────────────────────────────────────── */
const DarkCtx = createContext<{ dark: boolean; toggle: () => void }>({ dark: false, toggle: () => {} });
const useDark = () => useContext(DarkCtx);

/* ─── Icons ───────────────────────────────────────────────────────── */
function DownloadIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
    </svg>
  );
}

function SunIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/>
    </svg>
  );
}

/* ─── CodeBlock ───────────────────────────────────────────────────── */
function CodeBlock({ code, dark: forceDark = false }: { code: string; dark?: boolean }) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(code).then(() => { setCopied(true); setTimeout(() => setCopied(false), 2000); });
  };
  return (
    <div className={`relative flex items-center gap-2 mt-1.5 rounded-lg px-3 py-2 font-mono text-[11px] group ${forceDark ? "bg-black/40 text-green-400" : "bg-gray-900 text-green-400"}`}>
      <span className="flex-1 select-all break-all">{code}</span>
      <button onClick={copy} title="Copy"
        className={`flex-shrink-0 flex items-center gap-1 text-[10px] font-sans font-semibold px-2 py-1 rounded-md transition-all ${copied ? "bg-green-500/20 text-green-300" : "bg-white/10 text-gray-400 hover:bg-white/20 hover:text-white"}`}>
        {copied
          ? <><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><polyline points="20 6 9 17 4 12"/></svg> Copied</>
          : <><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg> Copy</>
        }
      </button>
    </div>
  );
}

/* ─── Changelog ───────────────────────────────────────────────────── */
const CHANGELOG = [
  {
    version: "v1.4",
    date: "Jun 2025",
    badge: "New",
    badgeColor: "bg-blue-500",
    items: [
      "Dark / light mode toggle",
      "Share button — copy link or native share sheet",
      "Copy buttons on all PowerShell commands",
      "Floating download FAB when you scroll past hero",
    ],
  },
  {
    version: "v1.3",
    date: "Jun 2025",
    badge: "New",
    badgeColor: "bg-blue-500",
    items: [
      "PowerShell (.ps1) versions for all schedulers & uninstaller",
      "Bilingual PS1 help (English + Hindi) in accordion",
      "Elegant redesign — white SaaS layout with spacious sections",
    ],
  },
  {
    version: "v1.2",
    date: "Jun 2025",
    badge: "",
    badgeColor: "",
    items: [
      "Auto-scheduler: 30-min, weekly, and 15-day installers",
      "Silent uninstaller removes task + all installed files",
      "9-category transparent listing with exact paths",
    ],
  },
  {
    version: "v1.0",
    date: "Jun 2025",
    badge: "",
    badgeColor: "",
    items: [
      "Rigorous temp + AppData deep sweep across all Local/Roaming apps",
      "Initial release: my-clean-pc.bat cleans 10 junk categories",
      "Covers AI IDEs (9 apps), 8 browsers, Temp, Prefetch, DNS, and more",
      "Hardcoded exclusions: passwords, Downloads folder always skipped",
    ],
  },
];

function WhatsNew() {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    if (open) document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen(o => !o)}
        className="flex items-center gap-1.5 text-xs font-semibold px-3 py-2 rounded-full border border-gray-200 dark:border-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      >
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"/>
          <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"/>
        </span>
        What's New
      </button>

      {open && (
        <div className="absolute right-0 top-12 w-80 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-2xl shadow-2xl shadow-black/10 dark:shadow-black/40 overflow-hidden z-50">
          <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
            <div>
              <p className="font-bold text-gray-900 dark:text-white text-sm">What's New</p>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">My Clean PC changelog</p>
            </div>
            <button onClick={() => setOpen(false)} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>

          <div className="overflow-y-auto max-h-80 divide-y divide-gray-100 dark:divide-gray-800">
            {CHANGELOG.map(entry => (
              <div key={entry.version} className="px-5 py-4">
                <div className="flex items-center gap-2 mb-2.5">
                  <span className="font-bold text-gray-900 dark:text-white text-sm">{entry.version}</span>
                  {entry.badge && (
                    <span className={`text-[10px] font-bold text-white px-1.5 py-0.5 rounded-full ${entry.badgeColor}`}>{entry.badge}</span>
                  )}
                  <span className="text-gray-400 dark:text-gray-600 text-xs ml-auto">{entry.date}</span>
                </div>
                <ul className="space-y-1.5">
                  {entry.items.map(item => (
                    <li key={item} className="flex items-start gap-2 text-xs text-gray-500 dark:text-gray-400">
                      <span className="text-blue-400 mt-0.5 flex-shrink-0">›</span>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <div className="px-5 py-3 bg-gray-50 dark:bg-gray-800/60 border-t border-gray-100 dark:border-gray-800">
            <p className="text-[11px] text-gray-400 dark:text-gray-500 text-center">All updates are free forever ❤️</p>
          </div>
        </div>
      )}
    </div>
  );
}

/* ─── Navbar ──────────────────────────────────────────────────────── */
function ShareButton() {
  const [state, setState] = useState<"idle" | "copied" | "error">("idle");
  const share = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) {
        await navigator.share({ title: "My Clean PC", text: "Free Windows junk cleaner — silently wipes 10 categories.", url });
      } else {
        await navigator.clipboard.writeText(url);
        setState("copied");
        setTimeout(() => setState("idle"), 2500);
      }
    } catch {
      setState("error");
      setTimeout(() => setState("idle"), 2500);
    }
  };
  return (
    <button onClick={share} title="Share this page"
      className={`flex items-center gap-1.5 text-xs font-semibold px-3 py-2 rounded-full border transition-all ${
        state === "copied" ? "border-green-300 dark:border-green-700 bg-green-50 dark:bg-green-950/50 text-green-700 dark:text-green-400"
        : state === "error"  ? "border-red-300 dark:border-red-700 bg-red-50 dark:bg-red-950/50 text-red-600 dark:text-red-400"
        : "border-gray-200 dark:border-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
      }`}>
      {state === "copied" ? (
        <><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><polyline points="20 6 9 17 4 12"/></svg> Copied!</>
      ) : state === "error" ? (
        <><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> Failed</>
      ) : (
        <><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg> Share</>
      )}
    </button>
  );
}

function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const { dark, toggle } = useDark();
  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);
  return (
    <header className={`fixed top-0 inset-x-0 z-50 transition-all duration-500 ${scrolled ? "bg-white/90 dark:bg-gray-950/90 backdrop-blur border-b border-gray-100 dark:border-gray-800 shadow-sm" : ""}`}>
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#" className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center shadow-sm">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
          </div>
          <span className="font-semibold text-gray-900 dark:text-white tracking-tight">My Clean PC</span>
        </a>
        <nav className="hidden md:flex items-center gap-8 text-sm text-gray-500 dark:text-gray-400">
          <a href="#auto-clean" className="hover:text-gray-900 dark:hover:text-white transition-colors">Auto-Clean</a>
          <a href="#what-it-cleans" className="hover:text-gray-900 dark:hover:text-white transition-colors">What It Cleans</a>
          <a href="#safety" className="hover:text-gray-900 dark:hover:text-white transition-colors">Safety</a>
          <a href="#download" className="hover:text-gray-900 dark:hover:text-white transition-colors">Download</a>
        </nav>
        <div className="flex items-center gap-2">
          <WhatsNew />
          <ShareButton />
          <button onClick={toggle}
            className="w-9 h-9 rounded-full flex items-center justify-center border border-gray-200 dark:border-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            title={dark ? "Switch to light mode" : "Switch to dark mode"}>
            {dark ? <SunIcon /> : <MoonIcon />}
          </button>
          <a href="#download" className="text-sm font-medium bg-blue-600 text-white px-4 py-2 rounded-full hover:bg-blue-700 transition-colors shadow-sm">
            Download Free
          </a>
        </div>
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
  const lines = ["Cursor\\Cache…","Windsurf\\logs…","Chrome\\Cache…","Edge\\Cache…","Brave\\Cache…","Firefox cache2…","%TEMP%\\*…","%LOCALAPPDATA%\\Temp…","AppData\\*\\Cache…","AppData\\*\\Logs…","C:\\Windows\\Temp…","$Recycle.Bin…","SoftwareDistribution…","thumbcache_*.db…","DNS cache…"];

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
      <div className="flex items-center gap-1.5 px-4 py-3 bg-[#161b22] border-b border-white/5">
        <span className="w-2.5 h-2.5 rounded-full bg-red-500/80"/><span className="w-2.5 h-2.5 rounded-full bg-yellow-400/80"/><span className="w-2.5 h-2.5 rounded-full bg-green-400/80"/>
        <span className="ml-2 text-gray-500 text-[10px]">my-clean-pc.bat</span>
      </div>
      <div className="p-5">
        {phase === "idle" && (
          <div className="text-center py-8">
            <div className="w-12 h-12 rounded-full bg-blue-500/15 flex items-center justify-center mx-auto mb-4">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            </div>
            <p className="text-gray-400 mb-5 leading-relaxed text-[11px]">Scans 10 categories — AI IDEs,<br/>browsers, rigorous temp &amp; AppData &amp; more</p>
            <button onClick={start} className="bg-blue-600 hover:bg-blue-500 text-white text-[11px] font-semibold px-5 py-2 rounded-lg transition-colors">Run Demo</button>
          </div>
        )}
        {phase === "scanning" && (
          <div className="py-4">
            <div className="flex items-center gap-2 mb-3"><span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse"/><span className="text-blue-400 text-[11px]">Scanning…</span></div>
            <p className="text-gray-500 text-[10px] h-3 mb-3 truncate">{line}</p>
            <div className="h-1 rounded-full bg-white/5 mb-1 overflow-hidden"><div className="h-full bg-gradient-to-r from-blue-500 to-blue-400 rounded-full transition-all duration-75" style={{ width: `${progress}%` }}/></div>
            <div className="flex justify-between text-[10px] text-gray-600 mt-1"><span>Analyzing</span><span>{Math.round(progress)}%</span></div>
          </div>
        )}
        {phase === "done" && (
          <div className="py-1">
            <div className="grid grid-cols-2 gap-2 mb-3">
              {[["AI IDE Caches","9 apps","#a78bfa"],["Browser Data","8 browsers","#60a5fa"],["Temp & Junk","~2.1 GB","#f87171"],["System","5 types","#fb923c"]].map(([l, v, c]) => (
                <div key={l} className="bg-white/5 rounded-lg p-2.5"><p className="text-base font-bold" style={{ color: c }}>{v}</p><p className="text-gray-500 text-[10px] mt-0.5">{l}</p></div>
              ))}
            </div>
            <div className="bg-green-500/10 border border-green-500/20 rounded-lg px-3 py-2 text-[10px] text-green-400 mb-3">✓ Passwords safe &nbsp;·&nbsp; ✓ Downloads untouched</div>
            <button onClick={reset} className="w-full text-[11px] text-gray-500 hover:text-gray-300 transition-colors py-1">Reset demo</button>
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
      <div className="absolute inset-0 bg-gradient-to-br from-slate-50 via-white to-blue-50 dark:from-gray-950 dark:via-gray-900 dark:to-blue-950"/>
      <div className="absolute top-0 right-0 w-[600px] h-[600px] rounded-full bg-blue-100/40 dark:bg-blue-900/20 blur-3xl -translate-y-1/3 translate-x-1/3 pointer-events-none"/>
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] rounded-full bg-slate-100/60 dark:bg-slate-900/40 blur-3xl translate-y-1/3 -translate-x-1/3 pointer-events-none"/>
      <div className="relative max-w-6xl mx-auto px-6 py-24 grid md:grid-cols-2 gap-16 items-center w-full">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-medium text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-950/60 border border-blue-100 dark:border-blue-900 px-3 py-1.5 rounded-full mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"/>
            Free · Windows 10 &amp; 11 · No install needed
          </div>
          <h1 className="text-[3.25rem] font-extrabold text-gray-950 dark:text-white leading-[1.1] tracking-tight mb-6">
            One script.<br/>
            <span className="bg-gradient-to-r from-blue-600 to-blue-400 bg-clip-text text-transparent">Nine categories</span><br/>
            of junk—gone.
          </h1>
          <p className="text-lg text-gray-500 dark:text-gray-400 leading-relaxed mb-3 max-w-md">
            My Clean PC is a free Windows batch script that silently wipes AI IDE caches, browser history, temp files, prefetch, DNS, and more.
          </p>
          <p className="text-sm text-gray-400 dark:text-gray-500 italic mb-10">Designed with love for Priyanka ❤️</p>
          <div className="flex flex-wrap gap-3">
            <a href={DL("my-clean-pc.bat")} download="my-clean-pc.bat"
              className="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-full transition-colors shadow-lg shadow-blue-200 dark:shadow-blue-900/40 text-sm">
              <DownloadIcon size={15}/> Download .bat
            </a>
            <a href={DL("my-clean-pc.ps1")} download="my-clean-pc.ps1"
              className="inline-flex items-center gap-2 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-200 font-semibold px-6 py-3 rounded-full border border-gray-200 dark:border-gray-700 transition-colors text-sm shadow-sm">
              <DownloadIcon size={15}/> Download .ps1
            </a>
            <a href="#auto-clean" className="inline-flex items-center gap-2 text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-semibold px-6 py-3 text-sm transition-colors">
              Set up auto-clean →
            </a>
          </div>

          {/* Guarantee strip */}
          <div className="flex flex-wrap items-center gap-x-5 gap-y-2 mt-2 pl-1">
            {[
              { icon: "📄", label: "Open in Notepad — read every line" },
              { icon: "🚫", label: "No executables" },
              { icon: "🌐", label: "No network calls" },
              { icon: "🔑", label: "Passwords never touched" },
            ].map(({ icon, label }) => (
              <span key={label} className="flex items-center gap-1.5 text-xs text-gray-400 dark:text-gray-500">
                <span>{icon}</span>
                <span>{label}</span>
              </span>
            ))}
          </div>
        </div>
        <div className="flex justify-center md:justify-end"><ScanDemo /></div>
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
  const EN = [
    { n: "1", title: "Right-click → Run with PowerShell", body: 'Right-click the .ps1 file → "Run with PowerShell". If asked about execution policy, press Y then Enter.', code: null },
    { n: "2", title: "From an Admin PowerShell window",   body: null, code: "PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1" },
    { n: "3", title: "One-time unlock (recommended)",     body: "Paste in an Admin PowerShell window, press Y → Enter. After this, all .ps1 files run normally.", code: "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" },
  ];
  const HI = [
    { n: "१", title: "राइट-क्लिक → Run with PowerShell", body: '.ps1 फ़ाइल पर राइट-क्लिक करें → "Run with PowerShell" चुनें। अगर execution policy पूछे तो Y दबाएं फिर Enter।', code: null },
    { n: "२", title: "Admin PowerShell में टाइप करें",    body: null, code: "PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1" },
    { n: "३", title: "एक बार की सेटिंग (सबसे आसान)",    body: "Admin PowerShell में यह कमांड चलाएं, Y → Enter दबाएं। इसके बाद सभी .ps1 फ़ाइलें सामान्य रूप से चलेंगी।", code: "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" },
  ];
  const steps = (list: typeof EN) => list.map(s => (
    <li key={s.n} className="flex gap-3">
      <span className="w-5 h-5 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 text-[10px] font-bold flex items-center justify-center flex-shrink-0 mt-0.5">{s.n}</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-1">{s.title}</p>
        {s.body && !s.code && <p className="text-xs text-gray-500 dark:text-gray-400">{s.body}</p>}
        {s.code && <CodeBlock code={s.code} />}
        {s.body && s.code && <p className="text-xs text-gray-500 dark:text-gray-400 mt-1.5">{s.body}</p>}
      </div>
    </li>
  ));
  return (
    <div className="border border-gray-200 dark:border-gray-700 rounded-2xl overflow-hidden">
      <button onClick={() => setOpen(o => !o)} className="w-full flex items-center justify-between px-5 py-4 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-750 transition-colors text-left">
        <span className="flex items-center gap-2.5 text-sm font-semibold text-gray-700 dark:text-gray-200">
          <span className="text-base">❓</span>
          How to run .ps1 files &nbsp;·&nbsp; <span className="text-blue-600 dark:text-blue-400">.ps1 फ़ाइल कैसे चलाएं</span>
        </span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`text-gray-400 transition-transform ${open ? "rotate-180" : ""}`}><polyline points="6 9 12 15 18 9"/></svg>
      </button>
      {open && (
        <div className="grid md:grid-cols-2 gap-0 divide-y md:divide-y-0 md:divide-x divide-gray-100 dark:divide-gray-700 bg-gray-50/50 dark:bg-gray-900/50 border-t border-gray-100 dark:border-gray-700">
          <div className="p-6">
            <p className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-4">English</p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-5">Windows blocks .ps1 scripts by default. Pick any method below:</p>
            <ol className="space-y-4">{steps(EN)}</ol>
          </div>
          <div className="p-6">
            <p className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-4">हिंदी</p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-5">Windows डिफ़ॉल्ट रूप से .ps1 स्क्रिप्ट ब्लॉक करता है। नीचे कोई भी तरीका चुनें:</p>
            <ol className="space-y-4">{steps(HI)}</ol>
          </div>
        </div>
      )}
    </div>
  );
}

function AutoClean() {
  return (
    <section id="auto-clean" className="py-28 px-6 bg-white dark:bg-gray-900 transition-colors">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-3">Set &amp; Forget</p>
          <h2 className="text-4xl font-extrabold text-gray-950 dark:text-white tracking-tight mb-4">Automatic Cleaning</h2>
          <p className="text-lg text-gray-400 dark:text-gray-500 max-w-lg mx-auto">Pick a frequency. Download the cleaner + its silent installer. Right-click → Run as administrator. Done forever.</p>
        </div>

        <div className="mb-10">
          <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-3">Step 1 — Download the cleaner</p>
          <a href={DL("my-clean-pc.bat")} download="my-clean-pc.bat"
            className="flex items-center gap-4 border border-gray-200 dark:border-gray-700 rounded-2xl px-5 py-4 hover:border-blue-300 dark:hover:border-blue-700 hover:bg-blue-50/50 dark:hover:bg-blue-950/30 transition-all group bg-white dark:bg-gray-800 shadow-sm">
            <div className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-gray-700 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/50 transition-colors flex items-center justify-center text-lg">🦇</div>
            <div className="flex-1">
              <p className="font-semibold text-gray-900 dark:text-white text-sm">my-clean-pc.bat</p>
              <p className="text-xs text-gray-400 dark:text-gray-500">The cleaning script — cleans all 10 categories silently and exits</p>
            </div>
            <span className="flex items-center gap-1.5 text-xs font-semibold text-blue-600 dark:text-blue-400 opacity-0 group-hover:opacity-100 transition-opacity">
              <DownloadIcon size={13}/> Download
            </span>
          </a>
        </div>

        <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-3">Step 2 — Choose frequency &amp; download its silent installer</p>
        <div className="grid md:grid-cols-3 gap-4 mb-6">
          {SCHEDULES.map(s => (
            <div key={s.id} className={`rounded-2xl p-5 border transition-all ${s.highlight ? "border-blue-200 dark:border-blue-800 bg-blue-50/60 dark:bg-blue-950/40 shadow-md shadow-blue-100/60 dark:shadow-blue-900/20" : "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 shadow-sm"}`}>
              {s.highlight && <p className="text-[10px] font-bold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-2">★ Recommended</p>}
              <span className="text-2xl mb-3 block">{s.icon}</span>
              <h3 className="font-bold text-gray-900 dark:text-white mb-0.5 text-sm">{s.label}</h3>
              <p className="text-[11px] text-gray-400 dark:text-gray-500 mb-2">{s.sub}</p>
              <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed mb-4">{s.detail}</p>
              <div className="flex gap-2">
                <a href={DL(s.bat)} download={s.bat} className="flex-1 flex items-center justify-center gap-1 bg-blue-600 hover:bg-blue-700 text-white text-[11px] font-bold py-2 rounded-xl transition-colors">
                  <DownloadIcon size={11}/>.bat
                </a>
                <a href={DL(s.ps1)} download={s.ps1} className="flex-1 flex items-center justify-center gap-1 bg-gray-800 dark:bg-gray-700 hover:bg-gray-900 dark:hover:bg-gray-600 text-white text-[11px] font-bold py-2 rounded-xl transition-colors">
                  <DownloadIcon size={11}/>.ps1
                </a>
              </div>
            </div>
          ))}
        </div>

        <div className="flex gap-3 bg-amber-50 dark:bg-amber-950/40 border border-amber-200/80 dark:border-amber-800/60 rounded-2xl px-5 py-4 mb-4">
          <span className="text-amber-400 text-base mt-0.5">⚠</span>
          <p className="text-xs text-amber-700 dark:text-amber-400"><strong>Keep both files in the same folder.</strong> The installer copies my-clean-pc.bat to %LOCALAPPDATA%\MyCleanPC\ automatically. Run it once — cleaning happens forever after.</p>
        </div>

        <PsHelp />
      </div>
    </section>
  );
}

/* ─── What It Cleans ──────────────────────────────────────────────── */
const CATEGORIES = [
  { icon: "🤖", title: "AI IDE Caches",    count: "9 apps",     items: ["Cursor","Windsurf","Kiro","Trae AI","Warp","Devin","Qoder","Antigravity","Genspark"],    desc: "Cache, logs, and temp data from AI coding tools — can reach several GB over weeks." },
  { icon: "🌐", title: "Browser Data",     count: "All installed", items: ["Auto-detect every browser on PC","Chrome, Edge, Firefox, Brave, Opera + any other","Cache, cookies, history, sessions"], desc: "Scans AppData for all browsers — cleans like Ctrl+Shift+Delete. Passwords always skipped." },
  { icon: "🗂️", title: "Temp Files",       count: "Rigorous",   items: ["%TEMP%","%LOCALAPPDATA%\\Temp","C:\\Windows\\Temp","CrashDumps","D3DSCache","WebCache","Every app's Temp/tmp"], desc: "Maximum safe local temp cleanup — every known temp location plus Temp folders inside all Local apps." },
  { icon: "🧹", title: "AppData Deep Sweep", count: "All apps",   items: ["%LOCALAPPDATA%\\*\\Cache","%LOCALAPPDATA%\\*\\Logs","%APPDATA%\\*\\Temp","%APPDATA%\\*\\CachedData"], desc: "Scans every app in Local and Roaming — deletes cache, temp, and log folders (maximum safe junk). Passwords skipped." },
  { icon: "⚡", title: "Prefetch",         count: "1 path",     items: ["C:\\Windows\\Prefetch"],                                                                  desc: "Stale Windows prefetch files only. Recent files and Quick Access pins are intentionally skipped." },
  { icon: "🧽", title: "Disk Cleanup",     count: "C: drive",   items: ["cleanmgr.exe /sagerun","All non-download VolumeCaches categories","DownloadsFolder excluded"],       desc: "Runs Windows Disk Cleanup without category prompts. Anything with 'download' in the CleanMgr category name is not selected." },
  { icon: "🗑️", title: "Recycle Bin",     count: "All drives",  items: ["$Recycle.Bin on every drive"],                                                          desc: "Empties the Recycle Bin across all connected drives." },
  { icon: "🔄", title: "Update Cache",     count: "2 paths",    items: ["SoftwareDistribution\\Download","DataStore\\Logs"],                                     desc: "Already-installed Windows update files taking up space." },
  { icon: "🖼️", title: "Thumbnail Cache", count: "Explorer",   items: ["thumbcache_*.db","iconcache_*.db"],                                                      desc: "Stale Explorer thumbnail databases — rebuilt fresh automatically." },
  { icon: "📋", title: "Event Logs",       count: "4 logs",     items: ["Application","System","Security","Setup"],                                               desc: "Windows event logs that grow and slow down Event Viewer." },
  { icon: "🌍", title: "DNS Cache",        count: "System-wide",items: ["ipconfig /flushdns"],                                                                   desc: "Flushes the DNS resolver — fixes stale or broken domain lookups." },
];

function WhatItCleans() {
  return (
    <section id="what-it-cleans" className="py-28 px-6 bg-slate-50 dark:bg-gray-950 transition-colors">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-3">Fully transparent</p>
          <h2 className="text-4xl font-extrabold text-gray-950 dark:text-white tracking-tight mb-4">What It Actually Cleans</h2>
          <p className="text-lg text-gray-400 dark:text-gray-500 max-w-lg mx-auto">Every folder and file the script touches — nothing hidden, nothing extra.</p>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {CATEGORIES.map(c => (
            <div key={c.title} className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 hover:border-blue-100 dark:hover:border-blue-900 hover:shadow-md transition-all">
              <div className="flex items-start justify-between mb-3">
                <span className="text-2xl">{c.icon}</span>
                <span className="text-[10px] font-semibold text-gray-400 dark:text-gray-500 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 px-2 py-0.5 rounded-full">{c.count}</span>
              </div>
              <h3 className="font-bold text-gray-900 dark:text-white text-sm mb-1">{c.title}</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 leading-relaxed mb-3">{c.desc}</p>
              <ul className="space-y-0.5">
                {c.items.map(i => (
                  <li key={i} className="flex items-center gap-1.5 text-[11px] text-gray-500 dark:text-gray-400">
                    <span className="text-gray-300 dark:text-gray-600">›</span><span className="font-mono">{i}</span>
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
    { icon: "🔑", title: "Saved Passwords",  body: "Login Data files (Chrome, Edge, Brave, Vivaldi, Opera, Yandex) are explicitly skipped in every loop." },
    { icon: "📁", title: "Downloads Folder", body: "%USERPROFILE%\\Downloads is never read, listed, or modified." },
    { icon: "🗝️", title: "Firefox key4.db", body: "Firefox stores passwords in key4.db — it is hardcoded to be skipped every time." },
    { icon: "🖼️", title: "Personal Files",  body: "The script only targets known cache/temp directories — photos, docs, and videos are never touched." },
  ];
  return (
    <section id="safety" className="py-28 px-6 bg-white dark:bg-gray-900 transition-colors">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-green-600 dark:text-green-400 uppercase tracking-widest mb-3">Hardcoded exclusions</p>
          <h2 className="text-4xl font-extrabold text-gray-950 dark:text-white tracking-tight mb-4">What It Will <span className="text-green-600 dark:text-green-400">Never</span> Touch</h2>
          <p className="text-lg text-gray-400 dark:text-gray-500">These aren't settings — they're hardcoded exclusions in the script itself.</p>
        </div>
        <div className="grid sm:grid-cols-2 gap-4 mb-8">
          {never.map(n => (
            <div key={n.title} className="flex gap-4 p-5 rounded-2xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-800/50 shadow-sm hover:border-green-100 dark:hover:border-green-900 transition-colors">
              <span className="text-2xl mt-0.5">{n.icon}</span>
              <div>
                <p className="font-semibold text-gray-900 dark:text-white text-sm mb-1">{n.title}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">{n.body}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="bg-green-50 dark:bg-green-950/40 border border-green-100 dark:border-green-900/60 rounded-2xl p-6 text-center">
          <p className="font-semibold text-green-800 dark:text-green-300 mb-1">100% Open source batch scripts</p>
          <p className="text-sm text-green-700 dark:text-green-400">Open any file in Notepad before running — every line is readable plain text. No executables, no network calls, no telemetry.</p>
        </div>
      </div>
    </section>
  );
}

/* ─── FAQ ─────────────────────────────────────────────────────────── */
const FAQS = [
  {
    q: "Is it safe to run?",
    a: "Yes. The script only deletes known cache and temp directories — it never touches your personal files, photos, documents, or passwords. Every path it accesses is listed in the 'What It Cleans' section. You can open the .bat or .ps1 file in Notepad to read every line before running.",
  },
  {
    q: "Will it delete my saved passwords?",
    a: "Never. Login Data files for Chrome, Edge, Brave, Vivaldi, Opera, and Yandex are hardcoded to be skipped in every browser loop. Firefox's key4.db (password store) is also explicitly excluded. These exclusions are in the script itself — not a setting that can be changed by accident.",
  },
  {
    q: "Will it delete files from my Downloads folder?",
    a: "No. %USERPROFILE%\\Downloads is never read, listed, or touched by the script in any way.",
  },
  {
    q: "How do I check if the scheduler is running?",
    a: "Open PowerShell or Command Prompt and run: schtasks /query /tn \"MyCleanPC\"\n\nIf the task exists, it will show its next run time and status. If you see 'ERROR: The system cannot find the file specified' — the task isn't registered yet. Run your chosen frequency installer (e.g. schedule-1week.bat) as Administrator to set it up.",
  },
  {
    q: "How do I stop the automatic cleaning?",
    a: "Download and run uninstall.bat (or uninstall.ps1) as Administrator. It removes the MyCleanPC scheduled task and deletes the installed files from %LOCALAPPDATA%\\MyCleanPC\\. Your PC won't be cleaned automatically again unless you re-run a scheduler installer.",
  },
  {
    q: "Do I need administrator rights?",
    a: "The one-time cleaner (my-clean-pc.bat) runs fine without admin rights for most paths. However, the scheduler installers (schedule-*.bat / .ps1) and uninstaller require 'Run as Administrator' because they register or remove a Windows Task Scheduler entry.",
  },
  {
    q: "Will this slow down my computer?",
    a: "No — the opposite. The script removes junk files that waste disk space and can cause Explorer, browsers, and AI IDEs to slow down as caches grow. Cleaning periodically keeps these tools snappy. The script itself runs silently in the background and exits in seconds.",
  },
  {
    q: "Can I see what was deleted?",
    a: "The .bat version runs silently with no window or log. The .ps1 version prints colour-coded output so you can see each category as it's cleaned. If you want a permanent log, run the .ps1 version from a PowerShell window — you can scroll back through the session history.",
  },
];

function FAQ() {
  const [openIdx, setOpenIdx] = useState<number | null>(null);
  const toggle = (i: number) => setOpenIdx(prev => (prev === i ? null : i));
  return (
    <section id="faq" className="py-28 px-6 bg-slate-50 dark:bg-gray-950 transition-colors">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-widest mb-3">Common questions</p>
          <h2 className="text-4xl font-extrabold text-gray-950 dark:text-white tracking-tight mb-4">FAQ</h2>
          <p className="text-lg text-gray-400 dark:text-gray-500 max-w-md mx-auto">Everything you might want to know before running the scripts.</p>
        </div>

        <div className="space-y-2">
          {FAQS.map((faq, i) => (
            <div key={i} className="bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl overflow-hidden transition-all">
              <button
                onClick={() => toggle(i)}
                className="w-full flex items-center justify-between gap-4 px-6 py-5 text-left hover:bg-gray-50 dark:hover:bg-gray-800/60 transition-colors"
              >
                <span className="font-semibold text-gray-900 dark:text-white text-sm leading-snug">{faq.q}</span>
                <span className={`flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center border transition-all ${openIdx === i ? "border-blue-300 dark:border-blue-700 bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 rotate-45" : "border-gray-200 dark:border-gray-700 text-gray-400"}`}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                </span>
              </button>

              {openIdx === i && (
                <div className="px-6 pb-5 border-t border-gray-50 dark:border-gray-800">
                  <p className="text-sm text-gray-500 dark:text-gray-400 leading-relaxed whitespace-pre-line pt-4">
                    {faq.a.includes("schtasks") ? (
                      <>
                        {faq.a.split("\n\n")[0]}
                        <CodeBlock code='schtasks /query /tn "MyCleanPC"' />
                        <span className="block mt-3">{faq.a.split("\n\n").slice(1).join("\n\n")}</span>
                      </>
                    ) : faq.a}
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="mt-10 text-center">
          <p className="text-sm text-gray-400 dark:text-gray-500">Still have a question?</p>
          <a href="https://github.com/CRAJKUMARSINGH/My-Clean-PC/issues" target="_blank" rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 mt-1.5 transition-colors">
            Open an issue on GitHub
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
          </a>
        </div>
      </div>
    </section>
  );
}

/* ─── Download ────────────────────────────────────────────────────── */
const ALL_FILES = [
  { icon: "🦇", label: "Cleaner",          sub: "Run once silently",          file: "my-clean-pc.bat",     ext: ".bat", theme: "blue"  },
  { icon: "⚙️", label: "Cleaner PS",       sub: "Colour-coded output",        file: "my-clean-pc.ps1",     ext: ".ps1", theme: "slate" },
  { icon: "⚡", label: "Schedule 30 min",  sub: "Silent installer",           file: "schedule-30min.bat",  ext: ".bat", theme: "blue"  },
  { icon: "⚡", label: "Schedule 30 min",  sub: "Silent installer (PS)",      file: "schedule-30min.ps1",  ext: ".ps1", theme: "slate" },
  { icon: "📅", label: "Schedule Weekly",  sub: "Silent installer",           file: "schedule-1week.bat",  ext: ".bat", theme: "blue"  },
  { icon: "📅", label: "Schedule Weekly",  sub: "Silent installer (PS)",      file: "schedule-1week.ps1",  ext: ".ps1", theme: "slate" },
  { icon: "🌙", label: "Schedule 15 Days", sub: "Silent installer",           file: "schedule-15days.bat", ext: ".bat", theme: "blue"  },
  { icon: "🌙", label: "Schedule 15 Days", sub: "Silent installer (PS)",      file: "schedule-15days.ps1", ext: ".ps1", theme: "slate" },
  { icon: "🗑️", label: "Uninstall",        sub: "Remove task + files",        file: "uninstall.bat",       ext: ".bat", theme: "red"   },
  { icon: "🗑️", label: "Uninstall PS",     sub: "Remove task + files (PS)",   file: "uninstall.ps1",       ext: ".ps1", theme: "red"   },
];

function Download() {
  return (
    <section id="download" className="py-28 px-6 bg-gray-950 transition-colors">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <p className="text-xs font-semibold text-blue-400 uppercase tracking-widest mb-3">All files</p>
          <h2 className="text-4xl font-extrabold text-white tracking-tight mb-4">Download</h2>
          <p className="text-gray-400 text-lg max-w-md mx-auto">Every script as .bat and .ps1. All silent — no prompts, no menus.</p>
        </div>
        <div className="grid sm:grid-cols-2 gap-3">
          {ALL_FILES.map(f => (
            <a key={f.file} href={DL(f.file)} download={f.file}
              className="flex items-center gap-3.5 bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 rounded-2xl px-4 py-3.5 transition-all group">
              <span className="text-xl">{f.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-white">{f.label}
                  <span className={`ml-2 text-[10px] font-bold px-1.5 py-0.5 rounded ${f.theme === "blue" ? "bg-blue-600/30 text-blue-300" : f.theme === "red" ? "bg-red-600/30 text-red-300" : "bg-slate-600/40 text-slate-300"}`}>{f.ext}</span>
                </p>
                <p className="text-[11px] text-gray-500 truncate">{f.sub} — {f.file}</p>
              </div>
              <DownloadIcon size={14} />
            </a>
          ))}
        </div>
        <div className="mt-8 bg-white/5 border border-white/10 rounded-2xl p-5 space-y-3">
          <div>
            <p className="text-gray-600 text-[11px] font-mono mb-1"># PowerShell — run with bypass:</p>
            <CodeBlock code="PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1" dark />
          </div>
          <div>
            <p className="text-gray-600 text-[11px] font-mono mb-1"># Check your scheduled task:</p>
            <CodeBlock code='schtasks /query /tn "MyCleanPC"' dark />
          </div>
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

/* ─── Floating Download ───────────────────────────────────────────── */
function FloatingDownload() {
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const hero = document.querySelector("#hero-end");
    if (!hero) return;
    const observer = new IntersectionObserver(([entry]) => setVisible(!entry.isIntersecting), { threshold: 0 });
    observer.observe(hero);
    return () => observer.disconnect();
  }, []);
  return (
    <div className={`fixed bottom-6 right-6 z-50 flex flex-col items-end gap-2 transition-all duration-300 ${visible ? "opacity-100 translate-y-0 pointer-events-auto" : "opacity-0 translate-y-4 pointer-events-none"}`}>
      <div className="flex gap-2">
        <a href={DL("my-clean-pc.ps1")} download="my-clean-pc.ps1"
          className="flex items-center gap-2 bg-gray-800 hover:bg-gray-900 dark:bg-gray-700 dark:hover:bg-gray-600 text-white text-xs font-semibold px-4 py-2.5 rounded-full shadow-lg transition-colors">
          <DownloadIcon size={12} /> .ps1
        </a>
        <a href={DL("my-clean-pc.bat")} download="my-clean-pc.bat"
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold px-5 py-2.5 rounded-full shadow-xl shadow-blue-500/30 transition-colors">
          <DownloadIcon size={13} /> Download .bat
        </a>
      </div>
      <p className="text-[10px] text-gray-400 text-right pr-1">Free · No install needed</p>
    </div>
  );
}

/* ─── App ─────────────────────────────────────────────────────────── */
export default function App() {
  const [dark, setDark] = useState(() => window.matchMedia("(prefers-color-scheme: dark)").matches);
  const toggle = () => setDark(d => !d);

  return (
    <DarkCtx.Provider value={{ dark, toggle }}>
      <div className={`font-sans antialiased ${dark ? "dark" : ""}`}>
        <Navbar />
        <Hero />
        <div id="hero-end" aria-hidden="true" />
        <AutoClean />
        <WhatItCleans />
        <Safety />
        <FAQ />
        <Download />
        <Footer />
        <FloatingDownload />
      </div>
    </DarkCtx.Provider>
  );
}
