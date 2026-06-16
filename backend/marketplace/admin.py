from django.contrib import admin
from .models import Category, Product, ProductVariant

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon', 'is_active', 'parent')
    list_filter = ('is_active', 'parent')
    search_fields = ('name',)
    prepopulated_fields = {'icon': ('name',)}

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'seller', 'price', 'is_available', 'is_featured', 'is_premium', 'rating', 'stock_quantity')
    list_filter = ('is_available', 'is_featured', 'is_premium', 'category')
    search_fields = ('name', 'description', 'seller__store_name')
    readonly_fields = ('rating', 'total_sold', 'created_at', 'updated_at')
    list_editable = ('price', 'stock_quantity', 'is_available')
    fieldsets = (
        ('Basic Information', {
            'fields': ('seller', 'category', 'name', 'description', 'unit')
        }),
        ('Pricing & Stock', {
            'fields': ('price', 'stock_quantity', 'preparation_time')
        }),
        ('Status', {
            'fields': ('is_available', 'is_featured', 'is_premium')
        }),
        ('Images', {
            'fields': ('images',)
        }),
        ('Statistics', {
            'fields': ('rating', 'total_sold', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    list_display = ('product', 'name', 'price_adjustment', 'stock')
    list_filter = ('product',)
    search_fields = ('name', 'product__name')
