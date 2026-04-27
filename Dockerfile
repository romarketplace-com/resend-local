# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS deps
WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm fetch --frozen-lockfile

# -----------------------
# Builder
# -----------------------
FROM node:22-alpine AS builder
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN corepack enable

COPY --from=deps /root/.local/share/pnpm /root/.local/share/pnpm
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --offline

COPY . .

# Build application
RUN pnpm build

# Create persistent sqlite DB file during build so it can be copied into the runtime image
# This uses the `db:migrate` script defined in package.json which runs drizzle-kit push
RUN pnpm db:migrate

# -----------------------
# Runner
# -----------------------
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8005
ENV HOSTNAME=0.0.0.0
ENV DB_PATH=/data/resend-local.sqlite

RUN addgroup -S nodejs && adduser -S nextjs -G nodejs
RUN corepack enable

# runtime app only
COPY --from=builder --chown=nextjs:nodejs /app/dist ./
COPY --from=builder --chown=nextjs:nodejs /app/dist/app/init-server.js ./
# copy generated sqlite DB from builder into app directory so init script can move it into /data
COPY --from=builder --chown=nextjs:nodejs /app/resend-local.sqlite ./resend-local.sqlite

# ensure writable DB directory exists and is owned by runtime user
RUN mkdir -p /data && chown -R nextjs:nodejs /data && chmod 0777 /data

USER nextjs

EXPOSE 8005


# Start server with database initialization on startup
CMD ["sh", "-c", "cp ./resend-local.sqlite /data/resend-local.sqlite && chown -R nextjs:nodejs /data && node ./app/init-server.js"]