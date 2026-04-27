# syntax=docker/dockerfile:1.7

# -----------------------
# Deps
# -----------------------
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
RUN pnpm build

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

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# RUN chown -R nextjs:nodejs ./

USER nextjs

EXPOSE 8005

CMD ["sh", "-c", "npm run db:migrate && npm run start:prod"]