'use strict'

/* ── DOM refs ─────────────────────────────────────────────────────────────── */
const btn          = document.getElementById('btn')
const log          = document.getElementById('log')
const dot          = document.getElementById('dot')
const logLabel     = document.getElementById('log-label')
const status       = document.getElementById('status')
const btnMin       = document.getElementById('btn-min')
const btnClose     = document.getElementById('btn-close')
const estimateCard = document.getElementById('estimate-card')
const ecValue      = document.getElementById('ec-value')
const ecSub        = document.getElementById('ec-sub')
const resultBanner = document.getElementById('result-banner')
const freedNumber  = document.getElementById('freed-number')
const freedUnit    = document.getElementById('freed-unit')
const freedCmp     = document.getElementById('freed-cmp')

/* ── Window controls ──────────────────────────────────────────────────────── */
btnMin.addEventListener('click',   () => window.api.minimize())
btnClose.addEventListener('click', () => window.api.close())

/* ── Helpers ─────────────────────────────────────────────────────────────── */
function formatBytes(bytes) {
  if (bytes >= 1e9) return { value: (bytes / 1e9).toFixed(2), unit: 'GB' }
  if (bytes >= 1e6) return { value: (bytes / 1e6).toFixed(1), unit: 'MB' }
  if (bytes >= 1e3) return { value: Math.round(bytes / 1e3),  unit: 'KB' }
  return { value: bytes, unit: 'B' }
}

/** Animate a numeric display from 0 up to `target` over `duration` ms */
function countUp(el, unitEl, targetBytes, duration = 1600) {
  const { value: targetVal, unit } = formatBytes(targetBytes)
  const target = parseFloat(targetVal)
  const decimals = targetVal.includes('.') ? targetVal.split('.')[1].length : 0
  unitEl.textContent = ' ' + unit
  const start = performance.now()
  function tick(now) {
    const progress = Math.min((now - start) / duration, 1)
    // Ease-out cubic
    const eased = 1 - Math.pow(1 - progress, 3)
    const current = (target * eased).toFixed(decimals)
    el.textContent = current
    if (progress < 1) requestAnimationFrame(tick)
  }
  requestAnimationFrame(tick)
}

function classifyLine(raw) {
  const t = raw.trim()
  if (!t) return 'l-muted'
  if (t === '============================================') return 'l-muted'
  if (t.startsWith('-- PRE-SCAN') || t.startsWith('  Estimated junk') || /^\s{4}/.test(t) && raw.includes(' KB') || /^\s{4}/.test(t) && raw.includes(' MB') || /^\s{4}/.test(t) && raw.includes(' GB')) return 'l-scan'
  if (t.startsWith('-- STEP'))                             return 'l-step'
  if (/Space freed this run/i.test(t))                     return 'l-freed'
  if (/That's like/i.test(t))                              return 'l-cmp'
  if (/THANKS CODEX/i.test(t))                             return 'l-thanks'
  if (/skipped|NOT touched|auto-skip/i.test(t))            return 'l-warn'
  if (/cleared|flushed|emptied|completed|freed|done/i.test(t)) return 'l-ok'
  return null
}

function appendLine(text, cls) {
  const div = document.createElement('div')
  if (cls) div.className = cls
  div.textContent = text
  log.appendChild(div)
  log.scrollTop = log.scrollHeight
}

/* ── Main clean flow ─────────────────────────────────────────────────────── */
btn.addEventListener('click', () => {
  // Reset everything
  log.innerHTML = ''
  estimateCard.classList.remove('visible')
  resultBanner.classList.remove('visible', 'glow')
  freedNumber.textContent = '0'
  freedUnit.textContent   = ''
  freedCmp.textContent    = ''
  window.api.removeAll()

  btn.disabled       = true
  dot.className      = 'dot scan'
  logLabel.textContent = 'Pre-scanning …'
  status.textContent = 'Scanning …'
  status.className   = 'scan'

  let inPrescan = true
  let freedBytes = 0

  window.api.onLine((rawLine) => {
    const line = rawLine

    // ── Machine-readable sentinels ────────────────────────────────────
    if (line.startsWith('PRESCAN_ESTIMATE:')) {
      const estStr = line.slice('PRESCAN_ESTIMATE:'.length).trim()
      ecValue.textContent = estStr
      estimateCard.classList.add('visible')
      return   // don't print to log
    }

    if (line.startsWith('FREED_BYTES:')) {
      freedBytes = parseInt(line.slice('FREED_BYTES:'.length).trim(), 10) || 0
      return   // don't print to log
    }

    // ── Phase transition: STEP 1 means real cleaning has started ──────
    if (inPrescan && /^-- STEP/.test(line.trim())) {
      inPrescan = false
      dot.className        = 'dot active'
      logLabel.textContent = 'Cleaning …'
      status.textContent   = 'Cleaning …'
      status.className     = 'running'
    }

    // ── Fun comparison line → stash it for the result banner ─────────
    if (/That's like/i.test(line)) {
      freedCmp.textContent = line.trim()
    }

    appendLine(line, classifyLine(line))
  })

  window.api.onDone(({ code }) => {
    dot.className        = 'dot done'
    btn.disabled         = false
    logLabel.textContent = code === 0 ? 'Done ✓' : `Finished (exit ${code})`
    status.textContent   = code === 0 ? 'All done!' : `Exited (code ${code})`
    status.className     = 'done'

    if (freedBytes > 0) {
      resultBanner.classList.add('visible')
      // Trigger glow animation
      void resultBanner.offsetWidth   // reflow so animation replays
      resultBanner.classList.add('glow')
      countUp(freedNumber, freedUnit, freedBytes, 1800)
    }
  })

  window.api.startClean()
})
