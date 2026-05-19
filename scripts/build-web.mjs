import { copyFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(root, "build", "web");

console.log("[build] flutter build web --release");
execSync("flutter build web --release --base-href=/", { cwd: root, stdio: "inherit" });

if (!existsSync(out)) {
  throw new Error(`Expected Flutter output at ${out}`);
}

const redirects = join(root, "public", "_redirects");
if (existsSync(redirects)) {
  copyFileSync(redirects, join(out, "_redirects"));
} else {
  writeFileSync(join(out, "_redirects"), "/*    /index.html   200\n", "utf8");
}

console.log("[build] Web bundle ready:", out);
