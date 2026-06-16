# payments/urls.py

from django.urls import path
from .views import (
    InitiatePaymentView,
    VerifyPaymentView,
    PaymentWebhookView,
    PaymentStatusView,
    SimulatePaymentView
)

urlpatterns = [
    path('initiate/', InitiatePaymentView.as_view(), name='initiate_payment'),
    path('verify/<str:transaction_id>/', VerifyPaymentView.as_view(), name='verify_payment'),
    path('webhook/', PaymentWebhookView.as_view(), name='payment_webhook'),
    path('status/<int:order_id>/', PaymentStatusView.as_view(), name='payment_status'),
    path('simulate/', SimulatePaymentView.as_view(), name='simulate_payment'),
]