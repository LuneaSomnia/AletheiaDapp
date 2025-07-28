// src/services/notifications.ts
import { 
  getNotificationActor,
  getCurrentPrincipal 
} from './canisters';
import type { NotificationData } from './canisters';

export const getNotifications = async (unreadOnly: boolean = false): Promise<NotificationData[]> => {
  try {
    const actor = await getNotificationActor();
    const notifications = await actor.getNotifications(
      undefined, // since
      50, // limit
      unreadOnly
    );
    
    return notifications.map(notif => ({
      ...notif,
      id: Number(notif.id),
      timestamp: Number(notif.timestamp),
      userId: notif.userId
    }));
  } catch (error) {
    console.error('Failed to fetch notifications:', error);
    // Return mock data as fallback
    return [
      {
        id: 1,
        userId: await getCurrentPrincipal() || Principal.anonymous(),
        title: "New Claim Assignment",
        message: "You have been assigned a new claim to verify",
        timestamp: Date.now() - 60000,
        read: false,
        notificationType: "new_assignment"
      },
      {
        id: 2,
        userId: await getCurrentPrincipal() || Principal.anonymous(),
        title: "Payment Received",
        message: "Your monthly payment of 15.5 ICP has been processed",
        timestamp: Date.now() - 3600000,
        read: false,
        notificationType: "payment_received"
      }
    ];
  }
};

export const markNotificationAsRead = async (notificationId: number): Promise<void> => {
  try {
    const actor = await getNotificationActor();
    await actor.markAsRead(notificationId);
  } catch (error) {
    console.error('Failed to mark notification as read:', error);
  }
};

export const markAllNotificationsAsRead = async (): Promise<void> => {
  try {
    const actor = await getNotificationActor();
    await actor.markAllAsRead();
  } catch (error) {
    console.error('Failed to mark all notifications as read:', error);
  }
};

export const updateNotificationSettings = async (settings: {
  inApp?: boolean;
  push?: boolean;
  email?: boolean;
  disabledTypes?: string[];
}): Promise<void> => {
  try {
    const actor = await getNotificationActor();
    await actor.updateSettings(
      settings.inApp,
      settings.push,
      settings.email,
      settings.disabledTypes
    );
  } catch (error) {
    console.error('Failed to update notification settings:', error);
  }
};

export const sendNotification = async (
  title: string,
  message: string,
  type: string = 'info'
): Promise<void> => {
  try {
    const actor = await getNotificationActor();
    const currentPrincipal = await getCurrentPrincipal();
    
    if (currentPrincipal) {
      await actor.sendNotification(currentPrincipal, title, message, type);
    }
  } catch (error) {
    console.error('Failed to send notification:', error);
  }
};