#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.ssh" "$HOME/.config" "$HOME/.cache" "$HOME/.local/share/pnpm/store" /workspace/projects
chmod 700 "$HOME/.ssh"

DOTFILES_DIR="/workspace/projects/.dotfiles"

link_dotfile() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "$source_path" ]; then
    return
  fi

  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    return
  fi

  ln -sfn "$source_path" "$target_path"
}

if [ -d "$DOTFILES_DIR" ]; then
  link_dotfile "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_dotfile "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
  link_dotfile "$DOTFILES_DIR/.config/tmux" "$HOME/.config/tmux"
  link_dotfile "$DOTFILES_DIR/.config/lazygit" "$HOME/.config/lazygit"
fi

if [ ! -f "$HOME/.gitconfig" ]; then
  cat > "$HOME/.gitconfig" <<'EOF'
[init]
	defaultBranch = main
[pull]
	rebase = false
[core]
	editor = nvim
EOF
fi

exec "$@"
