# Docker Web Development Environment

This folder defines the Docker containers for your web development workflow.

Your project source lives outside this folder:

```txt
/mariomedrano/projects/ajedrezlapaz
```

This Docker setup lives here:

```txt
/Users/mariomedrano/Personal/dev-containers
```

## Containers

The Compose stack has three main containers:

- `workstation`: your interactive development machine with terminal tools.
- `dev-web`: runs the `ajedrezlapaz` Next.js app in development mode.
- `prod-web`: builds and runs the `ajedrezlapaz` Next.js app in production mode.

All three custom images use Debian Bookworm slim bases. The workstation and app containers use `node:22-bookworm-slim`.

## How The Containers Connect

`workstation` mounts your host projects directory:

```txt
/mariomedrano/projects -> /workspace/projects
```

So inside `workstation`, your app path is:

```txt
/workspace/projects/ajedrezlapaz
```

`dev-web` mounts only that app:

```txt
/mariomedrano/projects/ajedrezlapaz -> /app
```

`prod-web` uses the same app folder as its Docker build context.

The result:

- edit code in `workstation`
- run the Next.js dev server in `dev-web`
- build/run the production image with `prod-web`

## Workstation

`workstation` includes:

- `zsh`
- `tmux`
- Neovim
- `git`
- `lazygit`
- Node.js 22
- `pnpm`, `npm`, `yarn`
- TypeScript, TSX, Create Next App, Nest CLI
- `tree-sitter-cli` for Neovim parser builds
- `ripgrep`, `fd`, `fzf`, `jq`, `yq`, `bat`, `tree`, `htop`

The image does not bake in shell, tmux, Neovim, or lazygit config files. Your dotfiles repo should own those.

This setup uses your Linux workstation dotfiles fork under the shared projects directory:

```sh
cd /workspace/projects
git clone git@github.com:caifel/dotfiles.git .dotfiles
cd .dotfiles
git checkout linux-workstation
```

Inspect before symlinking:

```sh
find . -maxdepth 3 -type f | sort
```

Link the active workstation configs into the home directory:

```sh
mkdir -p ~/.config
ln -s /workspace/projects/.dotfiles/.zshrc ~/.zshrc
ln -s /workspace/projects/.dotfiles/.config/nvim ~/.config/nvim
ln -s /workspace/projects/.dotfiles/.config/tmux ~/.config/tmux
ln -s /workspace/projects/.dotfiles/.config/lazygit ~/.config/lazygit
```

The dotfiles originally came from Lazar Nikolov's macOS-oriented dotfiles, but this branch keeps only the Linux container pieces used by this workstation.

Then clone your project:

```sh
cd /workspace/projects
git clone git@github.com:YOUR_USER/ajedrezlapaz.git
```

That writes to:

```txt
/mariomedrano/projects/ajedrezlapaz
```

## Quick Start

Copy the example environment file if you want to customize paths or ports:

```sh
cp .env.example .env
```

Start the workstation:

```sh
docker compose up -d --build workstation
docker compose exec workstation zsh
```

Or:

```sh
make build
make up
make shell
```

## GitHub SSH From Workstation

This setup treats `workstation` as your real development machine, so GitHub SSH should live inside the container. That keeps `git`, `lazygit`, private clones, pulls, and pushes working from the same place where you use `tmux` and Neovim.

The SSH key is stored in the persistent `workstation-home` Docker volume at `/home/mario/.ssh`, so it survives image rebuilds. If you delete Docker volumes with `make clean`, you will need to recreate the key.

Inside the workstation container:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "mario@web-workstation" -f ~/.ssh/id_ed25519_github
cat > ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
  AddKeysToAgent no
EOF
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519_github
cat ~/.ssh/id_ed25519_github.pub
```

Add the printed public key to GitHub under SSH keys, then verify:

```sh
ssh -T git@github.com
```

Run the Next.js app in development mode:

```sh
docker compose up --build dev-web
```

Open:

```txt
http://localhost:3000
```

## Production Web

`prod-web` expects your Next.js app at:

```txt
/mariomedrano/projects/ajedrezlapaz
```

It uses `pnpm`, runs the app build, and starts the Next.js standalone server on port `8080`.

For best production output, your app should set this in `next.config.mjs` or `next.config.js`:

```js
const nextConfig = {
  output: "standalone",
};

export default nextConfig;
```

Run production:

```sh
docker compose up --build prod-web
```

Open:

```txt
http://localhost:8080
```

## Notes

Database containers and database client tools are intentionally not part of this setup. Add PostgreSQL, MySQL, Redis, or other database tooling on demand per project.

If Docker Desktop cannot mount `/mariomedrano/projects`, add that path to Docker Desktop file sharing settings, or change `PROJECTS_PATH` in `.env`.

The `workstation-home` volume is mounted at `/home/mario` and keeps your dotfiles clone, shell history, LazyVim plugins, and tool state between rebuilds.

To reset all Docker volumes:

```sh
docker compose down -v
```
