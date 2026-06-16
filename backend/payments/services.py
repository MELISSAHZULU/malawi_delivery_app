# payments/services.py

import hmac
import hashlib
import json
import uuid
from datetime import datetime
from django.conf import settings
from django.utils import timezone
import requests
from decimal import Decimal
from .models import PaymentTransaction

class PayChanguService:
    """
    Service for integrating with PayChangu Mobile Money API
    Supports Airtel Money and TNM Mpamba in Malawi
    """
    
    def __init__(self):
        self.api_key = getattr(settings, 'PAYCHANGU_API_KEY', '')
        self.api_secret = getattr(settings, 'PAYCHANGU_SECRET_KEY', '')
        self.base_url = getattr(settings, 'PAYCHANGU_BASE_URL', 'https://api.paychangu.com/v1')
        self.callback_url = getattr(settings, 'PAYCHANGU_CALLBACK_URL', '')
        self.redirect_url = getattr(settings, 'PAYCHANGU_REDIRECT_URL', '')
        
    def initiate_payment(self, payment: PaymentTransaction) -> dict:
        """
        Initiate a payment with PayChangu API
        
        Args:
            payment: PaymentTransaction instance
            
        Returns:
            dict: {
                'success': bool,
                'reference': str,
                'payment_url': str,
                'error': str (if failed)
            }
        """
        try:
            # Prepare payload for PayChangu
            payload = {
                'transaction_id': payment.transaction_id,
                'amount': float(payment.amount),
                'currency': payment.currency,
                'mobile_number': payment.mobile_number,
                'operator': payment.operator,
                'reference': f"MWD-{uuid.uuid4().hex[:8].upper()}",
                'description': f"Order #{payment.order.order_number} - Malawi Delivery",
                'callback_url': self.callback_url,
                'redirect_url': self.redirect_url,
                'metadata': {
                    'order_id': payment.order.id,
                    'order_number': payment.order.order_number,
                    'user_id': payment.order.buyer.user.id
                }
            }
            
            # Generate signature for authentication
            signature = self._generate_signature(payload)
            
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'X-Signature': signature,
                'Content-Type': 'application/json'
            }
            
            # Make API request to PayChangu
            response = requests.post(
                f'{self.base_url}/payments/initiate',
                json=payload,
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200 or response.status_code == 201:
                data = response.json()
                
                # Update payment with PayChangu reference
                payment.paychangu_reference = data.get('reference')
                payment.paychangu_status = 'pending'
                payment.callback_data['request'] = payload
                payment.callback_data['response'] = data
                payment.save()
                
                return {
                    'success': True,
                    'reference': data.get('reference'),
                    'payment_url': data.get('payment_url'),
                    'transaction_id': data.get('transaction_id')
                }
            else:
                error_msg = response.json().get('message', 'Payment initiation failed')
                return {
                    'success': False,
                    'error': error_msg
                }
                
        except requests.exceptions.Timeout:
            return {
                'success': False,
                'error': 'Payment gateway timeout. Please try again.'
            }
        except requests.exceptions.ConnectionError:
            return {
                'success': False,
                'error': 'Network error. Please check your connection.'
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Payment initialization error: {str(e)}'
            }
    
    def verify_payment(self, transaction_id: str) -> dict:
        """
        Verify payment status with PayChangu API
        
        Args:
            transaction_id: PayChangu transaction ID
            
        Returns:
            dict: {
                'success': bool,
                'status': str,
                'reference': str,
                'amount': float,
                'verified': bool
            }
        """
        try:
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            response = requests.get(
                f'{self.base_url}/payments/verify/{transaction_id}',
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Check if payment is completed
                status = data.get('status', 'pending')
                is_completed = status.lower() == 'completed'
                
                return {
                    'success': True,
                    'status': status,
                    'reference': data.get('reference'),
                    'amount': data.get('amount'),
                    'verified': is_completed,
                    'data': data
                }
            else:
                return {
                    'success': False,
                    'error': 'Payment verification failed'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Verification error: {str(e)}'
            }
    
    def process_webhook(self, payload: dict, signature_header: str = None) -> dict:
        """
        Process incoming webhook from PayChangu
        
        Args:
            payload: Webhook payload
            signature_header: X-Signature header for verification
            
        Returns:
            dict: Processed webhook data
        """
        # Verify webhook signature (if provided)
        if signature_header:
            if not self._verify_webhook_signature(payload, signature_header):
                return {
                    'success': False,
                    'error': 'Invalid webhook signature'
                }
        
        # Extract webhook data
        reference = payload.get('reference')
        status = payload.get('status')
        transaction_id = payload.get('transaction_id')
        amount = payload.get('amount')
        
        # Find payment by reference
        try:
            payment = PaymentTransaction.objects.get(
                paychangu_reference=reference
            )
        except PaymentTransaction.DoesNotExist:
            return {
                'success': False,
                'error': f'Payment with reference {reference} not found'
            }
        
        # Update payment status based on webhook
        if status.lower() == 'completed':
            payment.status = 'completed'
            payment.completed_at = timezone.now()
            payment.paychangu_status = 'completed'
            payment.callback_data['webhook'] = payload
            
            # Update order status
            order = payment.order
            order.payment_status = 'completed'
            order.payment_transaction_id = transaction_id
            order.status = 'confirmed'
            order.save()
            
        elif status.lower() == 'failed':
            payment.status = 'failed'
            payment.paychangu_status = 'failed'
            payment.callback_data['webhook'] = payload
            payment.callback_data['error'] = payload.get('error_message', 'Payment failed')
            
        else:
            payment.paychangu_status = status
            payment.callback_data['webhook'] = payload
        
        payment.save()
        
        return {
            'success': True,
            'payment_id': payment.transaction_id,
            'status': payment.status,
            'order_number': payment.order.order_number
        }
    
    def check_payment_status(self, payment: PaymentTransaction) -> dict:
        """
        Check and update payment status from PayChangu
        
        Args:
            payment: PaymentTransaction instance
            
        Returns:
            dict: Current payment status
        """
        if not payment.paychangu_reference:
            return {
                'success': False,
                'error': 'No PayChangu reference found'
            }
        
        result = self.verify_payment(payment.paychangu_reference)
        
        if result['success']:
            if result['verified'] and payment.status != 'completed':
                payment.status = 'completed'
                payment.completed_at = timezone.now()
                payment.paychangu_status = 'completed'
                payment.save()
                
                # Update order payment status
                order = payment.order
                order.payment_status = 'completed'
                order.save()
                
            elif not result['verified'] and payment.status == 'pending':
                payment.paychangu_status = result.get('status', 'pending')
                payment.save()
        
        return {
            'success': result.get('success', False),
            'status': payment.status,
            'paychangu_status': payment.paychangu_status
        }
    
    def refund_payment(self, payment: PaymentTransaction) -> dict:
        """
        Process refund for a completed payment
        
        Args:
            payment: PaymentTransaction instance
            
        Returns:
            dict: Refund result
        """
        if payment.status != 'completed':
            return {
                'success': False,
                'error': 'Payment is not completed'
            }
        
        if not payment.paychangu_reference:
            return {
                'success': False,
                'error': 'No PayChangu reference found'
            }
        
        try:
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'reference': payment.paychangu_reference,
                'reason': 'Refund requested by customer'
            }
            
            response = requests.post(
                f'{self.base_url}/payments/refund',
                json=payload,
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                payment.status = 'refunded'
                payment.callback_data['refund'] = data
                payment.save()
                
                return {
                    'success': True,
                    'refund_id': data.get('refund_id'),
                    'message': 'Refund processed successfully'
                }
            else:
                return {
                    'success': False,
                    'error': response.json().get('message', 'Refund failed')
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Refund error: {str(e)}'
            }
    
    def _generate_signature(self, payload: dict) -> str:
        """
        Generate HMAC-SHA256 signature for request
        
        Args:
            payload: Request payload
            
        Returns:
            str: Signature hash
        """
        payload_string = json.dumps(payload, sort_keys=True)
        signature = hmac.new(
            self.api_secret.encode('utf-8'),
            payload_string.encode('utf-8'),
            hashlib.sha256
        )
        return signature.hexdigest()
    
    def _verify_webhook_signature(self, payload: dict, signature_header: str) -> bool:
        """
        Verify webhook signature
        
        Args:
            payload: Webhook payload
            signature_header: X-Signature header
            
        Returns:
            bool: True if signature is valid
        """
        payload_string = json.dumps(payload, sort_keys=True)
        expected_signature = hmac.new(
            self.api_secret.encode('utf-8'),
            payload_string.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(expected_signature, signature_header)


# Convenience functions for quick integration

def initiate_paychangu_payment(order_id: int, mobile_number: str, operator: str) -> dict:
    """
    Quick function to initiate a PayChangu payment
    
    Args:
        order_id: Order ID
        mobile_number: Mobile money number
        operator: 'airtel' or 'tnm'
        
    Returns:
        dict: Payment result
    """
    from orders.models import Order
    
    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return {'success': False, 'error': 'Order not found'}
    
    # Create payment record
    payment = PaymentTransaction.objects.create(
        order=order,
        transaction_id=f"PAY-{uuid.uuid4().hex[:12].upper()}",
        amount=order.total,
        currency='MWK',
        mobile_number=mobile_number,
        operator=operator,
        status='pending'
    )
    
    # Initiate with PayChangu
    service = PayChanguService()
    result = service.initiate_payment(payment)
    
    return result

def verify_paychangu_payment(transaction_id: str) -> dict:
    """
    Quick function to verify payment
    
    Args:
        transaction_id: PayChangu transaction ID
        
    Returns:
        dict: Verification result
    """
    service = PayChanguService()
    return service.verify_payment(transaction_id)

def get_payment_status(order_id: int) -> dict:
    """
    Get payment status for an order
    
    Args:
        order_id: Order ID
        
    Returns:
        dict: Payment status
    """
    try:
        payment = PaymentTransaction.objects.filter(
            order_id=order_id
        ).latest('created_at')
    except PaymentTransaction.DoesNotExist:
        return {'status': 'No payment found'}
    
    service = PayChanguService()
    return service.check_payment_status(payment)


# ============================================
# Payment Service for Flutter Frontend
# ============================================

class PaymentService:
    """
    Service class for handling payment operations from the Flutter frontend
    This matches the structure expected by the Flutter payment_service.dart
    """
    
    def __init__(self):
        self.paychangu = PayChanguService()
    
    def initiate_payment(self, order_id: int, amount: float, 
                        mobile_number: str, operator: str) -> dict:
        """
        Initiate a payment (called from Flutter frontend)
        """
        try:
            from orders.models import Order
            order = Order.objects.get(id=order_id)
            
            # Create payment record
            payment = PaymentTransaction.objects.create(
                order=order,
                transaction_id=f"PAY-{uuid.uuid4().hex[:12].upper()}",
                amount=amount,
                currency='MWK',
                mobile_number=mobile_number,
                operator=operator,
                status='pending'
            )
            
            # Initiate with PayChangu
            result = self.paychangu.initiate_payment(payment)
            
            if result['success']:
                return {
                    'success': True,
                    'transaction_id': payment.transaction_id,
                    'paychangu_reference': result.get('reference'),
                    'payment_url': result.get('payment_url'),
                    'status': payment.status
                }
            else:
                payment.status = 'failed'
                payment.save()
                return {
                    'success': False,
                    'error': result.get('error', 'Payment initiation failed')
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def verify_payment(self, transaction_id: str) -> dict:
        """
        Verify payment (called from Flutter frontend)
        """
        return self.paychangu.verify_payment(transaction_id)
    
    def get_payment_status(self, order_id: int) -> dict:
        """
        Get payment status (called from Flutter frontend)
        """
        try:
            payment = PaymentTransaction.objects.filter(
                order_id=order_id
            ).latest('created_at')
            
            result = self.paychangu.check_payment_status(payment)
            
            return {
                'success': True,
                'status': payment.status,
                'paychangu_status': payment.paychangu_status,
                'amount': payment.amount,
                'transaction_id': payment.transaction_id,
                'reference': payment.paychangu_reference,
                'created_at': payment.created_at
            }
        except PaymentTransaction.DoesNotExist:
            return {
                'success': False,
                'error': 'No payment found for this order'
            }
    
    def simulate_payment(self, order_id: int, amount: float, success: bool) -> dict:
        """
        Simulate payment for testing purposes
        Called from Flutter frontend during development
        """
        from orders.models import Order
        
        try:
            order = Order.objects.get(id=order_id)
        except Order.DoesNotExist:
            return {'success': False, 'error': 'Order not found'}
        
        # Create or find payment
        payment, created = PaymentTransaction.objects.get_or_create(
            order=order,
            defaults={
                'transaction_id': f"SIM-{uuid.uuid4().hex[:12].upper()}",
                'amount': amount,
                'currency': 'MWK',
                'mobile_number': '+265 99 999 9999',
                'operator': 'airtel',
                'status': 'pending'
            }
        )
        
        if success:
            payment.status = 'completed'
            payment.completed_at = timezone.now()
            payment.paychangu_status = 'completed'
            payment.paychangu_reference = f"SIM-{uuid.uuid4().hex[:8].upper()}"
            payment.save()
            
            # Update order payment status
            order.payment_status = 'completed'
            order.save()
            
            return {
                'success': True,
                'payment_id': payment.transaction_id,
                'status': 'completed',
                'message': 'Payment simulated successfully'
            }
        else:
            payment.status = 'failed'
            payment.save()
            
            return {
                'success': False,
                'payment_id': payment.transaction_id,
                'status': 'failed',
                'error': 'Payment simulation failed'
            }