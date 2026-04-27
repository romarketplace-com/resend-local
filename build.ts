import { spawnSync } from "node:child_process";
import fs from "fs-extra";
import esbuild from "esbuild";

console.log("building the next app");
const buildResult = spawnSync("pnpm", ["exec", "next", "build"], {
  stdio: "inherit",
  shell: true,
  env: {
    ...process.env,
  },
});

if (buildResult.status !== 0) {
  process.exit(1);
}

console.log("removing dist/app");
await fs.remove("dist/app");

console.log("copying files required for the app");
await fs.copy(".next/standalone", "dist/app");
await fs.copy(".next/static", "dist/app/.next/static");
await fs.copy("public", "dist/app/public");

console.log("generating database migrations for runtime initialization");
// Generate migrations to be used at container startup for schema initialization
const drizzleGenerateResult = spawnSync("pnpm", [
  "exec",
  "drizzle-kit",
  "generate",
  "--dialect",
  "sqlite",
  "--schema",
  "src/server/database/schema.ts",
  "--out",
  "dist/app/drizzle",
]);

if (drizzleGenerateResult.status !== 0) {
  console.error("Failed to generate migrations");
  // Don't fail the build - migrations will be generated at runtime if needed
  console.log("Continuing without pre-generated migrations");
}

console.log("building starter script");
esbuild.buildSync({
  entryPoints: ["src/starter.ts"],
  bundle: true,
  external: ["commander"],
  platform: "node",
  target: "node20",
  format: "esm",
  outfile: "dist/starter.js",
  banner: {
    js: `#! /usr/bin/env node`,
  },
});

console.log("building server initialization script");
esbuild.buildSync({
  entryPoints: ["src/init-server.ts"],
  bundle: true,
  platform: "node",
  target: "node20",
  format: "esm",
  outfile: "dist/app/init-server.js",
  banner: {
    js: `#! /usr/bin/env node`,
  },
});

console.log("done!");
