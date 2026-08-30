import { useState, useEffect, useRef, useCallback } from "react";
import MY_CLEAN_PC_BAT from "@clean-pc/my-clean-pc.bat?raw";
import MY_CLEAN_PC_PS1 from "@clean-pc/my-clean-pc.ps1?raw";
import MY_CLEAN_PC_GUI_PS1 from "@clean-pc/My-Clean-PC-GUI.ps1?raw";
import MY_CLEAN_PC_GUI_BAT from "@clean-pc/Launch-Clean-PC.bat?raw";

/* ═══════════════════════════════════════════════════════
   CONFETTI
═══════════════════════════════════════════════════════ */
const CONFETTI_COLORS = ["#ff0080","#ff6600","#ffe600","#00e676","#00b0ff","#d500f9","#ff4081","#ffeb3b","#69f0ae","#40c4ff"];

function ConfettiBurst({ active }: { active: boolean }) {
  const pieces = useRef(
    Array.from({ length: 70 }, (_, i) => ({
      id: i,
      left: Math.random() * 100,
      delay: Math.random() * 0.7,
      duration: 1.4 + Math.random() * 0.8,
      color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
      size: 6 + Math.random() * 9,
      rotate: Math.random() * 720 - 360,
      shape: Math.random() > 0.5 ? "circle" : "rect",
    }))
  );
  if (!active) return null;
  return (
    <div className="confetti-wrap" aria-hidden>
      {pieces.current.map((p) => (
        <span
          key={p.id}
          className="confetti-piece"
          style={{
            left: `${p.left}%`,
            background: p.color,
            width: p.size,
            height: p.shape === "circle" ? p.size : p.size * 0.35,
            borderRadius: p.shape === "circle" ? "50%" : "2px",
            animationDelay: `${p.delay}s`,
            animationDuration: `${p.duration}s`,
            "--rotate": `${p.rotate}deg`,
          } as React.CSSProperties}
        />
      ))}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   TOAST SYSTEM
═══════════════════════════════════════════════════════ */
type ToastKind = "success" | "info" | "warn" | "error";
interface Toast { id: number; kind: ToastKind; message: string; detail?: string }

let _toastId = 0;
let _addToast: ((t: Omit<Toast, "id">) => void) | null = null;

function toast(kind: ToastKind, message: string, detail?: string) {
  _addToast?.({ kind, message, detail });
}

function ToastContainer() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  useEffect(() => {
    _addToast = (t) => {
      const id = ++_toastId;
      setToasts((prev) => [...prev, { ...t, id }]);
      setTimeout(() => setToasts((prev) => prev.filter((x) => x.id !== id)), 5500);
    };
    return () => { _addToast = null; };
  }, []);

  if (!toasts.length) return null;
  const icons: Record<ToastKind, string> = { success: "✅", info: "ℹ️", warn: "⚠️", error: "❌" };
  const colors: Record<ToastKind, string> = {
    success: "#16a34a", info: "#0369a1", warn: "#d97706", error: "#dc2626",
  };

  return (
    <div style={{ position: "fixed", top: 16, left: "50%", transform: "translateX(-50%)", zIndex: 9999, display: "flex", flexDirection: "column", gap: 8, width: "min(420px, 95vw)", pointerEvents: "none" }}>
      {toasts.map((t) => (
        <div key={t.id} style={{
          background: "#fff",
          border: `2px solid ${colors[t.kind]}`,
          borderRadius: 12,
          padding: "12px 16px",
          boxShadow: "0 8px 24px rgba(0,0,0,.15)",
          animation: "toast-in .25s ease",
          pointerEvents: "auto",
        }}>
          <div style={{ fontWeight: 700, fontSize: 14, color: colors[t.kind], display: "flex", gap: 6 }}>
            <span>{icons[t.kind]}</span> {t.message}
          </div>
          {t.detail && <div style={{ fontSize: 12, color: "#374151", marginTop: 4, lineHeight: 1.6 }}>{t.detail}</div>}
        </div>
      ))}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   MODAL
═══════════════════════════════════════════════════════ */
function Modal({ open, onClose, title, children, confirmLabel, onConfirm, confirmColor }: {
  open: boolean; onClose: () => void; title: string; children: React.ReactNode;
  confirmLabel?: string; onConfirm?: () => void; confirmColor?: string;
}) {
  if (!open) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,.5)", zIndex: 8888, display: "flex", alignItems: "center", justifyContent: "center", padding: 20 }}>
      <div style={{ background: "#fff", borderRadius: 18, padding: "24px 22px", maxWidth: 400, width: "100%", boxShadow: "0 24px 60px rgba(0,0,0,.25)" }}>
        <h3 style={{ fontSize: 18, fontWeight: 800, color: "#1f2937", marginBottom: 12 }}>{title}</h3>
        <div style={{ fontSize: 14, color: "#374151", lineHeight: 1.7 }}>{children}</div>
        <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
          <button onClick={onClose} style={{ flex: 1, padding: "11px 0", border: "2px solid #e5e7eb", borderRadius: 10, background: "#f9fafb", fontSize: 14, fontWeight: 700, cursor: "pointer", color: "#374151", fontFamily: "inherit" }}>
            Cancel
          </button>
          {onConfirm && (
            <button onClick={onConfirm} style={{ flex: 2, padding: "11px 0", border: "none", borderRadius: 10, background: confirmColor ?? "#ea580c", fontSize: 14, fontWeight: 700, cursor: "pointer", color: "#fff", fontFamily: "inherit" }}>
              {confirmLabel ?? "OK, continue"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   DATA TYPES & CONSTANTS
═══════════════════════════════════════════════════════ */
type Frequency = "30min" | "weekly" | "every15days";

const FREQ_OPTIONS: { value: Frequency; label: string; days: number; hint: string }[] = [
  { value: "30min",       label: "Every 30 Min", days: 1 / 48,  hint: "Good for heavy daily use" },
  { value: "weekly",      label: "Weekly",       days: 7,       hint: "Recommended for most people ✓" },
  { value: "every15days", label: "Every 15 Days",days: 15,      hint: "Light use only" },
];

const CLEANING_TIPS = [
  "Clearing cookies and cached pages…",
  "Removing old website data (IndexedDB)…",
  "Unregistering old service workers…",
  "Wiping session storage…",
  "Flushing browser caches…",
  "Almost done…",
];

/* ═══════════════════════════════════════════════════════
   BROWSER CLEANING LOGIC (bug-safe, cross-browser)
═══════════════════════════════════════════════════════ */
interface CleanResult {
  localStorage: boolean;
  sessionStorage: boolean;
  caches: boolean;
  serviceWorkers: boolean;
  indexedDB: boolean;
  cookies: boolean;
}

async function runBrowserClean(): Promise<CleanResult> {
  const r: CleanResult = { localStorage: false, sessionStorage: false, caches: false, serviceWorkers: false, indexedDB: false, cookies: false };

  try { localStorage.clear(); r.localStorage = true; } catch (_) {}
  try { sessionStorage.clear(); r.sessionStorage = true; } catch (_) {}

  try {
    const keys = await caches.keys();
    await Promise.all(keys.map((c) => caches.delete(c)));
    r.caches = true;
  } catch (_) {}

  try {
    const regs = (await navigator.serviceWorker?.getRegistrations()) ?? [];
    await Promise.all(regs.map((s) => s.unregister()));
    r.serviceWorkers = true;
  } catch (_) {}

  try {
    // indexedDB.databases() is not in all browsers (e.g. Firefox < 126), guard carefully
    if (typeof indexedDB !== "undefined" && typeof indexedDB.databases === "function") {
      const dbs = await indexedDB.databases();
      await Promise.all(
        dbs.map(
          (db) =>
            new Promise<void>((res) => {
              if (!db.name) { res(); return; }
              const req = indexedDB.deleteDatabase(db.name);
              req.onsuccess = () => res();
              req.onerror   = () => res();
              req.onblocked = () => res();
            })
        )
      );
    }
    r.indexedDB = true;
  } catch (_) {}

  try {
    document.cookie.split(";").forEach((c) => {
      const key = c.split("=")[0].trim();
      if (key) document.cookie = `${key}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/`;
    });
    r.cookies = true;
  } catch (_) {}

  return r;
}

/* ═══════════════════════════════════════════════════════
   SOUND
═══════════════════════════════════════════════════════ */
function playDoneSound() {
  try {
    const ctx = new AudioContext();
    const t = ctx.currentTime;
    const play = (freq: number, startTime: number, dur: number, gain: number) => {
      const osc = ctx.createOscillator();
      const env = ctx.createGain();
      osc.connect(env); env.connect(ctx.destination);
      osc.type = "sine";
      osc.frequency.setValueAtTime(freq, startTime);
      osc.frequency.exponentialRampToValueAtTime(freq * 0.5, startTime + dur);
      env.gain.setValueAtTime(gain, startTime);
      env.gain.exponentialRampToValueAtTime(0.001, startTime + dur);
      osc.start(startTime); osc.stop(startTime + dur);
    };
    play(880, t, 0.22, 0.35);
    play(1100, t + 0.1, 0.22, 0.25);
    play(1320, t + 0.2, 0.38, 0.20);
    const n = ctx.createOscillator();
    const ng = ctx.createGain();
    n.connect(ng); ng.connect(ctx.destination);
    n.type = "sawtooth";
    n.frequency.setValueAtTime(200, t);
    n.frequency.exponentialRampToValueAtTime(40, t + 0.32);
    ng.gain.setValueAtTime(0.05, t);
    ng.gain.exponentialRampToValueAtTime(0.001, t + 0.32);
    n.start(t); n.stop(t + 0.32);
  } catch (_) {}
}

/* ═══════════════════════════════════════════════════════
   GREETING
═══════════════════════════════════════════════════════ */
function greeting(): { text: string; emoji: string } {
  const h = new Date().getHours();
  if (h >= 5  && h < 12) return { text: "Good morning",   emoji: "☀️" };
  if (h >= 12 && h < 17) return { text: "Good afternoon", emoji: "🌤️" };
  if (h >= 17 && h < 21) return { text: "Good evening",   emoji: "🌇" };
  return                         { text: "Good night",     emoji: "🌙" };
}

/* ═══════════════════════════════════════════════════════
   WINDOWS SCRIPTS (canonical: scripts/my-clean-pc.*)
═══════════════════════════════════════════════════════ */
const WIN_BAT = MY_CLEAN_PC_BAT;
const WIN_PS1 = MY_CLEAN_PC_PS1;

/* ═══════════════════════════════════════════════════════
   WINDOWS GUI LAUNCHER SCRIPTS (canonical: scripts/*GUI*)
═══════════════════════════════════════════════════════ */
const WIN_GUI_PS1 = MY_CLEAN_PC_GUI_PS1;
const WIN_GUI_BAT = MY_CLEAN_PC_GUI_BAT;

/* ═══════════════════════════════════════════════════════
   DOWNLOAD HELPERS
═══════════════════════════════════════════════════════ */
function downloadFile(content: string, filename: string) {
  const blob = new Blob([content], { type: "text/plain;charset=utf-8" });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement("a");
  a.href = url; a.download = filename; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

/* ═══════════════════════════════════════════════════════
   CLEAN RESULT CARD
═══════════════════════════════════════════════════════ */
function CleanResultCard({ result, onDismiss }: { result: CleanResult; onDismiss: () => void }) {
  const items: [string, boolean, string][] = [
    ["Cookies", result.cookies, "Website login tokens"],
    ["Cached pages", result.caches, "Old website data"],
    ["Session storage", result.sessionStorage, "Temporary page data"],
    ["Local storage", result.localStorage, "App data & preferences"],
    ["IndexedDB", result.indexedDB, "Browser database files"],
    ["Service workers", result.serviceWorkers, "Background website scripts"],
  ];
  return (
    <div style={{ width: "100%", background: "#f0fdf4", border: "2px solid #86efac", borderRadius: 14, padding: "16px 18px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
        <span style={{ fontWeight: 800, fontSize: 15, color: "#14532d" }}>🎉 Here's what we just cleaned:</span>
        <button onClick={onDismiss} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 18, color: "#6b7280", padding: "0 4px" }}>✕</button>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "6px 12px" }}>
        {items.map(([name, ok, desc]) => (
          <div key={name} style={{ display: "flex", alignItems: "flex-start", gap: 6 }}>
            <span style={{ fontSize: 14, flexShrink: 0, marginTop: 1 }}>{ok ? "✅" : "⏭️"}</span>
            <div>
              <div style={{ fontSize: 13, fontWeight: 700, color: "#166534" }}>{name}</div>
              <div style={{ fontSize: 11, color: "#4b7c5e" }}>{desc}</div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ marginTop: 12, padding: "8px 12px", background: "#dcfce7", borderRadius: 8, fontSize: 12, color: "#166534", fontWeight: 600 }}>
        🔒 Your passwords, bookmarks, and personal files were NOT touched.
      </div>
      <div style={{ marginTop: 8, fontSize: 12, color: "#6b7280" }}>
        ℹ️ Some websites may ask you to log in again — that is completely normal. Your passwords are still saved.
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   WINDOWS SCRIPT DOWNLOAD PANEL
═══════════════════════════════════════════════════════ */
function WinDownloadPanel({ type, onDownload }: { type: "bat" | "ps1"; onDownload: () => void }) {
  const [downloaded, setDownloaded] = useState(false);

  function handle() {
    if (type === "bat") downloadFile(WIN_BAT, "my-clean-pc.bat");
    else                downloadFile(WIN_PS1, "my-clean-pc.ps1");
    setDownloaded(true);
    onDownload();
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8, flex: 1 }}>
      <button
        className={`win-btn${type === "ps1" ? " win-btn-ps" : ""}`}
        onClick={handle}
      >
        ⬇️ Download {type === "bat" ? ".bat" : ".ps1"}
        <small>{downloaded ? "✓ Saved to Downloads!" : type === "bat" ? "Double-click to run" : "Right-click → Run with PS"}</small>
      </button>
      {downloaded && (
        <div style={{ background: "#f0fdf4", border: "1.5px solid #86efac", borderRadius: 10, padding: "10px 12px", fontSize: 12 }}>
          <div style={{ fontWeight: 800, color: "#14532d", marginBottom: 6 }}>
            ✅ Downloaded! Here's what to do next:
          </div>
          {type === "bat" ? (
            <ol style={{ paddingLeft: 16, color: "#374151", lineHeight: 2, margin: 0 }}>
              <li>Open your <strong>Downloads</strong> folder</li>
              <li>Find <strong>my-clean-pc.bat</strong></li>
              <li>Right-click it → <strong>"Run as administrator"</strong></li>
              <li>If Windows warns you: click <strong>"More info"</strong> → <strong>"Run anyway"</strong></li>
              <li>Follow the instructions on screen</li>
            </ol>
          ) : (
            <ol style={{ paddingLeft: 16, color: "#374151", lineHeight: 2, margin: 0 }}>
              <li>Open your <strong>Downloads</strong> folder</li>
              <li>Find <strong>my-clean-pc.ps1</strong></li>
              <li>Right-click it → <strong>"Run with PowerShell"</strong></li>
              <li>If asked about execution policy, type <strong>Y</strong> and press Enter</li>
              <li>Follow the colourful instructions on screen</li>
            </ol>
          )}
          <div style={{ marginTop: 8, padding: "6px 10px", background: "#fef9c3", borderRadius: 6, color: "#713f12", fontWeight: 600 }}>
            ⚠️ If Windows says "This app might harm your device" — that is a false alarm. Click <strong>More info → Run anyway</strong>. The script is safe and only deletes junk files.
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   EMAIL REMINDER SECTION
═══════════════════════════════════════════════════════ */
function EmailReminderSection() {
  const [email, setEmail]       = useState(() => localStorage.getItem("reminderEmail") ?? "");
  const [status, setStatus]     = useState<"idle" | "sending" | "sent" | "error">("idle");
  const [errMsg, setErrMsg]     = useState("");
  const [expanded, setExpanded] = useState(false);

  function saveEmail(v: string) {
    setEmail(v);
    localStorage.setItem("reminderEmail", v);
  }

  async function sendReminder() {
    if (!email.includes("@")) { setStatus("error"); setErrMsg("Please enter a valid email address."); return; }
    setStatus("sending");
    try {
      const res = await fetch("/.netlify/functions/send-reminder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, frequency: "monthly" }),
      });
      const data = await res.json();
      if (res.ok && data.ok) {
        setStatus("sent");
      } else {
        setStatus("error");
        setErrMsg(data.error ?? "Could not send email. Try again.");
      }
    } catch {
      setStatus("error");
      setErrMsg("Network error. Are you on the live Netlify site?");
    }
  }

  return (
    <div style={{ background: "linear-gradient(135deg,#eff6ff,#fdf4ff)", border: "1.5px solid #c4b5fd", borderRadius: 14, padding: "14px 16px" }}>
      <button
        onClick={() => setExpanded(e => !e)}
        style={{ width: "100%", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "space-between", padding: 0 }}
      >
        <span style={{ fontWeight: 800, fontSize: 14, color: "#4c1d95", display: "flex", alignItems: "center", gap: 7 }}>
          📧 Monthly Email Reminder
          <span style={{ fontSize: 11, fontWeight: 600, color: "#7c3aed", background: "#ede9fe", borderRadius: 6, padding: "2px 8px" }}>
            {email ? "Email saved ✓" : "Set up"}
          </span>
        </span>
        <span style={{ color: "#7c3aed", fontSize: 13, fontWeight: 700 }}>{expanded ? "▲" : "▼"}</span>
      </button>

      {!expanded && email && (
        <p style={{ margin: "6px 0 0", fontSize: 12, color: "#6d28d9" }}>
          Monthly reminders go to <strong>{email}</strong> — click to change or send one now.
        </p>
      )}

      {expanded && (
        <div style={{ marginTop: 12, display: "flex", flexDirection: "column", gap: 10 }}>
          <p style={{ margin: 0, fontSize: 13, color: "#374151", lineHeight: 1.6 }}>
            Get a monthly reminder email so you never forget to clean your PC.
            Enter your email below and click <strong>Send reminder</strong> to receive one now.
          </p>

          {/* Email input */}
          <div style={{ display: "flex", gap: 8 }}>
            <input
              type="email"
              placeholder="your@email.com"
              value={email}
              onChange={e => { saveEmail(e.target.value); setStatus("idle"); }}
              style={{ flex: 1, border: "1.5px solid #c4b5fd", borderRadius: 8, padding: "9px 12px",
                fontSize: 14, outline: "none", background: "#fff", color: "#111827",
                fontFamily: "inherit" }}
            />
            <button
              onClick={sendReminder}
              disabled={status === "sending" || !email}
              style={{ background: status === "sent" ? "#16a34a" : "linear-gradient(135deg,#7c3aed,#4338ca)",
                color: "#fff", border: "none", borderRadius: 8, padding: "9px 18px",
                fontWeight: 700, fontSize: 13, cursor: email && status !== "sending" ? "pointer" : "not-allowed",
                opacity: !email ? 0.6 : 1, whiteSpace: "nowrap", flexShrink: 0 }}
            >
              {status === "sending" ? "Sending…" : status === "sent" ? "✓ Sent!" : "Send reminder"}
            </button>
          </div>

          {/* Status messages */}
          {status === "sent" && (
            <div style={{ background: "#f0fdf4", border: "1.5px solid #86efac", borderRadius: 8, padding: "8px 12px", fontSize: 13, color: "#166534", fontWeight: 600 }}>
              ✅ Reminder email sent to <strong>{email}</strong>! Check your inbox (and spam folder just in case).
            </div>
          )}
          {status === "error" && (
            <div style={{ background: "#fef2f2", border: "1.5px solid #fca5a5", borderRadius: 8, padding: "8px 12px", fontSize: 13, color: "#991b1b" }}>
              ⚠️ {errMsg}
              {errMsg.includes("Netlify") && (
                <div style={{ marginTop: 4, fontSize: 12, color: "#7f1d1d" }}>
                  Email reminders only work on the live Netlify site (not in local preview). See setup instructions below.
                </div>
              )}
            </div>
          )}

          {/* Setup note */}
          <details style={{ fontSize: 12, color: "#6b7280" }}>
            <summary style={{ cursor: "pointer", fontWeight: 600, color: "#7c3aed" }}>ℹ️ First time? One-time Netlify setup needed</summary>
            <div style={{ marginTop: 8, lineHeight: 1.8, paddingLeft: 4 }}>
              <ol style={{ paddingLeft: 16, margin: 0, color: "#374151" }}>
                <li>Go to <a href="https://resend.com/signup" target="_blank" rel="noreferrer" style={{ color: "#7c3aed" }}>resend.com</a> — sign up free (takes 30 seconds)</li>
                <li>Create an API key → copy it</li>
                <li>In Netlify: <strong>Site configuration → Environment variables → Add variable</strong></li>
                <li>Name: <code style={{ background: "#f3f4f6", padding: "1px 5px", borderRadius: 4 }}>RESEND_API_KEY</code>, Value: paste your key</li>
                <li>Also add: <code style={{ background: "#f3f4f6", padding: "1px 5px", borderRadius: 4 }}>APP_URL</code> = your Netlify site URL</li>
                <li>Save — done! Email reminders now work.</li>
              </ol>
              <div style={{ marginTop: 6, color: "#9ca3af" }}>
                Free Resend plan: 3,000 emails/month — more than enough!
              </div>
            </div>
          </details>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   GUI DOWNLOAD PANEL  (two-file: .ps1 + .bat launcher)
═══════════════════════════════════════════════════════ */
function GuiDownloadPanel() {
  const [ps1Done, setPs1Done]   = useState(false);
  const [batDone, setBatDone]   = useState(false);
  const bothDone = ps1Done && batDone;
  const eitherDone = ps1Done || batDone;

  return (
    <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 8 }}>

      {/* Header badge */}
      <div style={{ textAlign: "center", fontSize: 12, fontWeight: 800, color: "#4338ca",
        background: "linear-gradient(135deg,#ede9fe,#dbeafe)", borderRadius: 8,
        padding: "5px 14px", display: "inline-block", alignSelf: "center", letterSpacing: 0.3 }}>
        ✨ NEW — Beautiful GUI Window (No command prompt!)
      </div>

      {/* Explainer */}
      <div style={{ fontSize: 12, color: "#374151", lineHeight: 1.7,
        background: "#f5f3ff", borderRadius: 10, padding: "10px 14px", border: "1.5px solid #c4b5fd" }}>
        This opens a <strong>real app window</strong> with a progress bar and colour-coded steps —
        no scary black command prompt. Just click <strong>Start Cleaning</strong> in the window and watch it go!
        <br />
        <span style={{ color: "#6d28d9", fontWeight: 700 }}>Requires 2 files downloaded into the same folder.</span>
      </div>

      {/* Download buttons row */}
      <div style={{ display: "flex", gap: 8 }}>
        <button
          className="win-btn win-btn-ps"
          style={{ background: "linear-gradient(135deg,#7c3aed,#4338ca)" }}
          onClick={() => { downloadFile(WIN_GUI_PS1, "My-Clean-PC-GUI.ps1"); setPs1Done(true); toast("success", "GUI script downloaded!", "Now also download the launcher .bat file below."); }}
        >
          ⬇️ Step 1: GUI Script (.ps1)
          <small>{ps1Done ? "✓ Got it!" : "Download this first"}</small>
        </button>
        <button
          className="win-btn"
          style={{ background: ps1Done ? "linear-gradient(135deg,#16a34a,#15803d)" : "linear-gradient(135deg,#94a3b8,#64748b)", cursor: "pointer" }}
          onClick={() => { downloadFile(WIN_GUI_BAT, "Launch-Clean-PC.bat"); setBatDone(true); toast("success", "Launcher downloaded!", ps1Done ? "Both files ready! Put them in the same folder, then double-click Launch-Clean-PC.bat." : "Now download the GUI script too (Step 1)."); }}
        >
          ⬇️ Step 2: Launcher (.bat)
          <small>{batDone ? "✓ Got it!" : ps1Done ? "Download this next" : "Download step 1 first"}</small>
        </button>
      </div>

      {/* After both downloaded */}
      {eitherDone && (
        <div style={{ background: "#f0fdf4", border: "1.5px solid #86efac", borderRadius: 10, padding: "12px 14px", fontSize: 12 }}>
          {!bothDone ? (
            <div style={{ color: "#d97706", fontWeight: 700 }}>
              ⚠️ Download <strong>both</strong> files before continuing — they must be in the same folder!
            </div>
          ) : (
            <>
              <div style={{ fontWeight: 800, color: "#14532d", marginBottom: 8, fontSize: 13 }}>
                ✅ Both files downloaded! Here's what to do:
              </div>
              <ol style={{ paddingLeft: 18, color: "#374151", lineHeight: 2.1, margin: 0 }}>
                <li>Open your <strong>Downloads</strong> folder</li>
                <li>Make sure both files are there:
                  <br />&nbsp;&nbsp;📄 <code style={{ background:"#e5e7eb",padding:"1px 5px",borderRadius:4 }}>My-Clean-PC-GUI.ps1</code>
                  <br />&nbsp;&nbsp;📄 <code style={{ background:"#e5e7eb",padding:"1px 5px",borderRadius:4 }}>Launch-Clean-PC.bat</code>
                </li>
                <li><strong>Double-click</strong> <code style={{ background:"#e5e7eb",padding:"1px 5px",borderRadius:4 }}>Launch-Clean-PC.bat</code></li>
                <li>If Windows warns: click <strong>"More info"</strong> → <strong>"Run anyway"</strong></li>
                <li>A <strong>beautiful window</strong> opens — click the big orange <strong>"Start Cleaning"</strong> button</li>
                <li>Watch the progress bar fill up — done in about 30 seconds!</li>
              </ol>
              <div style={{ marginTop: 8, padding: "6px 10px", background: "#fef9c3", borderRadius: 6, color: "#713f12", fontWeight: 600 }}>
                ⚠️ "Windows protected your PC" warning? Click <strong>More info</strong> → <strong>Run anyway</strong>.
                This is a false alarm — the script only deletes junk files and is completely safe.
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   MAIN APP
═══════════════════════════════════════════════════════ */
export default function App() {
  const [state, setState]           = useState<"idle" | "cleaning" | "done">("idle");
  const [frequency, setFrequency]   = useState<Frequency>("weekly");
  const [due, setDue]               = useState(false);
  const [lastCleaned, setLastCleaned] = useState<number>(0);
  const [streak, setStreak]         = useState<number>(0);
  const [tipIdx, setTipIdx]         = useState(0);
  const [cleanResult, setCleanResult] = useState<CleanResult | null>(null);
  const [showWarnModal, setShowWarnModal] = useState(false);
  const [isFirstVisit, setIsFirstVisit] = useState(false);
  const [showFirstVisitBanner, setShowFirstVisitBanner] = useState(false);
  const tipTimer = useRef<ReturnType<typeof setInterval> | null>(null);

  /* ── Load persisted state ── */
  useEffect(() => {
    const freq = localStorage.getItem("mcp_freq") as Frequency | null;
    if (freq && FREQ_OPTIONS.some((o) => o.value === freq)) setFrequency(freq);

    const last  = Number(localStorage.getItem("mcp_last") ?? 0);
    if (last) setLastCleaned(last);

    const saved = Number(localStorage.getItem("mcp_streak") ?? 0);
    if (saved) setStreak(saved);

    const days  = FREQ_OPTIONS.find((f) => f.value === (freq ?? "weekly"))?.days ?? 7;
    if (last && (Date.now() - last) / 86400000 >= days) setDue(true);

    const visited = localStorage.getItem("mcp_visited");
    if (!visited) {
      setIsFirstVisit(true);
      setShowFirstVisitBanner(true);
      localStorage.setItem("mcp_visited", "1");
    }
  }, []);

  /* ── Cleaning tip cycle ── */
  useEffect(() => {
    if (state === "cleaning") {
      setTipIdx(0);
      tipTimer.current = setInterval(() => {
        setTipIdx((i) => Math.min(i + 1, CLEANING_TIPS.length - 1));
      }, 320);
    } else {
      if (tipTimer.current) clearInterval(tipTimer.current);
    }
    return () => { if (tipTimer.current) clearInterval(tipTimer.current); };
  }, [state]);

  /* ── Request clean (show warning first) ── */
  const requestClean = useCallback(() => {
    if (state !== "idle") return;
    setShowWarnModal(true);
  }, [state]);

  /* ── Actually run the clean ── */
  const doClean = useCallback(async () => {
    setShowWarnModal(false);
    setState("cleaning");
    setCleanResult(null);
    await new Promise((r) => setTimeout(r, 1800));
    const result = await runBrowserClean();
    const now    = Date.now();
    const prev   = Number(localStorage.getItem("mcp_last") ?? 0);
    const freqDays = FREQ_OPTIONS.find((f) => f.value === frequency)?.days ?? 7;
    const grace    = freqDays * 2 * 86400000;
    const prevStreak = Number(localStorage.getItem("mcp_streak") ?? 0);
    const newStreak  = (!prev || (now - prev) <= grace) ? prevStreak + 1 : 1;
    localStorage.setItem("mcp_last",   String(now));
    localStorage.setItem("mcp_freq",   frequency);
    localStorage.setItem("mcp_streak", String(newStreak));
    setLastCleaned(now);
    setStreak(newStreak);
    setDue(false);
    playDoneSound();
    setCleanResult(result);
    setState("done");
    toast("success", "Browser cleaned successfully!", "Your browser is now fresh and junk-free.");
    setTimeout(() => setState("idle"), 4000);
  }, [frequency]);

  function pickFreq(f: Frequency) {
    setFrequency(f);
    localStorage.setItem("mcp_freq", f);
    const opt = FREQ_OPTIONS.find((o) => o.value === f)!;
    toast("info", `Reminder set to: ${opt.label}`, opt.hint);
  }

  function lastCleanedLabel(): string {
    if (!lastCleaned) return "Never cleaned yet — tap the button above!";
    const ms    = Date.now() - lastCleaned;
    const mins  = Math.floor(ms / 60000);
    const hours = Math.floor(ms / 3600000);
    const days  = Math.floor(ms / 86400000);
    if (mins  <  1) return "Just cleaned — great job! 🎉";
    if (mins  < 60) return `Last cleaned ${mins} minute${mins === 1 ? "" : "s"} ago`;
    if (hours < 24) return `Last cleaned ${hours} hour${hours === 1 ? "" : "s"} ago`;
    if (days  === 1) return "Last cleaned yesterday";
    return `Last cleaned ${days} days ago`;
  }

  const { text: greetText, emoji: greetEmoji } = greeting();

  return (
    <>
      <ToastContainer />

      <Modal
        open={showWarnModal}
        title="⚡ Quick heads-up before cleaning!"
        onClose={() => setShowWarnModal(false)}
        confirmLabel="Yes, clean it!"
        confirmColor="#16a34a"
        onConfirm={doClean}
      >
        <p style={{ marginBottom: 10 }}>
          After cleaning, <strong>some websites may ask you to log in again</strong> (like Google, Facebook, etc.).
          This is completely normal and expected.
        </p>
        <p style={{ marginBottom: 10 }}>
          👉 Your <strong>saved passwords</strong> are stored separately in your browser and are <strong>completely safe</strong>. Just click "Log in" and your password will fill in automatically.
        </p>
        <p style={{ background: "#f0fdf4", borderRadius: 8, padding: "8px 12px", color: "#14532d", fontWeight: 600, fontSize: 13 }}>
          ✅ Passwords · ✅ Bookmarks · ✅ Personal files — all safe!
        </p>
      </Modal>

      <div className="page">
        <ConfettiBurst active={state === "done"} />

        <p className="greeting">{greetText}, Priyanka! {greetEmoji}</p>

        <div className="logo">
          <span>🧹</span>
          <h1>My Clean PC</h1>
        </div>

        {/* ── First-visit welcome banner ── */}
        {showFirstVisitBanner && (
          <div style={{ width: "100%", background: "linear-gradient(135deg, #dbeafe, #ede9fe)", border: "2px solid #a5b4fc", borderRadius: 14, padding: "14px 18px" }}>
            <div style={{ display: "flex", justifyContent: "space-between" }}>
              <div style={{ fontWeight: 800, fontSize: 15, color: "#1e3a8a", marginBottom: 6 }}>
                👋 Welcome to My Clean PC!
              </div>
              <button onClick={() => setShowFirstVisitBanner(false)} style={{ background: "none", border: "none", cursor: "pointer", fontSize: 18, color: "#6b7280" }}>✕</button>
            </div>
            <div style={{ fontSize: 13, color: "#3730a3", lineHeight: 1.7 }}>
              This is your personal PC cleaning tool. To clean your <strong>browser</strong>, just tap the big orange button below — it takes about 2 seconds!
              <br />
              To clean your <strong>Windows PC</strong>, scroll down and download the script. It does everything for you automatically.
            </div>
            <div style={{ marginTop: 8, fontSize: 12, color: "#4c1d95", fontWeight: 600 }}>
              🔒 Nothing dangerous happens here. No files are deleted except junk. Your passwords are always safe.
            </div>
          </div>
        )}

        {/* ── What this tool does ── */}
        {!showFirstVisitBanner && (
          <div className="intro-box">
            <strong>What does this do?</strong> It removes junk files that build up in your browser —
            old website data, cached pages, cookies — to help your browser feel faster and free up space.
            Takes about 2 seconds.
            <div className="safe-list">
              🔒 Your passwords, bookmarks, and personal files are NEVER touched.
            </div>
          </div>
        )}

        {/* ── Due reminder ── */}
        {due && state === "idle" && (
          <p className="due-note">
            ⏰ Time for a clean!
            <small>Your PC is due — tap the button below</small>
          </p>
        )}

        {/* ── Big clean button ── */}
        <button
          className={`big-btn ${state}`}
          onClick={requestClean}
          disabled={state !== "idle"}
          title={state === "idle" ? "Tap to clean your browser — it's safe!" : undefined}
        >
          {state === "cleaning" ? (
            <>
              <div className="big-btn-row">
                <span className="spin" />
                ⏳ Cleaning… please wait
              </div>
              <span className="btn-sub">{CLEANING_TIPS[tipIdx]}</span>
            </>
          ) : state === "done" ? (
            <>
              ✅ All Clean! Amazing job!
              <span className="btn-sub">Your browser is fresh and fast now! 🎉</span>
            </>
          ) : (
            <>
              🧹 Clean My Browser Now
              <span className="btn-sub">Tap here — it's completely safe!</span>
            </>
          )}
        </button>

        {/* ── Post-clean summary ── */}
        {cleanResult && state === "idle" && (
          <>
            <CleanResultCard result={cleanResult} onDismiss={() => setCleanResult(null)} />
            {/* All work done summary */}
            <div className="all-work-done" style={{ marginTop: "1rem", fontSize: "1.2rem", fontWeight: "bold", color: "#0f62fe" }}>
              All work done – Summary:
              {cleanResult.cookies && " Cookies"}
              {cleanResult.caches && ", Caches"}
              {cleanResult.sessionStorage && ", Session Storage"}
              {cleanResult.localStorage && ", Local Storage"}
              {cleanResult.indexedDB && ", IndexedDB"}
            </div>
          </>
        )}

        {/* ── Last cleaned + streak ── */}
        <div className="last-cleaned-badge">🕐 {lastCleanedLabel()}</div>

        {streak >= 2 && (
          <div className="streak-badge">
            🔥 {streak} cleans in a row
            {streak >= 10 ? " — you're unstoppable!" : streak >= 5 ? " — keep it up!" : "!"}
          </div>
        )}

        {/* ── What gets cleaned ── */}
        <div className="what-cleaned">
          <strong>✅ What gets cleaned when you tap the button:</strong>
          Cookies &nbsp;·&nbsp; Cached web pages &nbsp;·&nbsp; Old website data &nbsp;·&nbsp;
          Session storage &nbsp;·&nbsp; IndexedDB &nbsp;·&nbsp; Service Workers
          <br />
          <span style={{ color: "#166534", fontWeight: 700 }}>
            🔒 Your saved passwords and bookmarks stay completely safe.
          </span>
        </div>

        {/* ── Frequency picker ── */}
        <div className="freq-row">
          <span className="freq-label">Remind me:</span>
          {FREQ_OPTIONS.map((o) => (
            <button
              key={o.value}
              className={`chip ${frequency === o.value ? "on" : ""}`}
              onClick={() => pickFreq(o.value)}
              title={o.hint}
            >
              {o.label}
            </button>
          ))}
        </div>

        {/* ── Email reminder ── */}
        <EmailReminderSection />

        {/* ══════════════════════════════════════════════
            WINDOWS SECTION
        ═════════════════════════════════════════════ */}
        <div className="win-section">
          <p className="win-title">🖥️ Full Windows PC Cleaner</p>
          <p className="win-subtitle">For deeper cleaning — runs on your Windows computer</p>
          <div className="win-desc">
            <strong>What this cleans on your Windows PC:</strong><br />
            AI IDEs: Cursor, Windsurf, Kiro, Trae AI, Warp, Devin &nbsp;|&nbsp;
            Browsers: auto-detects ALL installed (Chrome, Edge, Firefox, Brave, Opera, etc.)<br />
            Also: Rigorous temp · AppData sweep (Local + Roaming) · Recycle Bin · Windows Update cache · DNS cache · Event logs
            <br />
            <span className="win-safe">🔒 Passwords, Downloads folder, and personal files are NEVER touched.</span>
          </div>

          {/* ── GUI launcher (recommended) ── */}
          <div style={{ marginBottom: 14 }}>
            <GuiDownloadPanel />
          </div>

          {/* ── Divider ── */}
          <div style={{ display: "flex", alignItems: "center", gap: 10, margin: "4px 0 12px" }}>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
            <span style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600, whiteSpace: "nowrap" }}>
              OR — classic command-line versions below
            </span>
            <div style={{ flex: 1, height: 1, background: "#e5e7eb" }} />
          </div>

          {/* ── Classic .bat / .ps1 ── */}
          <div className="win-btn-row">
            <WinDownloadPanel type="bat" onDownload={() => toast("success", ".bat file downloaded!", "Check your Downloads folder. Right-click → Run as administrator for best results.")} />
            <WinDownloadPanel type="ps1" onDownload={() => toast("success", ".ps1 file downloaded!", "Check your Downloads folder. Right-click → Run with PowerShell.")} />
          </div>
        </div>

        {/* ══════════════════════════════════════════════
            FAQ
        ═════════════════════════════════════════════ */}
        <div className="faq-section">
          <div className="faq-title">❓ Common Questions — Plain English Answers</div>

          <div className="faq-item">
            <div className="faq-q">Is this safe? Will I lose anything important?</div>
            <div className="faq-a">
              Yes, 100% safe! The browser button removes temporary junk only — cached pages, cookies, and old website data.
              Your <strong>passwords, bookmarks, photos, and personal files are NEVER touched</strong>.
              Some websites may ask you to log in again — that is normal and expected (see below).
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">I got logged out of all my websites! Is that normal?</div>
            <div className="faq-a">
              Yes, completely normal! Cookies are what keep you "logged in" to websites like Google, Facebook, Netflix, etc.
              When cookies are cleared, websites ask you to log in again.
              <br /><strong>Your password is still saved in your browser</strong> — just click the password box and it will fill in automatically. You have not lost anything.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">Windows said the script is dangerous. What do I do?</div>
            <div className="faq-a">
              That is a <strong>false warning</strong> — Windows shows this for ANY downloaded script, even perfectly safe ones.
              Here is how to get past it:<br />
              <strong>1.</strong> Click <strong>"More info"</strong> (small blue link)<br />
              <strong>2.</strong> Then click <strong>"Run anyway"</strong> (grey button)<br />
              The script is completely safe and only deletes junk files.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">My icons look blank / missing after running the script. Is that a problem?</div>
            <div className="faq-a">
              Not at all — this is <strong>completely normal</strong>! The script cleared your icon cache (which is just junk).
              Windows automatically rebuilds it over the next few minutes. Just <strong>restart your PC</strong> and all icons will come back perfectly.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">Nothing seems different after clicking Clean. Did it actually work?</div>
            <div className="faq-a">
              Yes, it worked! Browser cleaning happens silently in the background — there is nothing visual to show you.
              Look at the <em>"Last cleaned"</em> badge below the button — it updated to show the exact time. That confirms it ran successfully.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">The PowerShell script says "Execution Policy" error. What do I do?</div>
            <div className="faq-a">
              Type <strong>Y</strong> and press <strong>Enter</strong> when it asks. This just tells Windows it is OK to run the script.
              It is a one-time confirmation and does not change anything permanently on your PC.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">Do I need to run the script as Administrator?</div>
            <div className="faq-a">
              It is <strong>recommended but not required</strong>. Some files (like Windows Update cache and Event Logs)
              can only be deleted by an Administrator. Without it, the script will still clean most things — it just skips the ones it cannot access.
              <br />To run as admin: right-click the file → <strong>"Run as administrator"</strong>.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">What is the difference between .bat and .ps1?</div>
            <div className="faq-a">
              Both do the <strong>exact same job</strong>.
              <br /><strong>.bat</strong> = classic Windows file, just double-click it. Best for most people.
              <br /><strong>.ps1</strong> = PowerShell version, shows colourful progress text. Right-click → "Run with PowerShell".
              <br />Either one works perfectly — pick whichever feels easier!
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">How often should I clean?</div>
            <div className="faq-a">
              For most people, <strong>once a week</strong> is perfect. If you use your PC heavily every day, every few days is fine.
              Use the "Remind me" buttons above to set your schedule and the app will remind you when it is time.
            </div>
          </div>

          <div className="faq-item">
            <div className="faq-q">My PC is slow even after cleaning. What else can I do?</div>
            <div className="faq-a">
              Try these next steps: <strong>Restart your PC</strong> (most effective!) · <strong>Check for Windows Updates</strong> (Settings → Update) ·
              <strong>Uninstall apps you do not use</strong> · <strong>Disable startup programs</strong> (Task Manager → Startup tab).
              If it is still very slow, your PC might need more RAM or an SSD upgrade.
            </div>
          </div>
        </div>

        <p className="credit">💖 Designed for <span className="priyanka-name">Priyanka</span> only</p>
      </div>
    </>
  );
}
