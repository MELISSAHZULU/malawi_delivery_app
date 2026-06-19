from django.urls import path
from .views import (
    DriverLocationView,
    AvailableDriversView,
    AssignDriverView,
    AutoAssignDriverView,
    DriverOrdersView,
    UpdateDeliveryStatusView,
)

urlpatterns = [
    path('location/', DriverLocationView.as_view(), name='driver_location'),
    path('available/', AvailableDriversView.as_view(), name='available_drivers'),
    path('assign/', AssignDriverView.as_view(), name='assign_driver'),
    path('auto-assign/', AutoAssignDriverView.as_view(), name='auto_assign_driver'),
    path('orders/', DriverOrdersView.as_view(), name='driver_orders'),
    path('orders/<int:order_id>/status/', UpdateDeliveryStatusView.as_view(), name='update_delivery_status'),
]
