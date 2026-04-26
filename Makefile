.PHONY: buildup
buildup:
	@docker compose -f docker-compose.$(app).yaml -p $(app) up -d --build

.PHONY: up
up:
	@docker compose -f docker-compose.$(app).yaml -p $(app) up -d

.PHONY: down
down:
	@docker compose -f docker-compose.$(app).yaml -p $(app) down

.PHONY: kill
kill:
	@docker compose -f docker-compose.$(app).yaml -p $(app) down --volumes

.PHONY: garage
garage:
	@docker exec -it garage /garage $(command)
