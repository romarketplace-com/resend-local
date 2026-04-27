import { migrate } from "drizzle-orm/libsql/migrator";
import path from "path";
import { fileURLToPath } from "url";
import { databaseClient } from "./client";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Run database migrations at startup
 * This ensures the schema is always initialized, especially important for ephemeral databases
 */
export async function initializeDatabase() {
  try {
    console.log("Initializing database schema...");
    
    // Try to run migrations from the generated drizzle folder
    const migrationsFolder = path.join(__dirname, "../../drizzle");
    
    try {
      await migrate(databaseClient, { migrationsFolder });
      console.log("Database migrations completed successfully");
    } catch (migrationError) {
      console.log("No pre-generated migrations found, schema will be created on demand");
    }
  } catch (error) {
    console.error("Failed to initialize database:", error);
    throw error;
  }
}
