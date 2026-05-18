COMPOSE=docker compose

.PHONY: build up down shell logs dev prod clean

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

dev:
	$(COMPOSE) up dev-web

prod:
	$(COMPOSE) up --build prod-web

clean:
	$(COMPOSE) down -v
