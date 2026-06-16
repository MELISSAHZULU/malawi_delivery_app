from django.urls import path
from .views import (
    CategoryListView, ProductListView, ProductDetailView,
    SellerProductListView, SellerProductDetailView
)

urlpatterns = [
    path('categories/', CategoryListView.as_view(), name='categories'),
    path('products/', ProductListView.as_view(), name='products'),
    path('products/<int:pk>/', ProductDetailView.as_view(), name='product-detail'),
    path('seller/products/', SellerProductListView.as_view(), name='seller-products'),
    path('seller/products/<int:pk>/', SellerProductDetailView.as_view(), name='seller-product-detail'),
]