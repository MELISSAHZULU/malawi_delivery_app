# payments/views.py (updated with service integration)

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from .models import PaymentTransaction
from .serializers import PaymentTransactionSerializer, PaymentInitiateSerializer
from .services import PayChanguService, PaymentService
from orders.models import Order

class InitiatePaymentView(generics.CreateAPIView):
    """Initiate a PayChangu payment"""
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentInitiateSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        data = serializer.validated_data
        order_id = data['order_id']
        
        try:
            order = Order.objects.get(id=order_id, buyer__user=request.user)
        except Order.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Use PaymentService to initiate payment
        payment_service = PaymentService()
        result = payment_service.initiate_payment(
            order_id=order.id,
            amount=data['amount'],
            mobile_number=data['mobile_number'],
            operator=data['operator']
        )
        
        if result['success']:
            return Response(result, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'error': result.get('error', 'Payment initiation failed')},
                status=status.HTTP_400_BAD_REQUEST
            )

class VerifyPaymentView(generics.RetrieveAPIView):
    """Verify payment status"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        transaction_id = kwargs.get('transaction_id')
        
        try:
            payment = PaymentTransaction.objects.get(transaction_id=transaction_id)
        except PaymentTransaction.DoesNotExist:
            return Response(
                {'error': 'Payment not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Use PaymentService to verify
        payment_service = PaymentService()
        result = payment_service.verify_payment(transaction_id)
        
        if result['success']:
            return Response({
                'success': True,
                'payment': PaymentTransactionSerializer(payment).data,
                'verified': result.get('verified', False),
                'status': result.get('status')
            })
        else:
            return Response(
                {'error': result.get('error', 'Verification failed')},
                status=status.HTTP_400_BAD_REQUEST
            )

class PaymentWebhookView(generics.GenericAPIView):
    """Handle PayChangu webhook callbacks"""
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        # Get signature from headers
        signature = request.headers.get('X-Signature')
        
        # Process webhook
        paychangu_service = PayChanguService()
        result = paychangu_service.process_webhook(
            payload=request.data,
            signature_header=signature
        )
        
        if result['success']:
            return Response({'status': 'ok'}, status=status.HTTP_200_OK)
        else:
            return Response(
                {'error': result.get('error', 'Webhook processing failed')},
                status=status.HTTP_400_BAD_REQUEST
            )

class PaymentStatusView(generics.RetrieveAPIView):
    """Get payment status for an order"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        order_id = kwargs.get('order_id')
        
        payment_service = PaymentService()
        result = payment_service.get_payment_status(order_id)
        
        return Response(result)

class SimulatePaymentView(generics.GenericAPIView):
    """Simulate payment for testing"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = request.data.get('order_id')
        amount = request.data.get('amount')
        success = request.data.get('success', True)
        
        payment_service = PaymentService()
        result = payment_service.simulate_payment(order_id, amount, success)
        
        return Response(result)