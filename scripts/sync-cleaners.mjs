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
const publicDir = join(root, "artifacts", "mockup-sandbox", "public");

const pairs = [
  ["my-clean-pc.ps1", "my-clean-pc.ps1"],
  ["my-clean-pc.bat", "my-clean-pc.bat"],
  ["clean-pc-core.ps1", "clean-pc-core.ps1"],
  ["cleanup_task.ps1", "cleanup_task.ps1"],
];

mkdirSync(publicDir, { recursive: true });

for (const [src, dest] of pairs) {
  const from = join(scriptsDir, src);
  const to = join(publicDir, dest);
  if (!existsSync(from)) {
    console.warn(`skip (missing): ${src}`);
    continue;
  }
  copyFileSync(from, to);
  console.log(`synced: ${src} -> artifacts/mockup-sandbox/public/${dest}`);
}

console.log("Done.");
