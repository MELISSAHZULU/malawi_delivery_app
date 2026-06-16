from rest_framework import serializers
from .models import Category, Product

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ('id', 'name', 'icon', 'image', 'is_active')

class ProductSerializer(serializers.ModelSerializer):
    seller_name = serializers.CharField(source='seller.store_name', read_only=True)
    delivery_time = serializers.CharField(read_only=True)
    
    class Meta:
        model = Product
        fields = ('id', 'seller', 'seller_name', 'category', 'name', 'description',
                 'price', 'unit', 'images', 'is_available', 'is_featured', 
                 'is_premium', 'stock_quantity', 'preparation_time', 
                 'delivery_time', 'rating', 'total_sold', 'created_at')
        read_only_fields = ('created_at', 'updated_at')

class ProductCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'