# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS deps
WORKDIR /app

# Better caching: install deps before copying the whole repo
COPY package.json pnpm-lock.yaml ./

# Corepack is built into modern Node images
RUN corepack enable && \
    pnpm fetch --frozen-lockfile

FROM node:22-alpine AS builder
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /root/.local/share/pnpm /root/.local/share/pnpm
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && \
    pnpm install --frozen-lockfile --offline

COPY . .
RUN pnpm build

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8005
ENV HOSTNAME=0.0.0.0

# Non-root runtime
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

# Copy only the standalone runtime and static assets
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# If the app writes a SQLite DB or request files locally, give it a writable dir
RUN mkdir -p /data && chown -R nextjs:nodejs /app /data

USER nextjs

EXPOSE 8005

CMD ["node", "server.js"]