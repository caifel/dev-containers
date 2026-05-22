# Docker Web Development Environment

This folder defines the Docker containers for your web development workflow.

Your project source lives outside this folder:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/web
```

This Docker setup lives here:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/ops
```

## Containers

The development Compose stack has three main containers:

- `ws`: your interactive development machine with terminal tools.
- `dev-web`: runs the `ajedrezlapaz` Next.js app in development mode.
- `dev-api`: runs the Elysia API with Bun and SQLite.

Production-like local testing lives in `docker-compose.prod.yml`:

- `prod-web`: builds and runs the `ajedrezlapaz` Next.js app in production mode.
- `prod-api`: builds and runs the Elysia API in production mode.

All custom images use Debian Bookworm slim bases through `oven/bun:1-debian`.

## How The Containers Connect

`ws` mounts your host projects directory:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/web -> /alp/web
/Users/mariomedrano/Projects/ajedrezlapaz/api -> /alp/api
```

So inside `ws`, your app path is:

```txt
/alp/web
```

`dev-web` mounts only that app:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/web -> /alp/web
```

`dev-api` mounts your API project:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/api -> /alp/api
```

`prod-web` and `prod-api` use the app folders as Docker build contexts from the standalone `docker-compose.prod.yml` file.

The result:

- edit code in `ws`
- run the Next.js dev server in `dev-web`
- run the Elysia API in `dev-api`
- build/run production-like images with `prod-web` and `prod-api`

## WS

`ws` includes:

- `zsh`
- `tmux`
- Neovim
- `git`
- `lazygit`
- Bun
- TypeScript, TSX, Create Next App
- `tree-sitter-cli` for Neovim parser builds
- SQLite CLI and development headers
- `ripgrep`, `fd`, `fzf`, `jq`, `yq`, `bat`, `tree`, `htop`

The image does not bake in shell, tmux, Neovim, or lazygit config files. Your dotfiles repo should own those.

This setup uses your Linux workstation dotfiles fork from:

```txt
/Users/mariomedrano/Dev/.dotfiles -> /alp/dotfiles
```

Inspect before symlinking:

```sh
find /alp/dotfiles -maxdepth 3 -type f | sort
```

Link the active ws configs into the home directory:

```sh
mkdir -p ~/.config
ln -s /alp/dotfiles/.zshrc ~/.zshrc
ln -s /alp/dotfiles/.config/nvim ~/.config/nvim
ln -s /alp/dotfiles/.config/tmux ~/.config/tmux
ln -s /alp/dotfiles/.config/lazygit ~/.config/lazygit
```

The dotfiles originally came from Lazar Nikolov's macOS-oriented dotfiles, but this branch keeps only the Linux container pieces used by `ws`.

Then clone your project:

```sh
cd /alp
git clone git@github.com:YOUR_USER/ajedrezlapaz.git web
```

That writes to:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/web
```

For the API, clone or create:

```sh
cd /alp
git clone git@github.com:YOUR_USER/ajedrezlapaz-api.git api
```

That writes to:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/api
```

## Quick Start

Copy the example environment file if you want to customize paths or ports:

```sh
cp .env.example .env
```

Start only the ws:

```sh
docker compose up -d --build ws
docker compose exec ws zsh
```

Or, with Make:

```sh
make build
make up-ws
make shell
```

Start the full development stack:

```sh
make build
make up
```

Display the development command reference:

```sh
make help
```

## GitHub SSH From WS

This setup treats `ws` as your real development machine, so GitHub SSH should live inside the container. That keeps `git`, `lazygit`, private clones, pulls, and pushes working from the same place where you use `tmux` and Neovim.

The SSH key is stored in the persistent `ws-home` Docker volume at `/home/mario/.ssh`, so it survives image rebuilds. If you delete Docker volumes with `make clean`, you will need to recreate the key.

Inside the ws container:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "mario@web-dev" -f ~/.ssh/id_ed25519_github
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

## Backend API

`dev-api` expects an Elysia/Bun API at:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/api
```

Inside the container, SQLite lives at:

```txt
/alp/api/data/app.db
```

The app receives:

```txt
DATABASE_URL=file:/alp/api/data/app.db
SQLITE_PATH=/alp/api/data/app.db
```

Run the API:

```sh
docker compose up --build dev-api
```

Or:

```sh
make dev-api
```

Open:

```txt
http://localhost:4000
```

Open a shell in the API container:

```sh
make dev-api-shell
```

Open the SQLite database:

```sh
make dev-api-sqlite
```

For Elysia + Drizzle with SQLite, install app dependencies inside the API project:

```sh
bun add elysia drizzle-orm
bun add -D drizzle-kit
```

Use generated migrations for durable schema changes:

```sh
bunx drizzle-kit generate
bunx drizzle-kit migrate
```

## Production

`prod-web` expects your Next.js app at:

```txt
/Users/mariomedrano/Projects/ajedrezlapaz/web
```

It uses Bun, runs the app build, and starts the Next.js standalone server with Bun on port `8080`.

For best production output, your app should set this in `next.config.mjs` or `next.config.js`:

```js
const nextConfig = {
  output: "standalone",
};

export default nextConfig;
```

Run production:

```sh
docker compose -f docker-compose.prod.yml up --build prod-web prod-api
```

Or:

```sh
make prod
```

Open:

```txt
http://localhost:8080
http://localhost:8081
```

Run only the web production container:

```sh
make prod-web
```

Run only the API production container:

```sh
make prod-api
```

## Notes

Development SQLite data is stored in the `dev-api-sqlite-data` Docker volume. Production API SQLite data is stored in the `prod-api-sqlite-data` Docker volume. If you run `docker compose down -v`, both local API databases are deleted.

If Docker Desktop cannot mount `/Users/mariomedrano/Projects/ajedrezlapaz`, add that path to Docker Desktop file sharing settings, or change `WEB_PATH`, `API_PATH`, or `DOTFILES_PATH` in `.env`.

The `ws-home` volume is mounted at `/home/mario` and keeps your dotfiles clone, shell history, LazyVim plugins, and tool state between rebuilds.

To reset all Docker volumes:

```sh
docker compose down -v
```
