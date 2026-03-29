# Barebone Django Boilerplate

A minimal Django project template with Docker, PostgreSQL, pytest, and django-allauth.

## Stack

- Django 6.0.3
- PostgreSQL
- pytest + pytest-django
- django-allauth

## Project Structure

```
├── docker-compose.yml
├── Dockerfile.web.local
├── .env
├── backend/
│   ├── manage.py
│   ├── pyproject.toml
│   ├── config/
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── local.py
│   │   │   └── test.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── requirements/
│   │   ├── base.txt
│   │   └── local.txt
│   └── backend/
```

## Quick Start

```bash
make setup
```

This will create `.env` from `.env.example`, build and start the Docker containers, and run migrations. The app will be available at `http://localhost:8001`.

Run `make help` to see all available commands.

## Settings

| File | Purpose |
|------|---------|
| `base.py` | Shared settings (installed apps, middleware, DB config) |
| `local.py` | Local development (`DEBUG=True`) |
| `test.py` | Test runner (in-memory SQLite, fast password hasher) |

`manage.py` defaults to `config.settings.local`. Tests use `config.settings.test` via `pyproject.toml`.

## Running Tests

```bash
make test
```

## Environment Variables

Configured in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPOSE_PROJECT_NAME` | `barebone` | Docker container name prefix |
| `DB_PORT` | `5432` | Host port for PostgreSQL |
| `WEB_PORT` | `8001` | Host port for Django |

## Coding Style

This project follows the [HackSoft Django Styleguide](https://github.com/HackSoftware/Django-Styleguide).
