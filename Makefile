COMPOSE=docker compose
COMPOSE_PROD=$(COMPOSE) -f docker-compose.prod.yml

.PHONY: build up down logs up-ws down-ws shell logs-ws api-types api-types-check db-migrate db-seed db-reset shell-api sqlite-api logs-api status clean prod prod-web prod-api smoke-test hooks-install help h

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

up: ## [dev] Start dev-api + dev-web, migrate DB, then refresh API types.
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

db-migrate: ## [dev] Apply API database migrations in the dev SQLite volume.
	$(COMPOSE) run --rm dev-api sh -lc "bun install && bun run db:migrate"

db-seed: ## [dev] Seed the dev API database; this replaces fixture-owned data.
	$(COMPOSE) run --rm dev-api sh -lc "bun install && bun run db:seed"

db-reset: ## [dev] Delete the dev API SQLite files, then migrate and seed them.
	$(COMPOSE) rm -sf dev-api
	$(COMPOSE) run --rm dev-api sh -lc "rm -f /alp/api/data/app.db /alp/api/data/app.db-* && bun install && bun run db:migrate && bun run db:seed"

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

smoke-test: ## Run a quick health check against the running API (dev or prod).
	@scripts/smoke-test.sh

hooks-install: ## Install the API types pre-commit hook into .git/hooks.
	@mkdir -p .git/hooks
	@cp .githooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed (api-types-check)."

# @group Helpers

help: ## Display development targets with descriptions and commands.
	@scripts/make-help.sh

h: help
