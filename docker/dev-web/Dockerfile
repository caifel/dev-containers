FROM node:22-bookworm-slim

ARG USERNAME=mario
ARG PNPM_VERSION=11.1.3

ENV PNPM_HOME=/home/${USERNAME}/.local/share/pnpm \
    PATH=/home/${USERNAME}/.local/share/pnpm:$PATH \
    NEXT_TELEMETRY_DISABLED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      openssl \
    && npm install -g pnpm@${PNPM_VERSION} \
    && usermod --login ${USERNAME} --move-home --home /home/${USERNAME} node \
    && groupmod --new-name ${USERNAME} node \
    && mkdir -p /home/${USERNAME}/.local/share/pnpm/store /app/node_modules \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /app \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
WORKDIR /app

CMD ["pnpm", "dev", "--hostname", "0.0.0.0"]
