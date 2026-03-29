"""
Test settings.
"""

from .base import *  # noqa: F403, F401

DEBUG = False

SECRET_KEY = "django-insecure-test-key"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]
