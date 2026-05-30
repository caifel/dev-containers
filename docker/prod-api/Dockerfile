FROM oven/bun:1-debian AS deps
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      redis-server \
      sqlite3 \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

FROM deps AS runner

ENV NODE_ENV=production
ENV PORT=8081
ENV SQLITE_PATH=/app/data/app.db

COPY . .

RUN mkdir -p /app/data

EXPOSE 8081

CMD redis-server --daemonize yes --save "" --appendonly no --pidfile /tmp/redis.pid && until redis-cli ping 2>/dev/null; do sleep 0.1; done && bun run db:migrate && bun run start
