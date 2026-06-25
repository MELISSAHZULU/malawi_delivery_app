import json
from datetime import datetime
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import DeliveryAssignment, DriverLocation, DriverActivityLog
from orders.models import Order
from accounts.models import DriverProfile

User = get_user_model()


class DeliveryTrackingConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for real-time delivery tracking"""
    
    async def connect(self):
        self.order_id = self.scope['url_route']['kwargs']['order_id']
        self.user = self.scope['user']
        self.group_name = f'delivery_{self.order_id}'
        
        # Check if user is authenticated
        if not self.user.is_authenticated:
            await self.close()
            return
        
        # Check if user is authorized to track this order
        if not await self.is_authorized():
            await self.close()
            return
        
        # Join group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()
        
        # Send initial status
        initial_data = await self.get_order_status()
        await self.send(text_data=json.dumps(initial_data))
    
    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        """Handle messages from client"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'ping':
                await self.send(text_data=json.dumps({'type': 'pong'}))
            
            elif message_type == 'location_update' and self.user.role == 'driver':
                await self.handle_driver_location(data)
            
            elif message_type == 'status_update' and self.user.role == 'driver':
                await self.handle_status_update(data)
                
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': str(e)
            }))
    
    async def driver_location(self, event):
        """Send driver location to WebSocket client"""
        await self.send(text_data=json.dumps({
            'type': 'driver_location',
            'latitude': event['latitude'],
            'longitude': event['longitude'],
            'driver_name': event.get('driver_name', 'Driver'),
            'driver_phone': event.get('driver_phone', ''),
            'eta': event.get('eta', 'Calculating...'),
            'timestamp': event.get('timestamp', datetime.now().isoformat())
        }))
    
    async def status_update(self, event):
        """Send status update to WebSocket client"""
        await self.send(text_data=json.dumps({
            'type': 'status_update',
            'status': event['status'],
            'order_id': event.get('order_id', self.order_id),
            'timestamp': event.get('timestamp', datetime.now().isoformat())
        }))
    
    async def driver_assigned(self, event):
        """Notify customer that driver has been assigned"""
        await self.send(text_data=json.dumps({
            'type': 'driver_assigned',
            'driver_name': event['driver_name'],
            'driver_phone': event.get('driver_phone', ''),
            'vehicle': event.get('vehicle', 'Motorcycle'),
            'eta': event.get('eta', 'Calculating...')
        }))
    
    @database_sync_to_async
    def is_authorized(self):
        """Check if user is authorized to track this order"""
        try:
            # Check if assignment exists
            try:
                assignment = DeliveryAssignment.objects.get(order_id=self.order_id)
            except DeliveryAssignment.DoesNotExist:
                # If no assignment yet, check if order exists
                order = Order.objects.get(id=self.order_id)
                
                # Customer can track their own order
                if self.user.role == 'buyer' and order.buyer == self.user:
                    return True
                
                # Seller can track their store's orders
                if self.user.role == 'seller' and order.seller.user == self.user:
                    return True
                
                # Admin can track all
                if self.user.is_superuser:
                    return True
                
                return False
            
            order = assignment.order
            
            # Customer can track their own order
            if self.user.role == 'buyer' and order.buyer == self.user:
                return True
            
            # Driver can track their own delivery
            if self.user.role == 'driver' and assignment.driver == self.user:
                return True
            
            # Seller can track their store's orders
            if self.user.role == 'seller' and order.seller.user == self.user:
                return True
            
            # Admin can track all
            if self.user.is_superuser:
                return True
            
            return False
        except Order.DoesNotExist:
            return False
    
    @database_sync_to_async
    def get_order_status(self):
        """Get current order status from database"""
        try:
            assignment = DeliveryAssignment.objects.get(order_id=self.order_id)
            return {
                'type': 'status_update',
                'status': assignment.status,
                'order_id': self.order_id,
                'driver_name': assignment.driver.username if assignment.driver else None,
                'driver_phone': assignment.driver.phone_number if assignment.driver else None,
                'picked_up_at': assignment.picked_up_at.isoformat() if assignment.picked_up_at else None,
                'delivered_at': assignment.delivered_at.isoformat() if assignment.delivered_at else None,
            }
        except DeliveryAssignment.DoesNotExist:
            return {
                'type': 'status_update',
                'status': 'pending',
                'order_id': self.order_id,
                'driver_name': None,
                'driver_phone': None,
            }
    
    @database_sync_to_async
    def handle_driver_location(self, data):
        """Update driver location in database"""
        try:
            latitude = data.get('latitude')
            longitude = data.get('longitude')
            
            if latitude is not None and longitude is not None:
                # Update driver location
                location, created = DriverLocation.objects.update_or_create(
                    driver=self.user,
                    defaults={
                        'latitude': latitude,
                        'longitude': longitude,
                        'is_active': True,
                    }
                )
                
                # Get delivery assignment
                assignment = DeliveryAssignment.objects.filter(
                    driver=self.user,
                    order_id=self.order_id
                ).first()
                
                if assignment and assignment.order.delivery_latitude:
                    from .views import calculate_eta
                    eta = calculate_eta(
                        float(latitude), float(longitude),
                        float(assignment.order.delivery_latitude) if assignment.order.delivery_latitude else None,
                        float(assignment.order.delivery_longitude) if assignment.order.delivery_longitude else None
                    )
                    
                    # Send to all in group (customer)
                    from channels.layers import get_channel_layer
                    channel_layer = get_channel_layer()
                    channel_layer.group_send(
                        self.group_name,
                        {
                            'type': 'driver_location',
                            'latitude': float(latitude),
                            'longitude': float(longitude),
                            'driver_name': self.user.username,
                            'driver_phone': self.user.phone_number,
                            'eta': eta,
                            'timestamp': datetime.now().isoformat()
                        }
                    )
        except Exception as e:
            print(f"Error updating driver location: {e}")
    
    @database_sync_to_async
    def handle_status_update(self, data):
        """Update order status"""
        try:
            new_status = data.get('status')
            
            if new_status:
                assignment = DeliveryAssignment.objects.filter(
                    driver=self.user,
                    order_id=self.order_id
                ).first()
                
                if assignment:
                    # Validate status transition
                    valid_transitions = {
                        'pending': ['accepted', 'cancelled'],
                        'accepted': ['picked_up', 'cancelled'],
                        'picked_up': ['driving', 'cancelled'],
                        'driving': ['delivered', 'cancelled'],
                        'delivered': [],
                        'cancelled': []
                    }
                    
                    if new_status in valid_transitions.get(assignment.status, []):
                        assignment.status = new_status
                        if new_status == 'picked_up':
                            assignment.picked_up_at = datetime.now()
                            assignment.order.status = 'picked_up'
                        elif new_status == 'delivered':
                            assignment.delivered_at = datetime.now()
                            assignment.order.status = 'delivered'
                        elif new_status == 'cancelled':
                            assignment.order.status = 'cancelled'
                        
                        assignment.save()
                        assignment.order.save()
                        
                        # Broadcast status update to customer
                        from channels.layers import get_channel_layer
                        channel_layer = get_channel_layer()
                        channel_layer.group_send(
                            self.group_name,
                            {
                                'type': 'status_update',
                                'status': new_status,
                                'order_id': self.order_id,
                                'timestamp': datetime.now().isoformat()
                            }
                        )
        except Exception as e:
            print(f"Error updating status: {e}")


def notify_customer(customer_id, data):
    """Send notification to customer via WebSocket"""
    try:
        from channels.layers import get_channel_layer
        channel_layer = get_channel_layer()
        
        # Find all orders for this customer
        orders = Order.objects.filter(buyer_id=customer_id)
        
        for order in orders:
            try:
                channel_layer.group_send(
                    f'delivery_{order.id}',
                    data
                )
            except:
                pass
    except:
        pass