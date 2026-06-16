from django.contrib import admin
from .models import Order, OrderTracking

class OrderTrackingInline(admin.TabularInline):
    model = OrderTracking
    extra = 0
    readonly_fields = ('created_at',)
    fields = ('status', 'location', 'note', 'created_at')

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'buyer', 'seller', 'driver', 'status', 'total', 'payment_status', 'created_at')
    list_filter = ('status', 'payment_status', 'created_at')
    search_fields = ('order_number', 'buyer__user__username', 'seller__store_name', 'driver__username')
    readonly_fields = ('order_number', 'created_at', 'updated_at')
    list_editable = ('status', 'payment_status')
    
    inlines = [OrderTrackingInline]
    
    fieldsets = (
        ('Order Information', {
            'fields': ('order_number', 'buyer', 'seller', 'driver', 'status')
        }),
        ('Items & Pricing', {
            'fields': ('items', 'subtotal', 'delivery_fee', 'total')
        }),
        ('Delivery Details', {
            'fields': ('delivery_address', 'delivery_latitude', 'delivery_longitude', 'estimated_delivery_time', 'actual_delivery_time')
        }),
        ('Payment', {
            'fields': ('payment_method', 'payment_status', 'payment_transaction_id')
        }),
        ('Tracking', {
            'fields': ('tracking_updates',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(OrderTracking)
class OrderTrackingAdmin(admin.ModelAdmin):
    list_display = ('order', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('order__order_number',)
    readonly_fields = ('created_at',)
