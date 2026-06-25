from django.urls import path
from .views import (
    DriverLocationView,
    AvailableDriversView,
    AcceptDeliveryView,
    DriverOrdersView,
    UpdateDeliveryStatusView,
    AvailableOrdersForDriverView,
    NearbyDriversView,
)

urlpatterns = [
    # Driver location
    path('location/', DriverLocationView.as_view(), name='driver_location'),
    
    # Available drivers
    path('drivers/', AvailableDriversView.as_view(), name='available_drivers'),
    path('drivers/nearby/', NearbyDriversView.as_view(), name='nearby_drivers'),
    
    # Delivery acceptance
    path('accept/<int:order_id>/', AcceptDeliveryView.as_view(), name='accept_delivery'),
    
    # Driver orders
    path('orders/', DriverOrdersView.as_view(), name='driver_orders'),
    path('orders/<int:order_id>/status/', UpdateDeliveryStatusView.as_view(), name='update_delivery_status'),
    
    # Available orders for drivers
    path('available/', AvailableOrdersForDriverView.as_view(), name='available_orders'),
]