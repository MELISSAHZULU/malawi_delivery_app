from django.contrib import admin
from .models import PaymentTransaction

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'order', 'amount', 'operator', 'mobile_number', 'status', 'created_at')
    list_filter = ('status', 'operator', 'created_at')
    search_fields = ('transaction_id', 'paychangu_reference', 'mobile_number', 'order__order_number')
    readonly_fields = ('transaction_id', 'created_at')
    list_editable = ('status',)
    
    fieldsets = (
        ('Transaction Details', {
            'fields': ('transaction_id', 'order', 'amount', 'currency')
        }),
        ('PayChangu Info', {
            'fields': ('paychangu_reference', 'paychangu_status')
        }),
        ('Customer Info', {
            'fields': ('mobile_number', 'operator')
        }),
        ('Status', {
            'fields': ('status', 'completed_at')
        }),
        ('Data', {
            'fields': ('callback_data',),
            'classes': ('collapse',)
        }),
    )
