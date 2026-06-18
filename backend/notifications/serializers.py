from rest_framework import serializers
from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = ['id', 'title', 'message', 'type', 'is_read', 'data', 'created_at', 'time_ago']
        read_only_fields = ['id', 'created_at']
    
    def get_time_ago(self, obj):
        from django.utils import timezone
        from datetime import timedelta
        
        diff = timezone.now() - obj.created_at
        if diff < timedelta(minutes=1):
            return 'Just now'
        elif diff < timedelta(hours=1):
            return f'{diff.seconds // 60} min ago'
        elif diff < timedelta(days=1):
            return f'{diff.seconds // 3600} hours ago'
        elif diff < timedelta(days=7):
            return f'{diff.days} days ago'
        else:
            return obj.created_at.strftime('%b %d, %Y')
    
    def get_time_ago(self, obj):
        from django.utils import timezone
        from datetime import timedelta
        
        diff = timezone.now() - obj.created_at
        if diff < timedelta(minutes=1):
            return 'Just now'
        elif diff < timedelta(hours=1):
            return f'{diff.seconds // 60}m ago'
        elif diff < timedelta(days=1):
            return f'{diff.seconds // 3600}h ago'
        elif diff < timedelta(days=7):
            return f'{diff.days}d ago'
        else:
            return obj.created_at.strftime('%b %d')
