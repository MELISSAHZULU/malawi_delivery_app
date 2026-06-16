from django.contrib import admin
from .models import DriverLocation, DeliveryAssignment

@admin.register(DriverLocation)
class DriverLocationAdmin(admin.ModelAdmin):
    list_display = ('driver', 'latitude', 'longitude', 'is_active', 'last_updated')
    list_filter = ('is_active',)
    search_fields = ('driver__username',)
    readonly_fields = ('last_updated',)

@admin.register(DeliveryAssignment)
class DeliveryAssignmentAdmin(admin.ModelAdmin):
    list_display = ('order', 'driver', 'status', 'assigned_at', 'accepted_at', 'delivered_at')
    list_filter = ('status', 'assigned_at')
    search_fields = ('order__order_number', 'driver__username')
    readonly_fields = ('assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at')
    list_editable = ('status',)
    
    fieldsets = (
        ('Assignment', {
            'fields': ('order', 'driver', 'status')
        }),
        ('Timestamps', {
            'fields': ('assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at')
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
    )
