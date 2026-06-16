from rest_framework import serializers
from .models import Category, Product, ProductVariant

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'image', 'is_active']

class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ['id', 'name', 'price_adjustment', 'stock']

class ProductSerializer(serializers.ModelSerializer):
    variants = ProductVariantSerializer(many=True, read_only=True)
    seller_name = serializers.CharField(source='seller.store_name', read_only=True)
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True, allow_null=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'unit', 'images',
            'is_available', 'is_featured', 'is_premium', 'stock_quantity',
            'preparation_time', 'rating', 'total_sold', 'created_at',
            'category', 'category_name', 'seller', 'seller_name', 'seller_id', 'variants'
        ]
        read_only_fields = ['rating', 'total_sold', 'created_at']

class ProductCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = [
            'name', 'description', 'price', 'unit', 'images',
            'is_available', 'is_featured', 'is_premium', 'stock_quantity',
            'preparation_time', 'category'
        ]
