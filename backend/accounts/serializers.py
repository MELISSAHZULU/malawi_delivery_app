from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import BuyerProfile, SellerProfile, DriverProfile

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    store_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone_number', 'profile_picture', 'is_verified', 'location', 'store_name']
    
    def get_store_name(self, obj):
        if hasattr(obj, 'seller_profile'):
            return obj.seller_profile.store_name
        return None

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)
    store_name = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'role', 'phone_number', 'store_name', 'address']
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        store_name = validated_data.pop('store_name', '')
        address = validated_data.pop('address', '')
        
        user = User.objects.create_user(**validated_data)
        
        # Create role-specific profile
        if user.role == 'buyer':
            BuyerProfile.objects.create(user=user)
        elif user.role == 'seller':
            SellerProfile.objects.create(
                user=user,
                store_name=store_name or f"{user.username}'s Store",
                address=address or '',
                latitude=0,
                longitude=0
            )
        elif user.role == 'driver':
            DriverProfile.objects.create(
                user=user,
                vehicle_type='motorcycle',
                vehicle_plate=''
            )
        
        return user

class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'phone_number', 'profile_picture', 'location', 'role']
        read_only_fields = ['id', 'role']
