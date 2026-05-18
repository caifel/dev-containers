FROM debian:bookworm-slim

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG NODE_VERSION=22
ARG LAZYGIT_VERSION=0.44.1

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
      eza \
      shellcheck \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
      | tar -xz -C /opt \
    && ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
    && curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
      | tar -xz -C /usr/local/bin lazygit \
    && npm install -g npm@latest pnpm yarn typescript tsx create-next-app @nestjs/cli

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} --shell /bin/zsh \
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
