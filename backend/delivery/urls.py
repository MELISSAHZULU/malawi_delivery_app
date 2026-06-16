from django.urls import path
from .views import (
    DriverLocationView,
    DriverOrdersView,
    AcceptDeliveryView,
    UpdateDeliveryStatusView
)

urlpatterns = [
    path('location/', DriverLocationView.as_view(), name='driver_location'),
    path('orders/', DriverOrdersView.as_view(), name='driver_orders'),
    path('accept/<int:order_id>/', AcceptDeliveryView.as_view(), name='accept_delivery'),
    path('status/<int:order_id>/', UpdateDeliveryStatusView.as_view(), name='update_delivery'),
]