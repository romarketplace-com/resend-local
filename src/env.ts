import { z } from "zod";

const EnvSchema = z.object({
  DB_PATH: z.string().optional().default("./resend-local.sqlite"),
  DATABASE_URL: z.string().default("file::memory:?cache=shared"),
});

export const env = EnvSchema.parse({
  DB_PATH: process.env.DB_PATH,
  DATABASE_URL: process.env.DATABASE_URL,
} satisfies Record<keyof z.input<typeof EnvSchema>, unknown>);
