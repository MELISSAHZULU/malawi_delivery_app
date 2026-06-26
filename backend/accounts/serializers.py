from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import BuyerProfile, SellerProfile, DriverProfile

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    store_name = serializers.SerializerMethodField()
    seller_address = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone_number', 'profile_picture', 
                  'is_verified', 'location', 'store_name', 'seller_address']
    
    def get_store_name(self, obj):
        if hasattr(obj, 'seller_profile'):
            return obj.seller_profile.store_name
        return None
    
    def get_seller_address(self, obj):
        if hasattr(obj, 'seller_profile'):
            return obj.seller_profile.address
        return obj.location


class SellerProfileSerializer(serializers.ModelSerializer):
    # These fields will be handled manually in update
    phone_number = serializers.CharField(write_only=True, required=False, allow_blank=True)
    location = serializers.CharField(write_only=True, required=False, allow_blank=True)
    seller_address = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    class Meta:
        model = SellerProfile
        fields = [
            'store_name', 'store_description', 'address', 'delivery_fee', 
            'phone_number', 'location', 'seller_address', 'is_active', 'opening_hours'
        ]
        read_only_fields = ['is_active']
    
    def update(self, instance, validated_data):
        # Extract user-related fields
        phone_number = validated_data.pop('phone_number', None)
        location = validated_data.pop('location', None)
        seller_address = validated_data.pop('seller_address', None)
        
        # Update seller profile fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update user fields
        user = instance.user  # Get the User instance
        if phone_number is not None:
            user.phone_number = phone_number
        if location is not None:
            user.location = location
        if seller_address is not None:
            # Store seller address in the seller profile address field
            instance.address = seller_address
            instance.save()
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
    store_name = serializers.SerializerMethodField()
    seller_address = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'phone_number', 'profile_picture', 
                  'location', 'role', 'store_name', 'seller_address']
        read_only_fields = ['id', 'role']
    
    def get_store_name(self, obj):
        if hasattr(obj, 'seller_profile'):
            return obj.seller_profile.store_name
        return None
    
    def get_seller_address(self, obj):
        if hasattr(obj, 'seller_profile'):
            return obj.seller_profile.address
        return obj.location
