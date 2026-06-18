from django.urls import path
from .views import (
    NotificationListView,
    NotificationMarkReadView,
    NotificationMarkAllReadView,
    NotificationUnreadCountView,
    NotificationCreateTestView,
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification_list'),
    path('unread-count/', NotificationUnreadCountView.as_view(), name='notification_unread_count'),
    path('<int:pk>/mark-read/', NotificationMarkReadView.as_view(), name='notification_mark_read'),
    path('mark-all-read/', NotificationMarkAllReadView.as_view(), name='notification_mark_all_read'),
    path('test/', NotificationCreateTestView.as_view(), name='notification_test'),
]
