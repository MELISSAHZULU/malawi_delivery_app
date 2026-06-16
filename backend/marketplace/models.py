from django.db import models
from accounts.models import SellerProfile

class Category(models.Model):
    name = models.CharField(max_length=50)
    icon = models.CharField(max_length=50, blank=True)
    image = models.ImageField(upload_to='categories/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True)
    
    class Meta:
        verbose_name_plural = "Categories"
    
    def __str__(self):
        return self.name

class Product(models.Model):
    seller = models.ForeignKey(SellerProfile, on_delete=models.CASCADE, related_name='products')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    name = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=20, default='piece')
    images = models.JSONField(default=list)
    is_available = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    is_premium = models.BooleanField(default=False)
    stock_quantity = models.IntegerField(default=0)
    preparation_time = models.IntegerField(default=15)
    rating = models.FloatField(default=0)
    total_sold = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} - {self.seller.store_name}"

class ProductVariant(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    name = models.CharField(max_length=50)
    price_adjustment = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    stock = models.IntegerField(default=0)
    
    def __str__(self):
        return f"{self.product.name} - {self.name}"
