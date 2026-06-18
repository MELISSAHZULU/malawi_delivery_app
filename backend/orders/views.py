from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db import models
from datetime import timedelta
import json
from .models import Order, OrderTracking
from .serializers import OrderSerializer, OrderCreateSerializer, OrderTrackingSerializer
from accounts.models import BuyerProfile, SellerProfile

class OrderListView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return OrderCreateSerializer
        return OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        print(f"User: {user.username}, Role: {user.role}")
        
        if user.role == 'buyer':
            queryset = Order.objects.filter(buyer__user=user).order_by('-created_at')
        elif user.role == 'seller':
            # Filter orders where the seller is the logged-in user
            queryset = Order.objects.filter(seller__user=user).order_by('-created_at')
        elif user.role == 'driver':
            queryset = Order.objects.filter(driver=user).order_by('-created_at')
        else:
            queryset = Order.objects.none()
        
        print(f"Found {queryset.count()} orders for {user.username}")
        return queryset
    
    def create(self, request, *args, **kwargs):
        try:
            print("Creating order...")
            print("Request data:", request.data)
            
            # Get buyer profile
            try:
                buyer = BuyerProfile.objects.get(user=request.user)
                print(f"Buyer found: {buyer.user.username}")
            except BuyerProfile.DoesNotExist:
                return Response(
                    {'error': 'Buyer profile not found'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get seller - use first available seller or from request
            seller_id = request.data.get('seller_id')
            if seller_id:
                try:
                    seller = SellerProfile.objects.get(id=seller_id)
                except SellerProfile.DoesNotExist:
                    return Response(
                        {'error': 'Seller not found'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                # Use first available seller (for testing)
                seller = SellerProfile.objects.first()
                if not seller:
                    return Response(
                        {'error': 'No seller available'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            print(f"Seller: {seller.store_name}")
            
            # Generate order number
            import random
            order_number = f"MWD-{timezone.now().strftime('%Y%m%d')}{random.randint(100, 999)}"
            
            # Create order
            order = Order.objects.create(
                buyer=buyer,
                seller=seller,
                order_number=order_number,
                status='pending',
                items=request.data.get('items', []),
                subtotal=request.data.get('subtotal', 0),
                delivery_fee=request.data.get('delivery_fee', 1500),
                total=request.data.get('total', 0),
                delivery_address=request.data.get('delivery_address', ''),
                payment_method=request.data.get('payment_method', 'paychangu'),
                payment_status='pending',
            )
            
            print(f"Order created: {order.order_number}")
            
            # Create tracking entry
            OrderTracking.objects.create(
                order=order,
                status='pending',
                note='Order placed'
            )
            
            return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"Error creating order: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

class OrderDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'buyer':
            return Order.objects.filter(buyer__user=user)
        elif user.role == 'seller':
            return Order.objects.filter(seller__user=user)
        elif user.role == 'driver':
            return Order.objects.filter(driver=user)
        return Order.objects.none()

class OrderTrackingView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderTrackingSerializer
    
    def get_queryset(self):
        order_id = self.kwargs.get('order_id')
        return OrderTracking.objects.filter(order_id=order_id)

class UpdateOrderStatusView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'seller':
            return Order.objects.filter(seller__user=user)
        return Order.objects.all()
    
    def update(self, request, *args, **kwargs):
        order = self.get_object()
        new_status = request.data.get('status')
        location = request.data.get('location', {})
        note = request.data.get('note', '')
        
        if not new_status:
            return Response(
                {'error': 'Status is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user has permission
        user = request.user
        if user.role == 'seller' and order.seller.user != user:
            return Response(
                {'error': 'Not authorized to update this order'},
                status=status.HTTP_403_FORBIDDEN
            )
        elif user.role == 'driver' and order.driver != user:
            return Response(
                {'error': 'Not authorized to update this order'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update order status
        order.status = new_status
        order.save()
        
        # Create tracking entry
        OrderTracking.objects.create(
            order=order,
            status=new_status,
            location=location,
            note=note
        )
        
        return Response(OrderSerializer(order).data)

class WeeklyEarningsView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        if user.role != 'seller':
            return Response(
                {'error': 'Only sellers can view earnings'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get last 7 days
        end_date = timezone.now()
        start_date = end_date - timedelta(days=7)
        
        # Get completed orders for this seller
        orders = Order.objects.filter(
            seller__user=user,
            status='delivered',
            created_at__gte=start_date,
            created_at__lte=end_date
        )
        
        # Calculate daily earnings
        daily_earnings = {}
        weekdays = []
        for i in range(7):
            day = start_date + timedelta(days=i)
            day_orders = orders.filter(created_at__date=day.date())
            day_total = day_orders.aggregate(total=models.Sum('total'))['total'] or 0
            daily_earnings[day.strftime('%a')] = float(day_total)
            weekdays.append(day.strftime('%a'))
        
        # Calculate total earnings
        total_earnings = sum(daily_earnings.values())
        
        # Get wallet balance
        wallet_balance = 0
        if hasattr(user, 'seller_profile') and hasattr(user.seller_profile, 'wallet'):
            wallet_balance = float(user.seller_profile.wallet.balance)
        
        return Response({
            'weekly_earnings': daily_earnings,
            'total': total_earnings,
            'wallet_balance': wallet_balance,
            'weekdays': weekdays,
            'orders_count': orders.count()
        })
