/**
 * Wrapper script to ensure database is initialized before starting the Next.js server
 * This is used in production Docker containers with ephemeral in-memory databases
 */

import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";
import * as fs from "node:fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function prepareDb() {
    try {
        const appDbPath = path.join(__dirname, "resend-local.sqlite");
        const dbPath = process.env.DB_PATH || "/data/resend-local.sqlite";
        const dbDir = path.dirname(dbPath);

        console.log(`🚀 Initializing Resend Local... PWD: ${__dirname}`);
        console.log(`📊 DB copy source: ${appDbPath}`);
        console.log(`📊 DB destination: ${dbPath}`);

        if (fs.existsSync(appDbPath)) {
            await fs.promises.mkdir(dbDir, { recursive: true });
            // ensure the target file is writable before copying over it
            try {
                await fs.promises.unlink(dbPath);
            } catch {
                // ignore missing file
            }
            // copy file into place (overwrite if exists)
            await fs.promises.copyFile(appDbPath, dbPath);
            await fs.promises.chmod(dbPath, 0o644);
            console.log(`✅ Copied DB to ${dbPath}`);
        } else {
            console.log("ℹ️  No pre-generated DB found in app directory; skipping copy");
        }

        // Always point the app at the writable DB path inside the container
        process.env.DATABASE_URL = `file:${dbPath}`;
        console.log(`ℹ️  Set DATABASE_URL=${process.env.DATABASE_URL}`);

        const stats = await fs.promises.stat(dbPath);
        console.log(`ℹ️  DB mode=${(stats.mode & 0o777).toString(8)} ownerWritable=${Boolean(stats.mode & 0o200)}`);
    } catch (err) {
        console.error("❌ Failed to prepare DB:", err);
        throw err;
    }
}

async function main() {
    try {
        await prepareDb();

        console.log("📢 Starting Next.js server...\n");

        const result = spawnSync("node", ["./server.js"], {
            cwd: __dirname,
            stdio: "inherit",
        });

        process.exit(result.status || 0);
    } catch (error) {
        console.error("❌ Failed to initialize server:", error);
        process.exit(1);
    }
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});
