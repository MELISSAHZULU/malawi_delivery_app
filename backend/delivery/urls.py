from django.urls import path
from .views import (
    DriverLocationView,
    AvailableDriversView,
    AcceptDeliveryView,
    DriverOrdersView,
    UpdateDeliveryStatusView,
)

urlpatterns = [
    path('location/', DriverLocationView.as_view(), name='driver_location'),
    path('available/', AvailableDriversView.as_view(), name='available_drivers'),
    path('accept/<int:order_id>/', AcceptDeliveryView.as_view(), name='accept_delivery'),
    path('orders/', DriverOrdersView.as_view(), name='driver_orders'),
    path('orders/<int:order_id>/status/', UpdateDeliveryStatusView.as_view(), name='update_delivery_status'),
]
