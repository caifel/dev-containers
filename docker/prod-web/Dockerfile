FROM oven/bun:1-debian AS deps
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

FROM deps AS build
COPY . .
RUN mkdir -p public
RUN bun --bun run build

FROM oven/bun:1-debian AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=8080
ENV NEXT_TELEMETRY_DISABLED=1

RUN groupadd --system --gid 1001 bunjs \
    && useradd --system --uid 1001 --gid bunjs nextjs

COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:bunjs /app/.next/standalone ./
COPY --from=build --chown=nextjs:bunjs /app/.next/static ./.next/static

USER nextjs
EXPOSE 8080

CMD ["bun", "server.js"]
