from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from .models import Notification
from .serializers import NotificationSerializer

class NotificationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')

class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        notification_id = kwargs.get('pk')
        try:
            notification = Notification.objects.get(id=notification_id, user=request.user)
            notification.mark_as_read()
            return Response({'success': True, 'message': 'Notification marked as read'})
        except Notification.DoesNotExist:
            return Response(
                {'error': 'Notification not found'},
                status=status.HTTP_404_NOT_FOUND
            )

class NotificationMarkAllReadView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'success': True, 'message': 'All notifications marked as read'})

class NotificationUnreadCountView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})

class NotificationCreateTestView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        """Create a test notification - for development only"""
        title = request.data.get('title', 'Test Notification')
        message = request.data.get('message', 'This is a test notification')
        
        notification = Notification.objects.create(
            user=request.user,
            title=title,
            message=message,
            type='system'
        )
        
        return Response(NotificationSerializer(notification).data, status=status.HTTP_201_CREATED)
