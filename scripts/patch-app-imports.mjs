#!/usr/bin/env node
import { readFileSync, writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const appPath = join(dirname(fileURLToPath(import.meta.url)), "..", "artifacts", "my-clean-pc", "src", "App.tsx");
let src = readFileSync(appPath, "utf8");

if (!src.includes('@clean-pc/my-clean-pc.bat?raw')) {
  src = src.replace(
    'import { useState, useEffect, useRef, useCallback } from "react";',
    'import { useState, useEffect, useRef, useCallback } from "react";\nimport MY_CLEAN_PC_BAT from "@clean-pc/my-clean-pc.bat?raw";\nimport MY_CLEAN_PC_PS1 from "@clean-pc/my-clean-pc.ps1?raw";',
  );
}

const start = src.indexOf("/* ═══════════════════════════════════════════════════════\n   EMBEDDED WINDOWS SCRIPTS");
const guiStart = src.indexOf("/* ═══════════════════════════════════════════════════════\n   WINDOWS GUI LAUNCHER SCRIPT");

if (start === -1 || guiStart === -1) {
  console.log("Already patched or markers not found.");
  process.exit(0);
}

const replacement = `/* ═══════════════════════════════════════════════════════
   WINDOWS SCRIPTS (canonical: scripts/my-clean-pc.*)
═══════════════════════════════════════════════════════ */
const WIN_BAT = MY_CLEAN_PC_BAT;
const WIN_PS1 = MY_CLEAN_PC_PS1;

`;

src = src.slice(0, start) + replacement + src.slice(guiStart);
writeFileSync(appPath, src);
console.log("Patched App.tsx — removed embedded WIN_BAT/WIN_PS1, using @clean-pc imports.");
