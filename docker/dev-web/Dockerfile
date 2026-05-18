FROM node:22-bookworm-slim

ENV PNPM_HOME=/home/node/.local/share/pnpm \
    PATH=/home/node/.local/share/pnpm:$PATH \
    NEXT_TELEMETRY_DISABLED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      openssl \
    && corepack enable \
    && corepack prepare pnpm@latest --activate \
    && mkdir -p /home/node/.local/share/pnpm/store /app \
    && chown -R node:node /home/node /app \
    && rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

CMD ["pnpm", "dev", "--hostname", "0.0.0.0"]
