from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, ProfileSerializer, SellerProfileSerializer
from .models import User, SellerProfile

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'success': True,
                'user': UserSerializer(user).data,
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'message': f'Account created successfully as {user.role}'
            }, status=status.HTTP_201_CREATED)
        
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
        if user.role == 'seller' and hasattr(user, 'seller_profile'):
            user_data['store_name'] = user.seller_profile.store_name
            user_data['seller_address'] = user.seller_profile.address
        
        print(f"Login successful for {username}, Role: {user.role}")
        
        return Response({
            'success': True,
            'user': user_data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)


class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ProfileSerializer
    
    def get_object(self):
        return self.request.user
    
    def retrieve(self, request, *args, **kwargs):
        user = self.get_object()
        data = ProfileSerializer(user).data
        
        if user.role == 'seller' and hasattr(user, 'seller_profile'):
            data['store_name'] = user.seller_profile.store_name
            data['seller_address'] = user.seller_profile.address
        
        return Response({
            'success': True,
            'data': data
        })


class UpdateStoreView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SellerProfileSerializer
    
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
        if hasattr(user, 'seller_profile'):
            user_data['store_name'] = user.seller_profile.store_name
            user_data['seller_address'] = user.seller_profile.address
        
        return Response({
            'success': True,
            'data': serializer.data,
            'user': user_data,
            'message': 'Store updated successfully'
        })
