from django.urls import path
from .views import (
    OrderListView,
    OrderDetailView,
    OrderTrackingView,
    UpdateOrderStatusView,
)

urlpatterns = [
    path('', OrderListView.as_view(), name='order_list'),
    path('<int:pk>/', OrderDetailView.as_view(), name='order_detail'),
    path('<int:order_id>/tracking/', OrderTrackingView.as_view(), name='order_tracking'),
    path('<int:pk>/status/', UpdateOrderStatusView.as_view(), name='update_order_status'),
]
