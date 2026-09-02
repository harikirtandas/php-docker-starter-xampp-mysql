.PHONY: install up down restart shell db-shell logs db-import fresh semana ip

install:
	@mkdir -p src/app src/public docker/mysql/init
	@if [ -f src/composer.json ] && [ ! -d src/vendor ]; then \
		echo "==> composer.json sin vendor/: instalando dependencias..."; \
		docker run --rm --user "$$(id -u):$$(id -g)" -v "$(PWD)/src":/app -w /app composer:latest install; \
	elif [ -d src/vendor ]; then \
		echo "==> vendor/ ya instalado, solo levantando."; \
	else \
		echo "==> no hay composer.json, nada que instalar."; \
	fi
	HOST_UID=$$(id -u) HOST_GID=$$(id -g) docker compose up -d --build
	@echo "App     -> http://localhost:$${APP_PORT:-8080}"
	@echo "Adminer -> http://localhost:$${ADMINER_PORT:-8081}"

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

shell:
	docker compose exec app bash

db-shell:
	docker compose exec mysql sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'

logs:
	docker compose logs -f

db-import:
	@test -n "$(FILE)" || (echo "uso: make db-import FILE=dump.sql" && exit 1)
	@test -f "$(FILE)" || (echo "no existe el archivo: $(FILE)" && exit 1)
	docker compose exec -T mysql sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' < "$(FILE)"

fresh:
	@read -p "Esto borra TODOS los datos de mysql-data. Escribi 'yes' para continuar: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose down -v; \
		HOST_UID=$$(id -u) HOST_GID=$$(id -g) docker compose up -d --build; \
	else \
		echo "Cancelado."; \
	fi

semana:
	@test -n "$(N)" || (echo "uso: make semana N=6" && exit 1)
	@mkdir -p src/public/semana$(N)
	@printf '<?php\n\ndeclare(strict_types=1);\n\n// pagina minima para confirmar que PHP corre en esta semana.\n?>\n<!doctype html>\n<html lang="es">\n<head>\n    <meta charset="utf-8">\n    <title>Semana $(N)</title>\n</head>\n<body>\n    <h1>Semana $(N)</h1>\n    <p>PHP <?= htmlspecialchars(phpversion()) ?></p>\n    <p><?= htmlspecialchars(date("Y-m-d H:i:s")) ?></p>\n</body>\n</html>\n' > src/public/semana$(N)/index.php
	@echo "==> creado src/public/semana$(N)/index.php"

ip:
	@ip=$$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null); \
	if [ -z "$$ip" ]; then \
		echo "no se encontro IP LAN en en0 ni en1 (revisa que estes conectado a Wi-Fi)"; \
		exit 1; \
	fi; \
	echo "IP LAN -> $$ip"; \
	echo "URL    -> http://$$ip:$${APP_PORT:-8080}"
