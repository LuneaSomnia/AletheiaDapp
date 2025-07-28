// src/hooks/useNotifications.ts
import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { getNotifications, markNotificationAsRead, markAllNotificationsAsRead } from '../services/notifications';
import { setNotifications, markAsRead, markAllAsRead } from '../services/store';
import type { RootState } from '../services/store';
import type { NotificationData } from '../services/canisters';

export const useNotifications = () => {
  const dispatch = useDispatch();
  const notifications = useSelector((state: RootState) => state.notifications);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load notifications from canister
  const loadNotifications = async (unreadOnly: boolean = false) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const notifs = await getNotifications(unreadOnly);
      dispatch(setNotifications(notifs));
    } catch (err) {
      console.error('Failed to load notifications:', err);
      setError('Failed to load notifications');
    } finally {
      setIsLoading(false);
    }
  };

  // Mark notification as read
  const markRead = async (notificationId: number) => {
    try {
      await markNotificationAsRead(notificationId);
      dispatch(markAsRead(notificationId));
    } catch (err) {
      console.error('Failed to mark notification as read:', err);
      setError('Failed to mark notification as read');
    }
  };

  // Mark all notifications as read
  const markAllRead = async () => {
    try {
      await markAllNotificationsAsRead();
      dispatch(markAllAsRead());
    } catch (err) {
      console.error('Failed to mark all notifications as read:', err);
      setError('Failed to mark all notifications as read');
    }
  };

  // Get unread count
  const unreadCount = notifications.filter(n => !n.read).length;

  // Auto-refresh notifications every 30 seconds
  useEffect(() => {
    loadNotifications();
    
    const interval = setInterval(() => {
      loadNotifications();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  return {
    notifications,
    unreadCount,
    isLoading,
    error,
    loadNotifications,
    markRead,
    markAllRead
  };
};