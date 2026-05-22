COMPOSE=docker compose
COMPOSE_PROD=$(COMPOSE) -f docker-compose.prod.yml

.PHONY: up-ws start-ws stop-ws restart-ws logs-ws shell build up start stop restart logs status down dev-web dev-api dev-api-shell dev-api-sqlite dev-web-reset clean prod prod-web prod-api help h

# @group WS

up-ws: ## [dev] Create and start only the ws container in the background.
	$(COMPOSE) up -d ws

start-ws: ## [dev] Start only the ws container.
	$(COMPOSE) start ws

stop-ws: ## [dev] Stop only the ws container.
	$(COMPOSE) stop ws

restart-ws: ## [dev] Restart only the ws container.
	$(COMPOSE) restart ws

shell: ## [dev] Open a zsh shell in the ws container.
	$(COMPOSE) exec ws zsh

# @group Development Stack

build: ## [dev] Build all development Docker images.
	$(COMPOSE) build

up: ## [dev] Create and start the full development stack in the background.
	$(COMPOSE) up -d ws dev-web dev-api

start: ## [dev] Start all existing development containers.
	$(COMPOSE) start

stop: ## [dev] Stop all development containers without removing them.
	$(COMPOSE) stop

restart: ## [dev] Restart all development containers.
	$(COMPOSE) restart

# @group Services

dev-web: ## [dev] Run the Next.js development web app.
	$(COMPOSE) up dev-web

dev-api: ## [dev] Run the Elysia/Bun dev API.
	$(COMPOSE) up dev-api

dev-api-shell: ## [dev] Open a shell in the dev-api container.
	$(COMPOSE) exec dev-api sh

dev-api-sqlite: ## [dev] Open the dev-api SQLite database.
	$(COMPOSE) exec dev-api sqlite3 /alp/api/data/app.db

# @group Utilities

dev-web-reset: ## [dev] Reset dev-web dependencies and restart dev-web.
	$(COMPOSE) stop dev-web
	$(COMPOSE) run --rm --user root --no-deps dev-web sh -lc 'mkdir -p /alp/web/node_modules /home/mario/.bun/install/cache && find /alp/web/node_modules -mindepth 1 -maxdepth 1 -exec rm -rf {} + && chown -R mario:mario /alp/web/node_modules /home/mario/.bun'
	$(COMPOSE) run --rm --no-deps dev-web bun install
	$(COMPOSE) up dev-web

clean: ## [dev] Stop development containers and delete development named volumes.
	$(COMPOSE) down -v

logs-ws: ## [dev] Follow only ws container logs.
	$(COMPOSE) logs -f ws

logs: ## [dev] Follow logs for all development containers.
	$(COMPOSE) logs -f

status: ## [dev] Show development Compose service status.
	$(COMPOSE) ps

down: ## [dev] Stop and remove development containers while keeping named volumes.
	$(COMPOSE) down

# @group Production-Like Local Testing

prod: ## [prod] Build and run production web and API containers.
	$(COMPOSE_PROD) up --build prod-web prod-api

prod-web: ## [prod] Build and run the production web container.
	$(COMPOSE_PROD) up --build prod-web

prod-api: ## [prod] Build and run the production API container.
	$(COMPOSE_PROD) up --build prod-api

# @group Helpers

help: ## Display development targets with descriptions and commands.
	@scripts/make-help.sh

h: help
