from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django import forms
import json
from .models import User, BuyerProfile, SellerProfile, DriverProfile

class SellerProfileForm(forms.ModelForm):
    class Meta:
        model = SellerProfile
        fields = '__all__'
        help_texts = {
            'opening_hours': 'Format: {"monday": "08:00-20:00", "tuesday": "08:00-20:00"}'
        }
    
    def clean_opening_hours(self):
        data = self.cleaned_data.get('opening_hours')
        if isinstance(data, str):
            try:
                return json.loads(data)
            except json.JSONDecodeError:
                raise forms.ValidationError("Invalid JSON format. Use: {\"monday\": \"08:00-20:00\"}")
        return data

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
    list_display = ('user', 'order_count')
    search_fields = ('user__username', 'user__email')
    readonly_fields = ('order_count',)

@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin):
    form = SellerProfileForm
    list_display = ('store_name', 'user', 'is_active', 'is_approved', 'rating', 'total_orders')
    list_filter = ('is_active', 'is_approved')
    search_fields = ('store_name', 'user__username', 'address')
    readonly_fields = ('rating', 'total_orders')
    
    fieldsets = (
        ('Store Information', {
            'fields': ('user', 'store_name', 'store_description', 'store_logo', 'store_banner')
        }),
        ('Location', {
            'fields': ('address', 'latitude', 'longitude')
        }),
        ('Status', {
            'fields': ('is_active', 'is_approved', 'rating', 'total_orders')
        }),
        ('Operations', {
            'fields': ('delivery_fee', 'opening_hours')
        }),
    )

@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle_type', 'vehicle_plate', 'is_available', 'is_verified')
    list_filter = ('vehicle_type', 'is_available', 'is_verified')
    search_fields = ('user__username', 'vehicle_plate')
    readonly_fields = ('rating', 'total_deliveries')
