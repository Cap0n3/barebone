PROJECT_NAME = ./backend

.PHONY: setup secret run app create-superuser shell docker-bash logs mkmigs mkmigs-dry migrate migrate-all showmigrations db-backup db-restore db-table db-columns flush sqlflush psql collect test ruff djlint djlint-all help

# PROJECT SETUP
# ------------------------------------------------------------------------------
setup:
	@echo "Setting up the project..."
	@cp -n .env.example .env 2>/dev/null && echo "Created .env from .env.example" || echo ".env already exists, skipping"
	@echo "Starting Docker containers..."
	@docker compose up -d --build
	@echo "Waiting for containers to be ready..."
	@sleep 10
	@echo ""
	@echo "Setup complete!"
	@echo "  - App running at: http://localhost:$${WEB_PORT:-8001}"
	@echo ""
	@echo "Next steps:"
	@echo "  make create-superuser    Create an admin account"
	@echo "  make help                See all available commands"
	@echo ""

# DJANGO COMMANDS
# ------------------------------------------------------------------------------
secret:
	@echo "Generating Django secret key..."
	@python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

run:
	@echo "Running django server..."
	@cd $(PROJECT_NAME) && python manage.py runserver 0.0.0.0:8000
	@echo "Done."

app:
	@echo "Creating app..."
	@if [ -z "$(app)" ]; then \
		echo "Usage: make app app=<app_name>"; \
		exit 1; \
	fi
	@docker compose exec web mkdir -p /app/backend/backend/$(app)
	@docker compose exec web python backend/manage.py startapp $(app) backend/backend/$(app)
	@echo "Done."

create-superuser:
	@echo "Creating superuser..."
	@docker compose exec web python backend/manage.py createsuperuser
	@echo "Done."

shell:
	@echo "Running shell..."
	@docker compose exec web python backend/manage.py shell
	@echo "Done."

docker-bash:
	@echo "Connecting to web container..."
	@docker compose exec web bash

logs:
	@docker logs -f --tail 50 barebone_web

mkmigs:
	@echo "Making migrations..."
	@docker compose exec web python backend/manage.py makemigrations $(app)
	@echo "Done."

mkmigs-dry:
	@echo "Making migrations (dry run)..."
	@docker compose exec web python backend/manage.py makemigrations --dry-run
	@echo "Done."

migrate:
	@echo "Migrating..."
	@docker compose exec web python backend/manage.py migrate
	@echo "Done."

migrate-all:
	@echo "Making migrations locally, then migrating in container..."
	@cd $(PROJECT_NAME) && python manage.py makemigrations
	@docker compose exec web python backend/manage.py migrate
	@echo "Done."

showmigrations:
	@echo "Showing migrations..."
	@docker compose exec web python backend/manage.py showmigrations $(app)
	@echo "Done."

# DATABASE COMMANDS
# ------------------------------------------------------------------------------
db-backup:
	@echo "Creating a backup of database..."
	@docker compose exec web bash -c "cd /app/backend/utility/db_operations && DOCKER_BACKUP_DIR=/app/db_backups ./db_backup.sh"
	@echo "Done."

db-restore:
	@echo "Restoring database..."
	@docker compose exec web bash -c "cd /app/backend/utility/db_operations && DOCKER_BACKUP_DIR=/app/db_backups ./db_restore.sh"
	@echo "Done."

db-table:
	@echo "Searching table..."
	@docker compose exec web bash -c \
	"echo \"SELECT $(columns) FROM $(table) $(WHERE);\" | python backend/manage.py dbshell"

db-columns:
	@echo "Listing columns for table: $(table)"
	@docker compose exec web bash -c \
	"echo \"\
SELECT column_name \
FROM information_schema.columns \
WHERE table_name = '$(table)' \
ORDER BY ordinal_position;\" \
| python backend/manage.py dbshell"

sqlflush:
	@echo "Showing SQL to flush the database..."
	@docker compose exec web python backend/manage.py sqlflush
	@echo "Done."

flush:
	@echo "Flushing the database (deleting all data)..."
	@docker compose exec web python backend/manage.py flush
	@echo "Done."

psql:
	@echo "Connecting to PostgreSQL database..."
	@docker compose exec db psql -U django -d django_db
	@echo "Connection closed."

# STATIC FILES
# ------------------------------------------------------------------------------
collect:
	@echo "Collecting static files..."
	@docker compose exec web python backend/manage.py collectstatic
	@echo "Done."

# TEST COMMANDS
# ------------------------------------------------------------------------------
test:
	@echo "Running tests..."
	@docker compose exec web pytest backend/
	@echo "Done."

# CODE QUALITY
# ------------------------------------------------------------------------------
ruff:
	@echo "Running ruff check..."
ifdef path
	@docker compose exec web ruff check ./$(PROJECT_NAME)/$(path)
else
	@docker compose exec web ruff check ./$(PROJECT_NAME)/
endif
	@echo "Done."

ruff-fix:
	@echo "Running ruff fix..."
ifdef path
	@docker compose exec web ruff check --fix ./$(PROJECT_NAME)/$(path)
else
	@docker compose exec web ruff check --fix ./$(PROJECT_NAME)/
endif
	@echo "Done."

ruff-format:
	@echo "Running ruff format..."
ifdef path
	@docker compose exec web ruff format ./$(PROJECT_NAME)/$(path)
else
	@docker compose exec web ruff format ./$(PROJECT_NAME)/
endif
	@echo "Done."

djlint:
	@echo "Running djlint check on specific template..."
ifndef path
	@echo "Error: Please specify a path relative to templates/ directory."
	@echo "Usage: make djlint path=<relative_path_from_templates>"
	@exit 1
endif
	@djlint --check $(PROJECT_NAME)/templates/$(path)
	@echo "Done."

djlint-all:
	@echo "Running djlint check on all HTML templates..."
	@djlint --check $(PROJECT_NAME)/templates/
	@echo "Done."

# HELP
# ------------------------------------------------------------------------------
help:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════════════════╗"
	@echo "║                      Barebone Django Boilerplate - Makefile                  ║"
	@echo "╚══════════════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  PROJECT SETUP                                                               │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  setup               First-time project setup (env, Docker, migrations)"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  DJANGO COMMANDS                                                             │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  secret              Generate a Django secret key"
	@echo "  run                 Run the Django server (local)"
	@echo "  app                 Create a new Django app"
	@echo "                      Usage: make app app=<app_name>"
	@echo "  create-superuser    Create a superuser"
	@echo "  shell               Open Django shell"
	@echo "  docker-bash         Connect to web container with bash"
	@echo "  logs                Stream web container logs (Ctrl+C to stop)"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  MIGRATIONS                                                                  │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  mkmigs              Make migrations"
	@echo "                      Usage: make mkmigs [app=<app_name>]"
	@echo "  mkmigs-dry          Make migrations dry run"
	@echo "  migrate             Apply migrations"
	@echo "  migrate-all         Make migrations locally + migrate in Docker"
	@echo "  showmigrations      Show migration status"
	@echo "                      Usage: make showmigrations [app=<app_name>]"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  DATABASE                                                                    │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  psql                Connect to PostgreSQL database"
	@echo "  db-backup           Create backup of database"
	@echo "  db-restore          Restore database backup"
	@echo "  db-table            Show table content via Django dbshell"
	@echo '                      Usage: make db-table table=<table> columns="id, name"'
	@echo "  db-columns          List table columns (schema inspection)"
	@echo "                      Usage: make db-columns table=<table_name>"
	@echo "  flush               Flush database - delete all data"
	@echo "  sqlflush            Display SQL for flushing database"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  STATIC FILES                                                                │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  collect             Collect static files"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  TESTING                                                                     │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  test                Run test suite with pytest"
	@echo ""
	@echo "┌──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  CODE QUALITY                                                                │"
	@echo "└──────────────────────────────────────────────────────────────────────────────┘"
	@echo "  ruff                Run Ruff linter"
	@echo "                      Usage: make ruff [path=<relative_path>]"
	@echo "  ruff-fix            Run Ruff linter with auto-fix"
	@echo "                      Usage: make ruff-fix [path=<relative_path>]"
	@echo "  ruff-format         Run Ruff formatter"
	@echo "                      Usage: make ruff-format [path=<relative_path>]"
	@echo "  djlint              Run djlint on specific template"
	@echo "                      Usage: make djlint path=<path_from_templates>"
	@echo "  djlint-all          Run djlint on all HTML templates"
	@echo ""
	@echo "──────────────────────────────────────────────────────────────────────────────────"
	@echo "  All commands run inside Docker unless noted otherwise."
	@echo "──────────────────────────────────────────────────────────────────────────────────"
	@echo ""
