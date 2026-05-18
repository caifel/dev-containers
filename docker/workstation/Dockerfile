FROM node:22-bookworm-slim

ARG USERNAME=mario
ARG LAZYGIT_VERSION=0.44.1
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/zsh \
    EDITOR=nvim \
    VISUAL=nvim \
    PNPM_HOME=/home/${USERNAME}/.local/share/pnpm \
    PATH=/home/${USERNAME}/.local/share/pnpm:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      wget \
      git \
      gnupg \
      build-essential \
      pkg-config \
      unzip \
      zip \
      xz-utils \
      ripgrep \
      fd-find \
      fzf \
      jq \
      yq \
      tree \
      htop \
      tmux \
      zsh \
      sudo \
      openssh-client \
      rsync \
      less \
      man-db \
      bat \
      shellcheck \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      amd64) NVIM_ARCH="x86_64"; LAZYGIT_ARCH="x86_64" ;; \
      arm64) NVIM_ARCH="arm64"; LAZYGIT_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
      | tar -xz -C /opt \
    && ln -s "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim \
    && curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin lazygit \
    && corepack enable \
    && corepack prepare pnpm@latest --activate \
    && corepack prepare yarn@stable --activate \
    && npm install -g typescript tsx create-next-app @nestjs/cli

RUN groupmod --new-name ${USERNAME} node \
    && usermod --login ${USERNAME} --move-home --home /home/${USERNAME} node \
    && chsh --shell /bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /workspace/projects /home/${USERNAME}/.config /home/${USERNAME}/.local/share/pnpm \
    && chown -R ${USERNAME}:${USERNAME} /workspace /home/${USERNAME}

COPY docker/workstation/entrypoint.sh /usr/local/bin/workstation-entrypoint

RUN chmod +x /usr/local/bin/workstation-entrypoint \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

USER ${USERNAME}
WORKDIR /workspace/projects

RUN mkdir -p ~/.config ~/.local/share/pnpm/store ~/.npm ~/.cache

ENTRYPOINT ["workstation-entrypoint"]
CMD ["zsh"]
