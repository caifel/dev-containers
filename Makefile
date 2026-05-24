COMPOSE=docker compose
COMPOSE_PROD=$(COMPOSE) -f docker-compose.prod.yml

.PHONY: build up down logs up-ws down-ws shell logs-ws api-types api-types-check shell-api sqlite-api logs-api status clean prod prod-web prod-api help h

# @group Build

build: ## [dev] Build all development Docker images.
	$(COMPOSE) build

# @group WS

up-ws: ## [dev] Create and start the independent ws container.
	$(COMPOSE) up -d ws

down-ws: ## [dev] Stop and remove the independent ws container while keeping named volumes.
	$(COMPOSE) rm -sf ws

shell: ## [dev] Open a zsh shell in the ws container.
	$(COMPOSE) exec ws zsh

logs-ws: ## [dev] Follow ws container logs.
	$(COMPOSE) logs -f ws

# @group Dev App

up: ## [dev] Start dev-api + dev-web, then refresh Swagger-generated web types.
	@scripts/sync-api-types.sh

down: ## [dev] Stop and remove dev-web + dev-api while keeping named volumes.
	$(COMPOSE) rm -sf dev-web dev-api

logs: ## [dev] Follow dev-web + dev-api logs.
	$(COMPOSE) logs -f dev-api dev-web

# @group API

api-types: ## [dev] Regenerate web API types from the running dev-api Swagger schema.
	@scripts/sync-api-types.sh

api-types-check: ## [dev] Check that generated web API types match the running dev-api Swagger schema.
	@scripts/sync-api-types.sh --check

shell-api: ## [dev] Open a shell in the dev-api container.
	$(COMPOSE) exec dev-api sh

sqlite-api: ## [dev] Open the dev-api SQLite database.
	$(COMPOSE) exec dev-api sqlite3 /alp/api/data/app.db

logs-api: ## [dev] Follow dev-api container logs.
	$(COMPOSE) logs -f dev-api

# @group Utilities

status: ## [dev] Show development Compose service status.
	$(COMPOSE) ps

clean: ## [dev] Stop all dev containers and delete development named volumes.
	$(COMPOSE) down -v

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
