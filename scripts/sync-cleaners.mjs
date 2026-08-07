#!/usr/bin/env node
/**
 * Sync canonical cleaner scripts from scripts/ to public download folders.
 * Run: node scripts/sync-cleaners.mjs
 */
import { copyFileSync, mkdirSync, existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const scriptsDir = join(root, "scripts");
const publicDirs = [
  join(root, "artifacts", "mockup-sandbox", "public"),
  join(root, "artifacts", "my-clean-pc", "public"),
];

const pairs = [
  ["my-clean-pc.ps1", "my-clean-pc.ps1"],
  ["my-clean-pc.bat", "my-clean-pc.bat"],
  ["clean-pc-core.ps1", "clean-pc-core.ps1"],
  ["cleanup_task.ps1", "cleanup_task.ps1"],
  ["My-Clean-PC-GUI.ps1", "My-Clean-PC-GUI.ps1"],
  ["Launch-Clean-PC.bat", "Launch-Clean-PC.bat"],
  ["schedule-30min.bat", "schedule-30min.bat"],
  ["schedule-30min.ps1", "schedule-30min.ps1"],
  ["schedule-1week.bat", "schedule-1week.bat"],
  ["schedule-1week.ps1", "schedule-1week.ps1"],
  ["schedule-15days.bat", "schedule-15days.bat"],
  ["schedule-15days.ps1", "schedule-15days.ps1"],
  ["uninstall.bat", "uninstall.bat"],
  ["uninstall.ps1", "uninstall.ps1"],
  ["my-clean-pc-standalone.ps1", "my-clean-pc-standalone.ps1"],
];

for (const publicDir of publicDirs) {
  mkdirSync(publicDir, { recursive: true });
  for (const [src, dest] of pairs) {
    const from = join(scriptsDir, src);
    const to = join(publicDir, dest);
    if (!existsSync(from)) {
      console.warn(`skip (missing): ${src}`);
      continue;
    }
    copyFileSync(from, to);
    console.log(`synced: ${src} -> ${to}`);
  }
}

console.log("Done.");
