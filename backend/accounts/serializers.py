# backend/accounts/serializers.py

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
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


class SellerProfileSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source='user.phone_number', required=False, allow_blank=True)
    location = serializers.CharField(source='user.location', required=False, allow_blank=True)
    
    class Meta:
        model = SellerProfile
        fields = [
            'store_name', 'store_description', 'address', 'delivery_fee', 
            'phone_number', 'location', 'is_active', 'opening_hours'
        ]
    
    def update(self, instance, validated_data):
        # Handle nested user fields
        user_data = {}
        if 'phone_number' in validated_data:
            user_data['phone_number'] = validated_data.pop('phone_number')
        if 'location' in validated_data:
            user_data['location'] = validated_data.pop('location')
        
        # Update seller profile
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update user
        if user_data:
            user = instance.user
            for attr, value in user_data.items():
                setattr(user, attr, value)
            user.save()
        
        return instance


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)
    password2 = serializers.CharField(write_only=True, required=True)
    store_name = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'role', 'phone_number', 'store_name', 'address']
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        
        try:
            validate_password(attrs['password'])
        except ValidationError as e:
            raise serializers.ValidationError({"password": e.messages})
        
        if User.objects.filter(username=attrs['username']).exists():
            raise serializers.ValidationError({"username": "Username already exists."})
        
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({"email": "Email already exists."})
        
        if attrs.get('phone_number') and User.objects.filter(phone_number=attrs['phone_number']).exists():
            raise serializers.ValidationError({"phone_number": "Phone number already exists."})
        
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        store_name = validated_data.pop('store_name', '')
        address = validated_data.pop('address', '')
        
        user = User.objects.create_user(**validated_data)
        
        if user.role == 'buyer':
            BuyerProfile.objects.create(user=user)
        elif user.role == 'seller':
            seller = SellerProfile.objects.create(
                user=user,
                store_name=store_name or f"{user.username}'s Store",
                address=address or '',
                latitude=0,
                longitude=0
            )
            # Create wallet for seller
            try:
                from payments.models import SellerWallet
                SellerWallet.objects.get_or_create(seller=seller)
            except:
                pass
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