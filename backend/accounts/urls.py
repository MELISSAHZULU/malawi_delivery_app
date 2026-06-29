from django.urls import path
from .views import (
    RegisterView, LoginView, ProfileView, UpdateStoreView, UpdateDriverProfileView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('update-store/', UpdateStoreView.as_view(), name='update-store'),
    path('update-driver-profile/', UpdateDriverProfileView.as_view(), name='update-driver-profile'),
]
