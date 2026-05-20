COMPOSE=docker compose

.PHONY: build up down shell logs dev-fe dev-fe-reset prod clean

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d workstation

down:
	$(COMPOSE) down

shell:
	$(COMPOSE) exec workstation zsh

logs:
	$(COMPOSE) logs -f workstation

dev-fe:
	$(COMPOSE) up dev-web

dev-fe-reset:
	$(COMPOSE) stop dev-web
	$(COMPOSE) run --rm --user root --no-deps dev-web sh -lc 'rm -f /app/pnpm-lock.yaml && rm -rf /app/.pnpm-store && mkdir -p /app/node_modules /home/mario/.local/share/pnpm/store && find /app/node_modules -mindepth 1 -maxdepth 1 -exec rm -rf {} + && chown -R mario:mario /app/node_modules /home/mario/.local/share/pnpm'
	$(COMPOSE) run --rm --no-deps dev-web pnpm install
	$(COMPOSE) up dev-web

prod:
	$(COMPOSE) up --build prod-web

clean:
	$(COMPOSE) down -v
