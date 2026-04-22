# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS deps
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && pnpm fetch --frozen-lockfile

FROM node:22-alpine AS builder
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /root/.local/share/pnpm /root/.local/share/pnpm
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --offline

COPY . .
RUN pnpm build

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8005
ENV HOSTNAME=0.0.0.0

RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

COPY --from=builder /app/dist/app ./

RUN mkdir -p /data && \
    chown -R nextjs:nodejs /app /data && \
    if [ ! -e /data/resend-local.sqlite ]; then cp /app/resend-local.sqlite /data/resend-local.sqlite; fi && \
    rm -f /app/resend-local.sqlite && \
    ln -s /data/resend-local.sqlite /app/resend-local.sqlite

USER nextjs

EXPOSE 8005

CMD ["node", "server.js"]