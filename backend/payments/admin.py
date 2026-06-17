from django.contrib import admin
from .models import PaymentTransaction, SellerWallet

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'order', 'amount', 'operator', 'mobile_number', 'status', 'created_at')
    list_filter = ('status', 'operator', 'created_at')
    search_fields = ('transaction_id', 'paychangu_reference', 'mobile_number', 'order__order_number')
    readonly_fields = ('transaction_id', 'created_at')
    list_editable = ('status',)

@admin.register(SellerWallet)
class SellerWalletAdmin(admin.ModelAdmin):
    list_display = ('seller', 'balance', 'total_earned', 'total_withdrawn', 'updated_at')
    search_fields = ('seller__store_name', 'seller__user__username')
    readonly_fields = ('updated_at',)
