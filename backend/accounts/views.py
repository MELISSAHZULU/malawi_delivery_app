# accounts/views.py

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import authenticate
from .models import User, BuyerProfile, SellerProfile, DriverProfile
from .serializers import UserSerializer, RegisterSerializer, ProfileSerializer

class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Create role-specific profile
        role = request.data.get('role', 'buyer')
        if role == 'buyer':
            BuyerProfile.objects.create(user=user)
        elif role == 'seller':
            SellerProfile.objects.create(
                user=user,
                store_name=request.data.get('store_name', ''),
                address=request.data.get('address', ''),
                latitude=request.data.get('latitude', 0),
                longitude=request.data.get('longitude', 0)
            )
        elif role == 'driver':
            DriverProfile.objects.create(
                user=user,
                vehicle_type=request.data.get('vehicle_type', 'motorcycle'),
                vehicle_plate=request.data.get('vehicle_plate', '')
            )
        
        return Response({
            'user': UserSerializer(user).data,
            'message': f'Account created successfully as {role}'
        }, status=status.HTTP_201_CREATED)

class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        user = authenticate(
            username=request.data.get('username'),
            password=request.data.get('password')
        )
        if user:
            response.data['user'] = UserSerializer(user).data
        return response

class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ProfileSerializer
    
    def get_object(self):
        return self.request.user