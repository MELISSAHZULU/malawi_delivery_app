from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User

# Customize admin site header
admin.site.site_header = "MalaWiDash Admin"
admin.site.site_title = "MalaWiDash Admin Portal"
admin.site.index_title = "Welcome to MalaWiDash Admin"
