FROM oven/bun:1-debian

ARG USERNAME=mario
ARG LAZYGIT_VERSION=0.44.1
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/zsh \
    EDITOR=nvim \
    VISUAL=nvim \
    BUN_INSTALL=/home/${USERNAME}/.bun \
    PATH=/home/${USERNAME}/.bun/bin:$PATH

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
	      openssl \
      nodejs \
      npm \
	      sqlite3 \
	      libsqlite3-dev \
	      rsync \
	      less \
      man-db \
      bat \
      lsof \
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
    && BUN_INSTALL=/usr/local bun install -g typescript tsx create-next-app tree-sitter-cli@0.22.6 \
    && curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin

RUN groupmod --new-name ${USERNAME} bun \
    && usermod --login ${USERNAME} --move-home --home /home/${USERNAME} bun \
    && chsh --shell /bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /alp /home/${USERNAME}/.config /home/${USERNAME}/.bun/install/cache \
    && chown -R ${USERNAME}:${USERNAME} /alp /home/${USERNAME}

COPY docker/ws/entrypoint.sh /usr/local/bin/ws-entrypoint

RUN chmod +x /usr/local/bin/ws-entrypoint \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

USER ${USERNAME}
WORKDIR /alp

RUN mkdir -p ~/.config ~/.bun/install/cache ~/.cache

ENTRYPOINT ["ws-entrypoint"]
CMD ["zsh"]
