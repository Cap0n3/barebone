from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path


def index(request):
    return HttpResponse(
        "<h1>It works!</h1><p>Your barebone Django project is up and running.</p>",
        content_type="text/html",
    )


urlpatterns = [
    path("", index),
    path("admin/", admin.site.urls),
    path("accounts/", include("allauth.urls")),
]
