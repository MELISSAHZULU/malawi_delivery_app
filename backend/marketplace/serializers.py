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
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'unit', 
            'image', 'images', 'image_url',  # ✅ Added image_url
            'is_available', 'is_featured', 'is_premium', 'stock_quantity',
            'preparation_time', 'rating', 'total_sold', 'created_at',
            'category', 'category_name', 'seller', 'seller_name', 'seller_id', 'variants'
        ]
        read_only_fields = ['rating', 'total_sold', 'created_at']
    
    def get_image_url(self, obj):
        """Get the image URL"""
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        if obj.images and len(obj.images) > 0:
            return obj.images[0]
        return None

class ProductCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = [
            'name', 'description', 'price', 'unit', 
            'image', 'images',
            'is_available', 'is_featured', 'is_premium', 'stock_quantity',
            'preparation_time', 'category'
        ]
