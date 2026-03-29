"""
Local development settings.
"""

from .base import *  # noqa: F403, F401

DEBUG = True

ALLOWED_HOSTS = ["localhost", "127.0.0.1"]

SECRET_KEY = "django-insecure-local-dev-key-change-in-production"
