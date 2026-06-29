from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, ProfileSerializer, SellerProfileSerializer
from .models import User, SellerProfile

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """
    Register a new user with support for both JSON and multipart/form-data.
    Supports image uploads for profile photos and identity documents.
    """
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def post(self, request, *args, **kwargs):
        # Handle both JSON and multipart data
        # The parser classes handle the content type automatically
        serializer = self.get_serializer(data=request.data)
        
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            
            # Prepare user data for response
            user_data = UserSerializer(user).data
            
            # Add role-specific data
            if user.role == 'seller' and hasattr(user, 'seller_profile'):
                user_data['store_name'] = user.seller_profile.store_name
                user_data['seller_address'] = user.seller_profile.address
            elif user.role == 'driver' and hasattr(user, 'driver_profile'):
                driver = user.driver_profile
                user_data['vehicle_type'] = driver.vehicle_type
                user_data['vehicle_plate'] = driver.vehicle_plate
                user_data['vehicle_color'] = driver.vehicle_color
                user_data['vehicle_model'] = driver.vehicle_model
                user_data['vehicle_image'] = driver.vehicle_image.url if driver.vehicle_image else None
                user_data['national_id'] = driver.national_id
                user_data['national_id_image'] = driver.national_id_image
                user_data['driver_license'] = driver.driver_license
                user_data['profile_photo'] = driver.profile_photo
            
            return Response({
                'success': True,
                'user': user_data,
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'message': f'Account created successfully as {user.role}'
            }, status=status.HTTP_201_CREATED)
        
        # Collect all error messages
        error_messages = []
        for field, errors in serializer.errors.items():
            for error in errors:
                if isinstance(error, dict):
                    error_messages.append(f"{field}: {', '.join(error.values())}")
                else:
                    error_messages.append(f"{field}: {error}")
        
        return Response({
            'success': False,
            'error': ' | '.join(error_messages) if error_messages else 'Registration failed'
        }, status=status.HTTP_400_BAD_REQUEST)


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        password = request.data.get('password')
        
        print(f"Login attempt for user: {username}")
        
        if not username or not password:
            return Response({
                'success': False,
                'error': 'Username and password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(username=username)
            print(f"User found: {user.username}, Role: {user.role}, Active: {user.is_active}")
        except User.DoesNotExist:
            print(f"User '{username}' does not exist")
            return Response({
                'success': False,
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        user = authenticate(username=username, password=password)
        
        if user is None:
            print(f"Authentication failed for {username}")
            return Response({
                'success': False,
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        if not user.is_active:
            return Response({
                'success': False,
                'error': 'Account is disabled'
            }, status=status.HTTP_403_FORBIDDEN)
        
        refresh = RefreshToken.for_user(user)
        
        user_data = UserSerializer(user).data
        
        # Add role-specific data
        if user.role == 'seller' and hasattr(user, 'seller_profile'):
            user_data['store_name'] = user.seller_profile.store_name
            user_data['seller_address'] = user.seller_profile.address
        elif user.role == 'driver' and hasattr(user, 'driver_profile'):
            driver = user.driver_profile
            user_data['vehicle_type'] = driver.vehicle_type
            user_data['vehicle_plate'] = driver.vehicle_plate
            user_data['vehicle_color'] = driver.vehicle_color
            user_data['vehicle_model'] = driver.vehicle_model
            user_data['vehicle_image'] = driver.vehicle_image.url if driver.vehicle_image else None
            user_data['national_id'] = driver.national_id
            user_data['national_id_image'] = driver.national_id_image
            user_data['driver_license'] = driver.driver_license
            user_data['profile_photo'] = driver.profile_photo
        
        print(f"Login successful for {username}, Role: {user.role}")
        
        return Response({
            'success': True,
            'user': user_data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)


class ProfileView(generics.RetrieveUpdateAPIView):
    """
    Get or update the current user's profile.
    Returns role-specific data for drivers and sellers.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = ProfileSerializer
    
    def get_object(self):
        return self.request.user
    
    def retrieve(self, request, *args, **kwargs):
        user = self.get_object()
        data = ProfileSerializer(user).data
        
        # ✅ Add driver-specific data
        if user.role == 'driver' and hasattr(user, 'driver_profile'):
            driver = user.driver_profile
            data['vehicle_type'] = driver.vehicle_type
            data['vehicle_plate'] = driver.vehicle_plate
            data['vehicle_color'] = driver.vehicle_color
            data['vehicle_model'] = driver.vehicle_model
            data['vehicle_image'] = driver.vehicle_image.url if driver.vehicle_image else None
            data['national_id'] = driver.national_id
            data['national_id_image'] = driver.national_id_image
            data['driver_license'] = driver.driver_license
            data['profile_photo'] = driver.profile_photo
            data['is_identity_verified'] = driver.is_identity_verified
            data['is_verified'] = driver.is_verified
        
        # ✅ Add seller-specific data
        if user.role == 'seller' and hasattr(user, 'seller_profile'):
            seller = user.seller_profile
            data['store_name'] = seller.store_name
            data['seller_address'] = seller.address
            data['national_id'] = seller.national_id
            data['national_id_image'] = seller.national_id_image
            data['profile_photo'] = seller.profile_photo
            data['business_license'] = seller.business_license
            data['is_identity_verified'] = seller.is_identity_verified
            data['is_approved'] = seller.is_approved
        
        return Response({
            'success': True,
            'data': data
        })


class UpdateStoreView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SellerProfileSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_object(self):
        return self.request.user.seller_profile
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        user = self.request.user
        user_data = UserSerializer(user).data
        
        # Add seller data to response
        if hasattr(user, 'seller_profile'):
            seller = user.seller_profile
            user_data['store_name'] = seller.store_name
            user_data['seller_address'] = seller.address
        
        return Response({
            'success': True,
            'data': serializer.data,
            'user': user_data,
            'message': 'Store updated successfully'
        })

class UpdateDriverProfileView(generics.UpdateAPIView):
    """
    Update driver profile information including vehicle details.
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_object(self):
        return self.request.user.driver_profile
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Update only the fields that are provided
        if 'vehicle_type' in request.data:
            instance.vehicle_type = request.data['vehicle_type']
        if 'vehicle_plate' in request.data:
            instance.vehicle_plate = request.data['vehicle_plate']
        if 'vehicle_color' in request.data:
            instance.vehicle_color = request.data['vehicle_color']
        if 'vehicle_model' in request.data:
            instance.vehicle_model = request.data['vehicle_model']
        
        instance.save()
        
        # Get updated user data
        user = self.request.user
        user_data = UserSerializer(user).data
        
        # Add driver data to response
        if hasattr(user, 'driver_profile'):
            driver = user.driver_profile
            user_data['vehicle_type'] = driver.vehicle_type
            user_data['vehicle_plate'] = driver.vehicle_plate
            user_data['vehicle_color'] = driver.vehicle_color
            user_data['vehicle_model'] = driver.vehicle_model
            user_data['vehicle_image'] = driver.vehicle_image.url if driver.vehicle_image else None
            user_data['national_id'] = driver.national_id
            user_data['national_id_image'] = driver.national_id_image
            user_data['driver_license'] = driver.driver_license
            user_data['profile_photo'] = driver.profile_photo
        
        return Response({
            'success': True,
            'data': {
                'vehicle_type': instance.vehicle_type,
                'vehicle_plate': instance.vehicle_plate,
                'vehicle_color': instance.vehicle_color,
                'vehicle_model': instance.vehicle_model,
            },
            'user': user_data,
            'message': 'Driver profile updated successfully'
        })

class UpdateDriverProfileView(generics.UpdateAPIView):
    """
    Update driver profile information including vehicle details.
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_object(self):
        return self.request.user.driver_profile
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Update only the fields that are provided
        if 'vehicle_type' in request.data:
            instance.vehicle_type = request.data['vehicle_type']
        if 'vehicle_plate' in request.data:
            instance.vehicle_plate = request.data['vehicle_plate']
        if 'vehicle_color' in request.data:
            instance.vehicle_color = request.data['vehicle_color']
        if 'vehicle_model' in request.data:
            instance.vehicle_model = request.data['vehicle_model']
        
        instance.save()
        
        # Get updated user data
        user = self.request.user
        user_data = UserSerializer(user).data
        
        # Add driver data to response
        if hasattr(user, 'driver_profile'):
            driver = user.driver_profile
            user_data['vehicle_type'] = driver.vehicle_type
            user_data['vehicle_plate'] = driver.vehicle_plate
            user_data['vehicle_color'] = driver.vehicle_color
            user_data['vehicle_model'] = driver.vehicle_model
            user_data['vehicle_image'] = driver.vehicle_image.url if driver.vehicle_image else None
            user_data['national_id'] = driver.national_id
            user_data['national_id_image'] = driver.national_id_image
            user_data['driver_license'] = driver.driver_license
            user_data['profile_photo'] = driver.profile_photo
        
        return Response({
            'success': True,
            'data': {
                'vehicle_type': instance.vehicle_type,
                'vehicle_plate': instance.vehicle_plate,
                'vehicle_color': instance.vehicle_color,
                'vehicle_model': instance.vehicle_model,
            },
            'user': user_data,
            'message': 'Driver profile updated successfully'
        })
