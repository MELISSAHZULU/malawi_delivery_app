from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, BuyerProfile, SellerProfile, DriverProfile

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'role', 'phone_number', 'is_verified', 'is_active')
    list_filter = ('role', 'is_verified', 'is_active', 'date_joined')
    search_fields = ('username', 'email', 'phone_number')
    ordering = ('-date_joined',)
    
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {
            'fields': ('role', 'phone_number', 'profile_picture', 'is_verified', 'location', 'latitude', 'longitude')
        }),
    )
    
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Additional Info', {
            'fields': ('role', 'phone_number', 'profile_picture', 'is_verified', 'location')
        }),
    )

@admin.register(BuyerProfile)
class BuyerProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'order_count', 'get_addresses')
    search_fields = ('user__username', 'user__email')
    
    def get_addresses(self, obj):
        return ", ".join(obj.delivery_addresses) if obj.delivery_addresses else "No addresses"
    get_addresses.short_description = "Delivery Addresses"

@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin):
    list_display = ('store_name', 'user', 'is_active', 'is_approved', 'rating', 'total_orders')
    list_filter = ('is_active', 'is_approved', 'rating')
    search_fields = ('store_name', 'user__username', 'address')
    readonly_fields = ('rating', 'total_orders')

@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle_type', 'vehicle_plate', 'is_available', 'is_verified', 'rating')
    list_filter = ('vehicle_type', 'is_available', 'is_verified')
    search_fields = ('user__username', 'vehicle_plate')
    readonly_fields = ('rating', 'total_deliveries')
