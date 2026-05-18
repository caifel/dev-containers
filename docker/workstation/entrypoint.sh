#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.ssh" "$HOME/.config" "$HOME/.cache" "$HOME/.local/share/pnpm/store" /workspace/projects
chmod 700 "$HOME/.ssh"

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
